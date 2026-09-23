pragma ComponentBehavior: Bound

import qs.config
import qs.components.reusable

IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  property string iface: ""
  property string kind: ""
  readonly property bool connected: kind !== ""

  isVertical: barConfig.vertical

  backgroundColor: Theme.resolveColor(connected ? properties.backgroundColor : properties.disconnectedColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)
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

  PollingProcess {
    interval: root.properties.interval
    command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3==\"connected\"{print $1\":\"$2; exit}'"]

    onDataReceived: data => {
      const parts = data.split(":");
      root.iface = parts[0] || "";
      root.kind = parts[1] || "";
    }
  }
}
