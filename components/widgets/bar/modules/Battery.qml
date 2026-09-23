pragma ComponentBehavior: Bound
import QtQuick

import qs.services
// Aliased: this file's own type is also called Battery
import qs.services as Services
import qs.config
import qs.components.reusable

IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  // From UPower's display device (services/Battery.qml)
  readonly property bool isCharging: Services.Battery.isCharging
  readonly property bool isDischarging: Services.Battery.isDischarging
  readonly property int percentage: Services.Battery.percentage
  readonly property string timeRemaining: isCharging ? Services.Battery.timeToFull : Services.Battery.timeRemaining
  // "none" / "low" / "critical": the last level notified about, so each
  // threshold notifies once per crossing
  property string _notifiedLevel: "none"

  readonly property string level: {
    if (isCharging)
      return "none";
    if (percentage <= properties.criticalThreshold)
      return "critical";
    if (percentage <= properties.lowThreshold)
      return "low";
    return "none";
  }

  isVertical: barConfig.vertical

  icon: getBatteryIcon()
  text: `${percentage}%`
  showText: properties.showPercentage

  backgroundColor: getBatteryColor()
  foregroundColor: Theme.resolveColor(properties.foregroundColor)

  iconScale: 1.1
  textScale: 0.9

  function getBatteryIcon() {
    if (isCharging) {
      if (percentage >= 90)
        return "󰂅";
      if (percentage >= 80)
        return "󰂋";
      if (percentage >= 60)
        return "󰂊";
      if (percentage >= 40)
        return "󰢞";
      if (percentage >= 20)
        return "󰢝";
      return "󰢜";
    } else {
      if (percentage >= 90)
        return "󰁹";
      if (percentage >= 80)
        return "󰂂";
      if (percentage >= 70)
        return "󰂁";
      if (percentage >= 60)
        return "󰂀";
      if (percentage >= 50)
        return "󰁿";
      if (percentage >= 40)
        return "󰁾";
      if (percentage >= 30)
        return "󰁽";
      if (percentage >= 20)
        return "󰁼";
      if (percentage >= 10)
        return "󰁻";
      return "󰁺";
    }
  }

  function getBatteryColor() {
    if (isCharging)
      return Theme.resolveColor(properties.chargingColor);
    if (level === "critical")
      return Theme.resolveColor(properties.criticalColor);
    if (level === "low")
      return Theme.resolveColor(properties.lowColor);
    return Theme.resolveColor(properties.backgroundColor);
  }

  function getBatteryStatus() {
    let status = I18n.tr(isCharging ? "Charging" : "Discharging");
    let details = `${status}: ${percentage}%`;
    if (timeRemaining) {
      details += " " + (isCharging ? I18n.tr("({0} to full)", timeRemaining) : I18n.tr("({0} remaining)", timeRemaining));
    }
    return details;
  }

  // Charging animation
  SequentialAnimation {
    running: root.isCharging && Appearance.animations
    loops: Animation.Infinite

    PropertyAnimation {
      target: root
      property: "opacity"
      from: 1.0
      to: 0.7
      duration: Appearance.animSlow * 5
      easing.type: Easing.InOutQuad
    }

    PropertyAnimation {
      target: root
      property: "opacity"
      from: 0.7
      to: 1.0
      duration: Appearance.animSlow * 5
      easing.type: Easing.InOutQuad
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      Notifs.sendNotification("axiom", I18n.tr("Battery Status"), root.getBatteryStatus());
    }
  }

  // Low battery notifications, once each time a threshold is crossed
  onLevelChanged: {
    if (properties.notify && level !== _notifiedLevel) {
      if (level === "critical")
        Notifs.sendNotification("axiom", I18n.tr("Critical Battery"), I18n.tr("Battery critically low: {0}%", percentage));
      else if (level === "low" && _notifiedLevel !== "critical")
        Notifs.sendNotification("axiom", I18n.tr("Low Battery"), I18n.tr("Battery low: {0}%", percentage));
    }
    _notifiedLevel = level;
  }
}
