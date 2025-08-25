import QtQuick
import Quickshell
import Quickshell.Io

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  property string iface: ""
  property string kind: "" // "wifi" | "ethernet" | ""
  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + labelIcon.implicitWidth + App.Settings.widgetPadding * 2

  Timer {
    id: poll
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      nm.command = ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3==\"connected\"{print $1\":\"$2; exit}'"];
      nm.running = true;
    }
  }

  Process {
    id: nm
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const out = (text || "").trim();
        const parts = out.split(":");
        root.iface = parts[0] || "";
        root.kind = parts[1] || "";
      }
    }
    onExited: {} // no-op; we only parse stdout above
  } function iconFor(k) { if (k === "wifi")
      return "";
    if (k === "ethernet")
      return "󰈀";
    return "󰤭";
  }

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.orange
    radius: App.Settings.borderRadius
  }

  Row {
    anchors.centerIn: parent
    spacing: 6
    Text {
      id: labelIcon
      color: Services.Colors.bg
      text: iconFor(root.kind)
      font.family: App.Settings.fontFamily
      font.pixelSize: App.Settings.fontSize
    }
    Text {
      id: label
      color: Services.Colors.bg
      text: root.iface || "—"
      font.family: App.Settings.fontFamily
      font.pixelSize: App.Settings.fontSize
    }
  }
}
