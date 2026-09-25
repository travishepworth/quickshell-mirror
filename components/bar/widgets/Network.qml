pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.config
import qs.services
import qs.components.hosts.popout

// The primary connection's kind and device. Hovering opens the Wi-Fi
// menu, middle click runs a command.
BarIconWidget {
  id: root

  // From SystemManager's "link" metric
  readonly property string iface: SystemManager.netLink.device
  readonly property string kind: SystemManager.netLink.kind

  Component.onCompleted: SystemManager.acquire(root, {
    "metrics": ["link"],
    "interval": root.properties.interval
  })
  onPropertiesChanged: SystemManager.acquire(root, {
    "metrics": ["link"],
    "interval": root.properties.interval
  })
  Component.onDestruction: SystemManager.release(root)
  readonly property bool connected: kind !== ""

  backgroundColor: Theme.resolveColor(connected ? properties.backgroundColor : properties.disconnectedColor)
  icon: getIcon()
  text: iface
  showText: properties.showName && iface !== ""

  function getIcon() {
    switch (kind) {
    case "wifi":
      return "";
    case "ethernet":
      return "󰈀";
    default:
      return NetworkingManager.available && !NetworkingManager.wifiEnabled ? "\u{F092E}" : "󰤭";
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.properties.middleCommand !== ""
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.MiddleButton
    onClicked: Quickshell.execDetached(["sh", "-c", root.properties.middleCommand])
  }

  PopoutAnchor {
    popouts: root.popouts
    panel: root.panel
    popoutName: "WifiNetworks"
    active: root.properties.showPopout
  }
}
