pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.services
import qs.components.hosts.popout
import qs.components.reusable

Item {
  id: osdRoot
  anchors.fill: parent

  // Bar slots, in order, from OSD.apps in the config. Each entry is the
  // argument set for one bar:
  //   app:     app-name substring to match, or the sentinels below
  //   showOsd: whether a change on this slot should force the OSD open
  //            (it always restarts the auto-hide timer regardless)
  //   icon:    icon glyph shown on the bar (master's is volume-dependent,
  //            see iconSource binding below - its entry is unused)
  // Sentinels:
  //   "other"  - catches whatever isn't one of the other named apps
  //   "master" - the actual system/output volume
  readonly property var trackedApps: OSDConfig.apps
  // Length of each bar along its axis; the OSD grows with the app count
  // in the other direction
  readonly property int barLength: 190
  readonly property int barSpacing: 20

  Variants {
    model: OSDConfig.enabled ? General.screens : []

    // One OSD per screen in General.screens; volume changes show it on the
    // target screen (the focused one when on every monitor).
    // Hiding is the popout's own hover-aware dismiss timer.
    delegate: EdgePopout {
      id: root
      required property ShellScreen modelData

      screen: modelData
      edge: OSDConfig.edge
      position: OSDConfig.position
      triggerEnabled: false
      dismissDelay: OSDConfig.timeout
      // The volume bars inside also report per-app changes, so they must
      // exist while the OSD is closed
      keepLoaded: true

      // Open (or keep open) on the focused screen; restarts the countdown
      function poke(force) {
        if (root.isOpen)
          root.updateDismissTimer();
        else if (force && ShellManager.isTarget(root.screen))
          root.show();
      }

      Connections {
        target: AudioManager

        function onVolumeChanged() {
          root.poke(true);
        }

        function onMutedChanged() {
          root.poke(true);
        }
      }

      content: Component {
        Item {
          id: box
          readonly property int margin: 15 - Widget.spacing

          implicitWidth: grid.implicitWidth + margin * 2
          implicitHeight: grid.implicitHeight + margin * 2

          GridLayout {
            id: grid
            anchors.fill: parent
            anchors.margins: box.margin
            // Vertical bars side by side, horizontal bars as rows
            flow: OSDConfig.vertical ? GridLayout.LeftToRight : GridLayout.TopToBottom
            columnSpacing: osdRoot.barSpacing
            rowSpacing: osdRoot.barSpacing

            Repeater {
              model: osdRoot.trackedApps

              delegate: PipewireVolumeBar {
                id: volBar
                required property var modelData
                required property int index

                readonly property bool isOtherSlot: modelData.app === "other"
                readonly property bool isMasterSlot: modelData.app === "master"

                orientation: OSDConfig.vertical ? Qt.Vertical : Qt.Horizontal
                Layout.preferredWidth: OSDConfig.vertical ? volBar.implicitWidth : osdRoot.barLength
                Layout.preferredHeight: OSDConfig.vertical ? osdRoot.barLength : volBar.implicitHeight
                targetApplication: isMasterSlot ? "" : (isOtherSlot ? "master" : modelData.app)
                excludedApps: isOtherSlot ? osdRoot.trackedApps.filter(a => a.app !== "other" && a.app !== "master").map(a => a.app) : []
                useSystemVolume: isMasterSlot
                iconSource: {
                  if (isMasterSlot) {
                    if (AudioManager.muted || AudioManager.volume === 0)
                      return "";
                    if (AudioManager.volume > 0.4)
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
