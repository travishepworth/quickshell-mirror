pragma ComponentBehavior: Bound

import QtQuick

import qs.services
import qs.config
import qs.components.reusable

BarIconWidget {
  id: root

  property bool isConnected: false
  property string tailnetName: ""

  icon: isConnected ? "󰳌" : "󰌙"
  text: isConnected ? (properties.label || tailnetName) : ""
  showText: properties.showLabel

  backgroundColor: Theme.resolveColor(isConnected ? properties.connectedColor : properties.disconnectedColor)

  iconScale: 1.1
  textScale: 0.9

  PollingProcess {
    id: statusChecker
    interval: root.properties.interval
    command: ["sh", "-c", "tailscale status &>/dev/null"]
    treatExitCodeAsStatus: true

    onStatusChanged: (exitCode, stdout, stderr) => {
      root.isConnected = (exitCode === 0);

      // If connected, get the tailnet name
      if (root.isConnected) {
        tailnetChecker.refresh();
      } else {
        root.tailnetName = "";
      }
    }
  }

  PollingProcess {
    id: tailnetChecker
    interval: 5000
    command: ["sh", "-c", "tailscale status --json 2>/dev/null | jq -r '.CurrentTailnet.Name // empty' 2>/dev/null"]
    autoStart: false

    onDataReceived: data => {
      let name = data.trim().replace(/^["']|["']$/g, '');
      root.tailnetName = name || "";
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      Notifs.sendNotification("axiom", "Tailscale", root.isConnected ? I18n.tr("Connected to: {0}", root.tailnetName) : I18n.tr("Disconnected"));
    }
  }
}
