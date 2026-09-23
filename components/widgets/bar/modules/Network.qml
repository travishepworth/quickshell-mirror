pragma ComponentBehavior: Bound

import qs.config
import qs.components.reusable

BarIconWidget {
  id: root

  property string iface: ""
  property string kind: ""
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
