pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.config
import qs.components.widgets.bar
import qs.components.widgets.popouts
import qs.components.reusable

/**
 * Popout wrapper for submenus.
 * Positions to the right of parent menu items with slide animation;
 * opens to the left instead if there's no space to the right.
 * Open/close/queue state and dismiss timing come from PopoutWrapperBase —
 * this file only adds submenu-specific positioning and animation.
 */
Item {
  id: outer

  required property ShellScreen screen
  required property bool openToLeft

  property alias popupWindow: submenuPopup
  property int minWidth: 100
  property int maxWidth: 600

  // Forward everything the base needs, plus a bit of connector geometry.
  PopoutWrapperBase {
    id: root
    anchors.fill: parent

    property int connectorGap: 4

    currentItem: loader.item ?? null

    PopupWindow {
      id: submenuPopup

      visible: root.occupied && loader.status === Loader.Ready
      color: "transparent"

      readonly property int contentWidth: {
        const itemWidth = root.currentItem?.implicitWidth ?? outer.minWidth;
        return Math.max(outer.minWidth, Math.min(outer.maxWidth, itemWidth));
      }
      readonly property int contentHeight: root.currentItem?.implicitHeight ?? 100

      implicitWidth: contentWidth + root.connectorGap
      implicitHeight: contentHeight

      property int offset: Widget.padding * 4 - Appearance.borderWidth
      property int baseX: root.currentData?.anchorX ?? 0
      property int openLeftX: baseX - submenuPopup.contentWidth - root.connectorGap - offset + Widget.padding * 3
      property int openRightX: baseX + (root.currentData?.anchorWidth ?? 0) + offset
      property int finalX: outer.openToLeft ? openLeftX : openRightX
      property int finalY: 0

      anchor {
        window: root.currentAnchor
        rect {
          x: finalX
          y: (root.currentData?.anchorY ?? 0)
          width: 1
          height: 1
        }
      }

      SlideAnimation {
        id: slideContainer
        anchors.fill: parent

        active: root.occupied && !root.isClosing
        slideFromRight: outer.openToLeft
        slideFromLeft: !outer.openToLeft
        slideFromTop: false
        slideFromBottom: false
        animationDuration: Appearance.animNormal
        enableFade: false

        Rectangle {
          id: contentContainer

          color: Theme.background
          radius: Appearance.borderRadius
          border.color: Theme.foreground
          border.width: Appearance.borderWidth

          x: outer.openToLeft ? Appearance.borderWidth : (root.connectorGap - Appearance.borderRadius)
          y: 0
          width: parent.width - root.connectorGap + (outer.openToLeft ? Appearance.borderWidth + Appearance.borderRadius : 0)
          height: parent.height

          Loader {
            id: loader
            anchors.fill: parent
            anchors.margins: Widget.spacing
            active: root.occupied
            asynchronous: false

            sourceComponent: Component {
              TraySubmenuPopout {
                wrapper: root
                menuItem: root.currentData?.menuItem
              }
            }

            onLoaded: root.updateDismissTimer()
          }
        }

        Rectangle {
          id: connector

          color: Theme.bg0
          // color: "green"
          x: outer.openToLeft ? (parent.width - root.connectorGap) : root.connectorGap
          y: 0
          width: root.connectorGap
          height: parent.height
        }

        Rectangle {
          id: topCorner
          anchors.top: connector.top
          anchors.left: connector.left
          anchors.right: connector.right
          width: connector.width
          height: Appearance.borderRadius
          // color: "red"
          color: "transparent"
          CornerPiece {
            isLeft: true
            isTop: false
          }
        }

        Rectangle {
          id: bottomCorner
          anchors.bottom: connector.bottom
          anchors.left: connector.left
          anchors.right: connector.right
          width: connector.width
          height: Appearance.borderRadius
          color: "transparent"
          CornerPiece {
            isLeft: true
            isTop: false
          }
        }
      }
    }
  }

  // Thin forwarding so external callers (SystemTrayPopout, TraySubmenuPopout)
  // keep using `submenuWrapper.safeOpenPopout(...)` / `closePopout()` /
  // `requestDismiss()` / `occupied` / `popupWindow` exactly as before,
  // without needing to reach into the inner PopoutWrapperBase directly.
  property alias occupied: root.occupied
  property alias currentItem: root.currentItem
  function safeOpenPopout(anchor, data) { root.safeOpenPopout(anchor, data); }
  function closePopout() { root.closePopout(); }
  function requestDismiss() { root.requestDismiss(); }
}
