pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.services
import qs.config
import qs.components.widgets.bar
import qs.components.widgets.bar.popouts
import qs.components.reusable

/**
 * Popout wrapper for bar widgets
 * Handles positioning, animation, and content loading for popouts that emerge from the bar.
 * Open/close/queue state and dismiss timing live in PopoutWrapperBase — this
 * file only adds what's specific to bar popouts: which content type to
 * load, where to position it, and how to animate it in/out.
 */
PopoutWrapperBase {
  id: root

  required property ShellScreen screen
  required property var barConfig
  required property QtObject panel

  property alias popupWindow: mainPopup

  // The content-type name travels inside currentData.name (see
  // PopoutAnchor.qml) rather than as a separate argument, so this file
  // never needs to override openPopout/safeOpenPopout from the base.
  readonly property string currentName: currentData?.name ?? ""

  currentItem: loader.item ?? null

  // Gap between bar and main content (connector thickness)
  property int connectorGap: Appearance.borderRadius * 2

  // Clear the anchor widget's popoutOpen flag on dismiss, so hovering it
  // again is allowed to open a fresh popout. Safety net for however this
  // popout ends up destroyed lives alongside it.
  onAboutToDismiss: {
    if (currentData?.anchorItem) {
      currentData.anchorItem.popoutOpen = false;
    }
  }

  Component.onDestruction: {
    if (currentData?.anchorItem) {
      currentData.anchorItem.popoutOpen = false;
    }
  }

  // Optional helper for updating an already-open popout's content/data
  // in place, without a close/reopen animation. Kept as (name, data) for
  // API compatibility with any existing callers — internally folds name
  // into the data blob the same way PopoutAnchor does.
  function changeContent(name, data) {
    if (isClosing)
      return;
    const merged = data ? Object.assign({}, data) : {};
    merged.name = name;
    currentData = merged;

    if (loader.item) {
      for (let key in merged) {
        if (loader.item.hasOwnProperty(key)) {
          loader.item[key] = merged[key];
        }
      }
    }
    updateDismissTimer();
  }

  PopupWindow {
    id: mainPopup
    visible: root.occupied && loader.status === Loader.Ready
    color: "transparent"

    // Content dimensions
    readonly property int contentWidth: root.currentItem?.implicitWidth ?? 200
    readonly property int contentHeight: root.currentItem?.implicitHeight ?? 100
    readonly property int isOnRightHalfOfScreen: (root.currentData?.anchorX ?? 0) > (root.screen.width / 2) ? true : false

    // Total size including connector gap
    implicitWidth: {
      if (root.barConfig.vertical) {
        return contentWidth + root.connectorGap;
      }
      return contentWidth;
    }

    implicitHeight: {
      if (root.barConfig.vertical) {
        return contentHeight + Appearance.borderRadius * 2 + Appearance.borderWidth * 2;
      }
      return contentHeight + root.connectorGap;
    }

    anchor {
      window: root.currentAnchor

      rect {
        x: {
          if (!root.currentData)
            return 0;

          if (root.barConfig.left) {
            return root.barConfig.extent;
          } else if (root.barConfig.right) {
            return (root.currentData.anchorX ?? 0) - mainPopup.implicitWidth - Widget.padding + Appearance.borderWidth;
          } else {
            let anchorCenter = (root.currentData.anchorX ?? 0) + (root.currentData.anchorWidth ?? 0) / 2;
            let popoutCenter = mainPopup.implicitWidth / 2;
            let targetX = anchorCenter - popoutCenter;

            return Math.max(Appearance.screenMargin, Math.min(targetX, root.screen.width - mainPopup.implicitWidth - Appearance.screenMargin));
          }
        }

        y: {
          if (!root.currentData)
            return 0;

          if (root.barConfig.top) {
            return root.barConfig.extent;
          } else if (root.barConfig.bottom) {
            return (root.currentData.anchorY ?? 0) - mainPopup.implicitHeight - Widget.padding + Appearance.borderWidth;
          } else {
            let anchorCenter = (root.currentData.anchorY ?? 0) + (root.currentData.anchorHeight ?? 0) / 2;
            let popoutCenter = mainPopup.implicitHeight / 2;
            let targetY = anchorCenter - popoutCenter;

            return Math.max(Appearance.screenMargin, Math.min(targetY, root.screen.height - mainPopup.implicitHeight - Appearance.screenMargin));
          }
        }

        width: 1
        height: 1
      }
    }

    SlideAnimation {
      id: slideContainer
      anchors.fill: parent

      active: root.occupied && !root.isClosing
      slideFromRight: root.barConfig.right
      slideFromLeft: root.barConfig.left
      slideFromTop: root.barConfig.top
      slideFromBottom: root.barConfig.bottom
      animationDuration: Appearance.animationDuration

      containerHeight: mainPopup.implicitHeight
      containerWidth: mainPopup.implicitWidth
      enableFade: false

      Rectangle {
        id: contentContainer
        color: Theme.background
        radius: Appearance.borderRadius
        border.color: Theme.foreground
        border.width: Appearance.borderWidth
        anchors.centerIn: parent

        width: root.barConfig.vertical ? parent.width - root.connectorGap : parent.width
        height: root.barConfig.vertical ? parent.height - Appearance.borderRadius * 4 + Appearance.borderWidth * 2 : parent.height - root.connectorGap

        Loader {
          id: loader
          anchors.fill: parent
          anchors.margins: Widget.spacing

          active: root.occupied
          asynchronous: false

          sourceComponent: {
            switch (root.currentName) {
            case "workspace-grid":
              return workspaceGridComponent;
            case "media-player":
              return mediaPlayerComponent;
            case "system-tray-menu":
              return systemTrayComponent;
            default:
              return null;
            }
          }

          onLoaded: {
            if (item) {
              item.wrapper = root;
              if (root.currentData) {
                for (let key in root.currentData) {
                  if (item.hasOwnProperty(key)) {
                    item[key] = root.currentData[key];
                  }
                }
              }
            }
            root.updateDismissTimer();
          }
        }
      }

      Rectangle {
        id: connector
        color: Theme.background

        x: root.barConfig.left ? 0 : root.barConfig.right ? parent.width - root.connectorGap : 0
        y: root.barConfig.top ? 0 : root.barConfig.bottom ? parent.height - root.connectorGap : 0 + Appearance.borderRadius * 2

        width: root.barConfig.vertical ? root.connectorGap : parent.width
        height: root.barConfig.vertical ? contentContainer.height - Appearance.borderWidth * 2 : root.connectorGap
      }

      Rectangle {
        id: cornerHolder
        color: "transparent"

        x: root.barConfig.left ? 0 : root.barConfig.right ? parent.width - root.connectorGap : 0
        y: root.barConfig.top ? 0 : root.barConfig.bottom ? parent.height - root.connectorGap : 0

        width: connector.width
        height: mainPopup.height
      }

      Rectangle {
        id: topCorner
        anchors.top: cornerHolder.top
        anchors.left: connector.left
        anchors.right: connector.right
        width: connector.width
        height: connector.width
        color: "transparent"
        clip: true
        CornerPiece {
          isLeft: true
          isTop: false
        }
      }

      Rectangle {
        id: bottomCorner
        anchors.bottom: cornerHolder.bottom
        anchors.left: connector.left
        anchors.right: connector.right
        width: connector.width
        height: connector.width
        color: "transparent"
        clip: true
        CornerPiece {
          isLeft: true
          isTop: true
        }
      }
    }
  }

  Component {
    id: workspaceGridComponent
    WorkspacePopout {
      wrapper: root
    }
  }

  Component {
    id: systemTrayComponent
    SystemTrayPopout {
      wrapper: root
      openToLeft: barConfig.right ? true : mainPopup.isOnRightHalfOfScreen === 1
    }
  }

  Component {
    id: mediaPlayerComponent
    MediaPopout {
      wrapper: root
    }
  }
}
