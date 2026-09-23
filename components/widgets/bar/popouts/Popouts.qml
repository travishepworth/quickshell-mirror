pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.services
import qs.config
import qs.components.widgets.bar
import qs.components.widgets.bar.popouts
import qs.components.widgets.popouts

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

    // Size comes from the shared attached shape. The content box is a
    // little shorter than the content along the bar (kept for parity
    // with how bar popout contents were sized before the extraction).
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

    AttachedSurface {
      id: surface
      anchors.fill: parent

      edge: root.barConfig.location
      active: root.occupied && !root.isClosing
      connectorGap: root.connectorGap
      boxWidth: root.barConfig.vertical ? mainPopup.contentWidth : mainPopup.contentWidth - root.connectorGap + Appearance.borderWidth * 4
      boxHeight: root.barConfig.vertical ? mainPopup.contentHeight - root.connectorGap + Appearance.borderWidth * 4 : mainPopup.contentHeight

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
          case "calendar":
            return calendarComponent;
          case "notifications":
            return notificationsComponent;
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

  Component {
    id: calendarComponent
    CalendarPopout {
      wrapper: root
    }
  }

  Component {
    id: notificationsComponent
    NotificationsPopout {
      wrapper: root
    }
  }
}
