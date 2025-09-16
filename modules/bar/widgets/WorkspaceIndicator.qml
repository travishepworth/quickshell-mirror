import QtQuick
import Quickshell
import Quickshell.Io

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  required property var screen

  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  property string monitorName: screen.name

  property int rows: 5
  property int cols: 5

  property int startingWorkspace: determineStartingWorkspace()
  property int totalWorkspaces: rows * cols

  function logMonitorName() {
    console.log("Monitor Name: " + monitorName);
  }

  function determineStartingWorkspace() {
    if (screen.name === "DP-1") {
      return 1;
    } else if (screen.name === "DP-2") {
      return totalWorkspaces + 1;
    }
  }

  function formatIcon(index) {
    index = parseInt(index) - 1;
    
    const row = Math.floor(index / cols);
    const workspaceStartRow = Math.floor(startingWorkspace / cols);
    
    if (row === workspaceStartRow) {
        return "";
    } else if (row === workspaceStartRow + 1) {
        return "";
    } else if (row === workspaceStartRow + 2) {
        return "";
    } else if (row === workspaceStartRow + 3) {
        return "";
    } else if (row === workspaceStartRow + 4) {
        return "";
    }
}

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent2
    radius: App.Settings.borderRadius
  }

  Timer {
    id: poll
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      workspace.command = ["sh", "-c", `hyprctl -j monitors | jq '.[] | select(.name == "${monitorName}") | .activeWorkspace.id'`];
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
    onClicked: logMonitorName()
  }
}

