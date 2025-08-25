import Quickshell
import Quickshell.Io
import QtQuick

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  property string time

  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
    onDateChanged: {
      label.text = Qt.formatDateTime(clock.date, "hh:mm:ss ap")
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent2
    radius: App.Settings.borderRadius
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Services.Colors.bg
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
    text: Qt.formatDateTime(clock.date, "HH:mm:ss")
  }
}
