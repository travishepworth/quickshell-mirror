pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.content.base

// Battery charge, state and time left; "On AC power" on machines without
// a battery.
Card {
  id: root

  ColumnLayout {
    anchors.centerIn: parent
    visible: !BatteryManager.isAvailable
    spacing: Widget.spacing / 2
    StyledIcon {
      Layout.alignment: Qt.AlignHCenter
      text: "power"
      textSize: Appearance.fontSize * 2.5
      opacity: 0.5
    }
    StyledText {
      visible: !root.compact
      Layout.alignment: Qt.AlignHCenter
      text: I18n.tr("On AC power")
      opacity: 0.6
    }
  }

  ColumnLayout {
    visible: BatteryManager.isAvailable
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
        percentage: Math.round(BatteryManager.percentage)
        iconText: BatteryManager.getBatteryIcon()
        iconColor: Theme.foreground
        fillColor: BatteryManager.isCritical ? Theme.error : BatteryManager.isLow ? Theme.warning : Theme.success
      }
    }
    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: `${Math.round(BatteryManager.percentage)}%`
      font.bold: true
    }
    StyledText {
      visible: !root.compact
      Layout.alignment: Qt.AlignHCenter
      text: BatteryManager.isCharging ? I18n.tr("Charging · {0} to full", BatteryManager.timeToFull) : BatteryManager.isFull ? I18n.tr("Fully charged") : I18n.tr("{0} left", BatteryManager.timeRemaining)
      textSize: Appearance.fontSize - 2
      opacity: 0.7
    }
  }
}
