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

  // Left-to-right order of bar slots. Each entry is the argument set for
  // one bar:
  //   app:     app-name substring to match, or the sentinels below
  //   showOsd: whether a change on this slot should force the OSD open
  //            (it always restarts the auto-hide timer regardless)
  //   icon:    icon glyph shown on the bar (master's is volume-dependent,
  //            see iconSource binding below - its entry here is unused
  //            but kept for consistency/documentation)
  // Sentinels:
  //   "other"  - catches whatever isn't one of the other named apps
  //              (was previously called "master")
  //   "master" - the actual system/output volume
  //              (was previously the hardcoded trailing bar)
  readonly property var trackedApps: [
    { app: "Zen", showOsd: true, icon: " " },
    { app: "vesktop", showOsd: true, icon: " " },
    { app: "other", showOsd: true, icon: " " },
    { app: "spotify", showOsd: true, icon: " " },
    { app: "master", showOsd: true, icon: "" }
  ]

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

        Repeater {
          model: osdRoot.trackedApps

          delegate: PipewireVolumeBar {
            id: volBar
            required property var modelData
            required property int index

            readonly property bool isOtherSlot: modelData.app === "other"
            readonly property bool isMasterSlot: modelData.app === "master"

            orientation: Qt.Vertical
            targetApplication: isMasterSlot ? "" : (isOtherSlot ? "master" : modelData.app)
            excludedApps: isOtherSlot ? osdRoot.trackedApps.filter(a => a.app !== "other" && a.app !== "master").map(a => a.app) : []
            useSystemVolume: isMasterSlot
            iconSource: {
              if (isMasterSlot) {
                if (Audio.muted || Audio.volume === 0)
                  return "";
                if (Audio.volume > 0.4)
                  return " ";
                return " ";
              }
              return modelData.icon;
            }

            onVisibilityChanged: {
              if (modelData.showOsd) {
                osdRoot.shouldShowOsd = true;
              }
              hideTimer.restart();
            }
          }
        }
      }
    }
  }
}
