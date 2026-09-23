pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common
import qs.components.widgets.overlay

// Battery charge, state and time left; "On AC power" on machines without
// a battery.
OverlayCard {
  id: root

  ColumnLayout {
    anchors.centerIn: parent
    visible: !Battery.isAvailable
    spacing: Widget.spacing / 2
    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: "\u{F06A5}"
      textSize: Appearance.fontSize * 2.5
      opacity: 0.5
    }
    StyledText {
      visible: !root.compact
      Layout.alignment: Qt.AlignHCenter
      text: "On AC power"
      opacity: 0.6
    }
  }

  ColumnLayout {
    visible: Battery.isAvailable
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      PercentageCircle {
        readonly property real side: Math.min(parent.width, parent.height)
        anchors.centerIn: parent
        width: side
        height: side
        percentage: Math.round(Battery.percentage)
        iconText: Battery.getBatteryIcon()
        iconColor: Theme.foreground
        fillColor: Battery.isCritical ? Theme.error : Battery.isLow ? Theme.warning : Theme.success
      }
    }
    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: `${Math.round(Battery.percentage)}%`
      font.bold: true
    }
    StyledText {
      visible: !root.compact
      Layout.alignment: Qt.AlignHCenter
      text: Battery.isCharging ? `Charging · ${Battery.timeToFull} to full` : Battery.isFull ? "Fully charged" : `${Battery.timeRemaining} left`
      textSize: Appearance.fontSize - 2
      opacity: 0.7
    }
  }
}
