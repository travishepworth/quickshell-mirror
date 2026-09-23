pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.services
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

  property real hideTimeout: 1000

  Variants {
    model: Quickshell.screens

    // One OSD per screen; volume changes only show it on the focused one.
    // Hiding is the popout's own hover-aware dismiss timer.
    delegate: EdgePopout {
      id: root
      required property ShellScreen modelData

      screen: modelData
      edge: Bar.Bottom
      position: 0.5
      triggerEnabled: false
      dismissDelay: osdRoot.hideTimeout
      // The volume bars inside also report per-app changes, so they must
      // exist while the OSD is closed
      keepLoaded: true

      // Open (or keep open) on the focused screen; restarts the countdown
      function poke(force) {
        if (root.isOpen)
          root.updateDismissTimer();
        else if (force && root.isFocusedScreen)
          root.show();
      }

      Connections {
        target: Audio

        function onVolumeChanged() {
          root.poke(true);
        }

        function onMutedChanged() {
          root.poke(true);
        }
      }

      content: Component {
        Item {
          implicitWidth: 350 - Widget.spacing * 2
          implicitHeight: 220 - Widget.spacing * 2

          RowLayout {
            anchors.fill: parent
            anchors.margins: 15 - Widget.spacing
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

                onVisibilityChanged: root.poke(modelData.showOsd)
              }
            }
          }
        }
      }
    }
  }
}
