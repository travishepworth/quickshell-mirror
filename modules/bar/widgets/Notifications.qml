import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io

import qs.services

Item {
  id: root
  height: Settings.widgetHeight
  implicitWidth: label.implicitWidth + Settings.widgetPadding * 2

  // Quickshell’s notification server tracks notifications; we use its model length.
  property int count: NotificationServer.trackedNotifications.values[0].name

  Rectangle {
    anchors.fill: parent
    color: Colors.accent
    radius: Settings.borderRadius
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Colors.bg
    text: count > 0 ? "●" : ""
    font.family: Settings.fontFamily
    font.pixelSize: Settings.fontSize
  }

  // Open swaync panel; run detached so Quickshell isn’t tied to its lifecycle.
  Process {
    id: openPanel
    command: ["swaync-client","-op","-sw"]
    // we only want a one-shot detached spawn:
    onStarted: { openPanel.startDetached(); openPanel.running = false }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: openPanel.running = true
  }
}

