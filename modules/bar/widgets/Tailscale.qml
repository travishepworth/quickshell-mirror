import QtQuick
import Quickshell
import Quickshell.Io


import qs.services

Item {
  id: root
  height: Settings.widgetHeight
  implicitWidth: label.implicitWidth + Settings.widgetPadding * 2

  Rectangle {
    anchors.fill: parent
    color: Colors.yellow
    radius: Settings.borderRadius
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
    color: Colors.bg
    font.family: Settings.fontFamily
    font.pixelSize: Settings.fontSize
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    // onClicked: 
  }
}

