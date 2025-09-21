import QtQuick
import Quickshell
import Quickshell.Io

import qs.services

Item {
  id: root
  required property var screen

  height: Settings.widgetHeight
  implicitWidth: label.implicitWidth + Settings.widgetPadding * 2
  property int orientation: Settings.orientation  // Accept orientation from parent
  property bool isVertical: orientation === Qt.Vertical

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

  function formatIconVertical(index) {
    index = parseInt(index) - 1;
    const col = index % cols;
    const workspaceStartCol = startingWorkspace % cols;

    if (col === workspaceStartCol - 1) {
      return "";  // or "↙" - leftmost column
    } else if (col === workspaceStartCol + 0) {
      return "";  // or "↓" - second column
    } else if (col === workspaceStartCol + 1) {
      return "";  // or "↘" - middle column
    } else if (col === workspaceStartCol + 2) {
      return "";  // or "→" - fourth column
    } else if (col === workspaceStartCol + 3) {
      return "";  // or "↗" - rightmost column
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.accent2
    radius: Settings.borderRadius
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
        // const out = formatIcon((text || "").trim());
        const out = isVertical ? formatIconVertical((text || "").trim()) : formatIcon((text || "").trim());
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
    onClicked: logMonitorName()
  }
}
