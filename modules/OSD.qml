pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.popouts
import qs.components.widgets.common

Item {
  id: osdRoot
  anchors.fill: parent

  // Left-to-right order of apps to track individually. "master" (below)
  // automatically excludes everything in this list.
  readonly property var trackedApps: ["Zen", "vesktop", "spotify"]

  property bool shouldShowOsd: false
  property real hideTimeout: 1000

  Connections {
    target: Audio

    function onVolumeChanged() {
      osdRoot.shouldShowOsd = true;
      hideTimer.restart();
    }

    function onMutedChanged() {
      osdRoot.shouldShowOsd = true;
      hideTimer.restart();
    }
  }

  function onVisibilityChanged() {
    osdRoot.shouldShowOsd = true;
    hideTimer.restart();
  }

  Timer {
    id: hideTimer
    interval: osdRoot.hideTimeout
    repeat: false
    onTriggered: osdRoot.shouldShowOsd = false
  }

  EdgePopup {
    id: root
    panelId: "volumeOSD"

    edge: EdgePopup.Edge.Bottom
    position: 0.5
    active: false
    // why are both of these necessary to prevent mouse?
    enableTrigger: false
    triggerOnHover: false
    property bool shouldShowOsd: osdRoot.shouldShowOsd
    triggerWidth: 5
    closeOnMouseExit: false
    closeOnClickOutside: true
    focusable: false
    aboveWindows: true
    edgeMargin: Config.containerOffset + Appearance.borderWidth * 2 + 3

    animationDuration: 200
    easingType: Easing.OutQuad

    onActiveChanged: {
      if (active) {
        osdRoot.shouldShowOsd = true;
        hideTimer.restart();
      }
    }

    onShouldShowOsdChanged: {
      if (shouldShowOsd) {
        root.active = true;
        hideTimer.restart();
      } else {
        root.active = false;
        hideTimer.stop();
      }
    }

    StyledContainer {
      backgroundColor: Theme.backgroundAlt
      borderColor: Theme.accent
      borderWidth: Appearance.borderWidth
      borderRadius: Appearance.borderRadius

      property bool hovered: false

      implicitWidth: 350
      implicitHeight: 220
      MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
          parent.hovered = true;
          osdRoot.shouldShowOsd = true;
          hideTimer.stop();
        }
        onExited: {
          parent.hovered = false;
          hideTimer.restart();
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 20

        PipewireVolumeBar {
          targetApplication: osdRoot.trackedApps[0]
          orientation: Qt.Vertical
          iconSource: ""
          onVisibilityChanged: {
            osdRoot.shouldShowOsd = true;
            hideTimer.restart();
          }
        }

        PipewireVolumeBar {
          targetApplication: osdRoot.trackedApps[1]
          orientation: Qt.Vertical
          iconSource: ""
          onVisibilityChanged: {
            osdRoot.shouldShowOsd = true;
            hideTimer.restart();
          }
        }

        PipewireVolumeBar {
          targetApplication: "master"
          excludedApps: osdRoot.trackedApps
          orientation: Qt.Vertical
          iconSource: ""
          onVisibilityChanged: {
            osdRoot.shouldShowOsd = true;
            hideTimer.restart();
          }
        }

        PipewireVolumeBar {
          targetApplication: osdRoot.trackedApps[2]
          orientation: Qt.Vertical
          iconSource: ""
          onVisibilityChanged: {
            osdRoot.shouldShowOsd = true;
            hideTimer.restart();
          }
        }

        PipewireVolumeBar {
          orientation: Qt.Vertical
          volume: Audio.volume
          isMuted: Audio.muted
          iconSource: {
            if (Audio.muted || Audio.volume === 0)
              return "";
            if (Audio.volume > 0.4)
              return "";
            return "";
          }
        }
      }
    }
  }
}
