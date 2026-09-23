pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io

import qs.config
import qs.components.reusable
import qs.components.widgets.bar.popouts

// Pending package updates: repo packages via `checkupdates` (pacman-contrib,
// which uses a temporary sync db, so it never touches the real one), plus
// AUR packages via paru/yay when enabled. Left click opens a terminal to
// upgrade, right click checks again now; hovering lists the packages.
IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  // [{ name, from, to }]
  property var repoPackages: []
  property var aurPackages: []
  readonly property int count: repoPackages.length + aurPackages.length

  readonly property bool hidden: properties.hideWhenEmpty && count === 0
  readonly property int interval: properties.intervalMinutes * 60000
  readonly property string upgradeCommand: properties.upgradeCommand || (properties.includeAur ? `${properties.aurHelper} -Syu` : "sudo pacman -Syu")

  isVertical: barConfig.vertical

  icon: "\u{F03D4}"
  text: String(count)
  showIcon: !hidden
  showText: !hidden
  padding: hidden ? 0 : Widget.padding

  backgroundColor: Theme.resolveColor(count >= properties.manyThreshold ? properties.manyColor : properties.backgroundColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)
  opacity: mouseArea.pressed ? 0.8 : 1

  function parse(text) {
    return text.split("\n").map(line => line.trim().split(/\s+/)).filter(f => f.length >= 4 && f[2] === "->").map(f => ({
          "name": f[0],
          "from": f[1],
          "to": f[3]
        }));
  }

  function refresh() {
    repoChecker.refresh();
    aurChecker.refresh();
  }

  PollingProcess {
    id: repoChecker
    interval: root.interval
    command: ["checkupdates", "--nocolor"]
    treatExitCodeAsStatus: true

    // 0: updates listed, 2: none, anything else: failed (offline, db locked)
    onStatusChanged: (exitCode, stdout, stderr) => {
      if (exitCode === 0 || exitCode === 2)
        root.repoPackages = root.parse(stdout);
      else
        console.warn(`[Updates] checkupdates failed (${exitCode}): ${stderr}`);
    }
  }

  PollingProcess {
    id: aurChecker
    interval: root.interval
    command: root.properties.includeAur ? ["sh", "-c", `command -v ${root.properties.aurHelper} >/dev/null || exit 127; ${root.properties.aurHelper} -Qua`] : []
    treatExitCodeAsStatus: true

    onCommandChanged: {
      if (command.length > 0)
        refresh();
      else
        root.aurPackages = [];
    }

    // -Qua exits 1 when nothing is outdated
    onStatusChanged: (exitCode, stdout, stderr) => {
      if (exitCode === 127) {
        console.warn(`[Updates] AUR helper '${root.properties.aurHelper}' is not installed`);
        root.aurPackages = [];
      } else {
        root.aurPackages = root.parse(stdout);
      }
    }
  }

  // Runs until the terminal closes, then re-checks
  Process {
    id: upgrader
    command: [root.properties.terminal, "-e", "bash", "-c", `${root.upgradeCommand}; echo; read -n 1 -s -r -p "Press any key to close"`]
    onExited: root.refresh()
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: !root.hidden
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton)
        root.refresh();
      else if (!upgrader.running)
        upgrader.running = true;
    }
  }

  PopoutAnchor {
    popouts: root.popouts
    panel: root.panel
    popoutName: "updates"
    active: root.properties.showPopout && !root.hidden
    extraData: ({
        "repoPackages": root.repoPackages,
        "aurPackages": root.aurPackages
      })
  }
}
