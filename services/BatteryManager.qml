pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs.config

QtObject {
  id: root

  property UPowerDevice battery: UPower.displayDevice?.isLaptopBattery ? UPower.displayDevice : null
  property bool isAvailable: battery !== null
  // UPowerDevice.percentage is a 0-1 ratio
  property int percentage: Math.round((battery?.percentage ?? 0) * 100)
  property bool isCharging: battery?.state === UPowerDeviceState.Charging
  property bool isDischarging: battery?.state === UPowerDeviceState.Discharging
  property bool isFull: battery?.state === UPowerDeviceState.FullyCharged
  property bool isLow: percentage <= 20
  property bool isCritical: percentage <= 10
  property string timeRemaining: formatTime(battery?.timeToEmpty ?? 0)
  property string timeToFull: formatTime(battery?.timeToFull ?? 0)

  function formatTime(seconds) {
    if (seconds <= 0)
      return "";

    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0) {
      return I18n.tr("{0}h {1}m", hours, minutes);
    } else {
      return I18n.tr("{0}m", minutes);
    }
  }

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
      return Theme.success;
    if (isCritical)
      return Theme.error;
    if (isLow)
      return Theme.warning;
    return Theme.backgroundHighlight;
  }
}
