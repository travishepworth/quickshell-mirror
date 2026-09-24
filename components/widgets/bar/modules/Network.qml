pragma ComponentBehavior: Bound
import QtQuick

import qs.config
import qs.services
import qs.components.reusable

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
      return "󰤭";
    }
  }
}
