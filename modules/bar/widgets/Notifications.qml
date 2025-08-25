import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  // Quickshell’s notification server tracks notifications; we use its model length.
  property int count: NotificationServer.trackedNotifications.values[0].name

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent
    radius: App.Settings.borderRadius
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Services.Colors.bg
    text: count > 0 ? "●" : ""
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
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

