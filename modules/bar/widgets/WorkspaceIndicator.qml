import QtQuick
import Quickshell
import Quickshell.Io

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  function formatIcon(index) {
    index = parseInt(index);
    if (1 <= index && index <= 5) {
      return "";
    } else if (6 <= index && index <= 10) {
      return "";
    } else if (11 <= index && index <= 15) {
      return "";
    }

  }

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent2
    radius: App.Settings.borderRadius
  }

  Timer {
    id: poll
    interval: 500
    running: true
    repeat: true
    onTriggered: {
      workspace.command = ["sh", "-c", "hyprctl -j activeworkspace | jq .id"];
      workspace.running = true;
    }
  }

  Process {
    id: workspace
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const out = formatIcon((text || "").trim());
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

