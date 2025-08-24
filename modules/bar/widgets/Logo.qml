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

  Text {
    id: label
    anchors.centerIn: parent
    color: Services.Colors.bg
    text: "" // Arch logo (Nerd Font)
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
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

