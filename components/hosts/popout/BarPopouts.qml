pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.services
import qs.config
// Imported (though loaded by URL) so qs scans the content types
import qs.components.content

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
  // Content box in popupWindow coordinates (see AttachedSurface.boxRect)
  readonly property rect boxRect: surface.boxRect

  // The content-type name travels inside currentData.name (see
  // PopoutAnchor.qml) rather than as a separate argument, so this file
  // never needs to override openPopout/safeOpenPopout from the base.
  readonly property string currentName: currentData?.name ?? ""
  // Which side the tray's submenus open to
  readonly property bool openToLeft: root.barConfig.right || mainPopup.isOnRightHalfOfScreen

  // content/<name>.qml, loaded by URL like bar widgets and overlay modules:
  // a new popout is just a file there plus a PopoutAnchor naming it
  function _loadContent() {
    if (loader.active && root.currentName !== "")
      loader.setSource(Qt.resolvedUrl("../../content/" + root.currentName + ".qml"), {
        "wrapper": root
      });
    else if (!loader.active)
      // Cleared, so reactivating doesn't first rebuild the previous popout
      loader.source = "";
  }
  onCurrentNameChanged: _loadContent()

  currentItem: loader.item ?? null

  // Gap between bar and main content (connector thickness)
  property int connectorGap: Appearance.borderRadius * 2

  // The bar's BarContainer. Its layoutUpdated signal re-anchors an open
  // popout, so it stays attached to a widget that moves or resizes.
  property var layoutSource: null

  // Where the anchor widget currently is, in bar-window coordinates. Read
  // live from currentData.anchorItem; the anchorX/anchorY snapshot in the
  // payload is only the fallback for callers that don't pass an item.
  property rect anchorRect: Qt.rect(0, 0, 0, 0)

  function updateAnchorRect() {
    const data = root.currentData;
    if (!data)
      return;
    const item = data.anchorItem;
    if (item) {
      try {
        const pos = item.mapToItem(null, 0, 0);
        root.anchorRect = Qt.rect(pos.x, pos.y, item.width, item.height);
        return;
      } catch (e) {
        // Anchor was destroyed (e.g. the bar rebuilt on a config reload)
      }
    }
    root.anchorRect = Qt.rect(data.anchorX ?? 0, data.anchorY ?? 0, data.anchorWidth ?? 0, data.anchorHeight ?? 0);
  }

  onCurrentDataChanged: updateAnchorRect()

  Connections {
    target: root.layoutSource
    // Positions settle through bindings after the signal, so read them once
    // they have
    function onLayoutUpdated() {
      if (root.occupied)
        Qt.callLater(root.updateAnchorRect);
    }
  }

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

  PopupWindow {
    id: mainPopup
    visible: root.occupied && loader.status === Loader.Ready
    color: "transparent"

    // Content dimensions
    readonly property int contentWidth: root.currentItem?.implicitWidth ?? 200
    readonly property int contentHeight: root.currentItem?.implicitHeight ?? 100
    readonly property bool isOnRightHalfOfScreen: root.anchorRect.x > (root.screen.width / 2)

    // Along-bar clamp range, in bar-window coordinates. The perpendicular
    // screen borders may sit inside the bar window (bar mapped first) or
    // outside it, so derive where their inner edge falls from how much of
    // the screen the window spans. The surface (fillets included) keeps a
    // screen margin clear of that edge, so the fillets never run into the
    // border's inner corner — the same gap EdgePopout leaves.
    readonly property real panelLength: {
      const mapped = root.barConfig.vertical ? root.panel.height : root.panel.width;
      return mapped > 0 ? mapped : (root.barConfig.vertical ? root.screen.height : root.screen.width);
    }
    readonly property real borderInset: Appearance.screenMargin - ((root.barConfig.vertical ? root.screen.height : root.screen.width) - panelLength) / 2
    readonly property real minAlong: borderInset + Appearance.screenMargin
    readonly property real maxAlong: panelLength - borderInset - Appearance.screenMargin

    // Where the popup starts along the bar so its content box sits at
    // `align` against the anchor: 0 lines the box's start edge up with the
    // anchor's, 1 its end edge, 0.5 centers it. The fillets hang outside
    // the box, hence the inset.
    function alignedStart(anchorStart, anchorLength, popupLength, boxLength) {
      const align = root.currentData?.align ?? 0.5;
      const inset = (popupLength - boxLength) / 2;
      return anchorStart + (anchorLength - boxLength) * align - inset;
    }

    // Size comes from the shared attached shape: the content box wraps
    // the content plus the surface's inset on every side.
    implicitWidth: surface.implicitWidth
    implicitHeight: surface.implicitHeight

    anchor {
      window: root.currentAnchor

      rect {
        x: {
          if (!root.currentData)
            return 0;

          if (root.barConfig.left) {
            return root.barConfig.extent;
          } else if (root.barConfig.right) {
            // Mirror of the left case: end at the bar's inner edge, not
            // relative to the anchor (tray icons are narrower than modules)
            return -mainPopup.implicitWidth;
          } else {
            const targetX = mainPopup.alignedStart(root.anchorRect.x, root.anchorRect.width, mainPopup.implicitWidth, surface.boxRect.width);

            return Math.max(mainPopup.minAlong, Math.min(targetX, mainPopup.maxAlong - mainPopup.implicitWidth));
          }
        }

        y: {
          if (!root.currentData)
            return 0;

          if (root.barConfig.top) {
            return root.barConfig.extent;
          } else if (root.barConfig.bottom) {
            return -mainPopup.implicitHeight;
          } else {
            const targetY = mainPopup.alignedStart(root.anchorRect.y, root.anchorRect.height, mainPopup.implicitHeight, surface.boxRect.height);

            return Math.max(mainPopup.minAlong, Math.min(targetY, mainPopup.maxAlong - mainPopup.implicitHeight));
          }
        }

        width: 1
        height: 1
      }
    }

    AttachedSurface {
      id: surface
      anchors.fill: parent

      edge: root.barConfig.location
      active: root.occupied && !root.isClosing
      connectorGap: root.connectorGap
      boxWidth: mainPopup.contentWidth + contentInset * 2
      boxHeight: mainPopup.contentHeight + contentInset * 2

      Loader {
        id: loader
        anchors.fill: parent
        anchors.margins: surface.contentInset

        active: root.occupied
        asynchronous: false

        onActiveChanged: root._loadContent()

        onLoaded: {
          if (item) {
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
  }
}
