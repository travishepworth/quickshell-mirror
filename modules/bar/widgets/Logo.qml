import QtQuick
import Quickshell
import Quickshell.Io

import qs.services as Services

Item {
  id: root
  height: Settings.widgetHeight
  implicitWidth: label.implicitWidth + Settings.widgetPadding * 2

  Rectangle {
    anchors.fill: parent
    color: Colors.accent2
    radius: Settings.borderRadius
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Colors.bg
    text: "" // Arch logo (Nerd Font)
    font.family: Settings.fontFamily
    font.pixelSize: Settings.fontSize
  }

  Process {
    id: wlogout
    command: ["wlogout"]
    onStarted: { wlogout.startDetached(); wlogout.running = false }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: wlogout.running = true
  }
}

