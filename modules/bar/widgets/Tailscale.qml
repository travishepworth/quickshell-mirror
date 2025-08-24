import QtQuick
import Quickshell
import Quickshell.Io

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent2
    radius: App.Settings.borderRadius
  }

  Timer {
    id: poll
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      tailscale.command = ["sh", "-c", "if tailscale status &>/dev/null; then echo '󰳌'; else echo '󰌙'; fi"];
      tailscale.running = true;
    }
  }

  Process {
    id: tailscale
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const out = (text || "").trim();
        label.text = out;
      }
    }
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Services.Colors.bg
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    // onClicked: 
  }
}

