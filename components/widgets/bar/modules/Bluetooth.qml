pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.services
import qs.config
import qs.components.reusable
import qs.components.widgets.bar.popouts

// Bluetooth status: off / on / connected, optionally with the connected
// device's name and battery. Click toggles power, middle click runs a
// command; hovering opens the Bluetooth menu. (Reads BluetoothManager
// only: inside this file `Bluetooth` would mean this component.)
BarIconWidget {
  id: root

  readonly property var connected: BluetoothManager.connectedDevices
  readonly property var firstDevice: connected[0] ?? null

  readonly property bool hidden: properties.hideWhenOff && !BluetoothManager.enabled

  icon: !BluetoothManager.enabled ? "\u{F00B2}" : connected.length > 0 ? "\u{F00B1}" : "\u{F00AF}"
  text: {
    if (connected.length > 1)
      return I18n.tr("{0} devices", connected.length);
    if (!firstDevice)
      return "";
    const battery = properties.showBattery && firstDevice.batteryAvailable ? ` ${Math.round(firstDevice.battery * 100)}%` : "";
    return BluetoothManager.deviceLabel(firstDevice) + battery;
  }
  showIcon: !hidden
  showText: properties.showDevice && text !== "" && !hidden
  padding: hidden ? 0 : Widget.padding

  backgroundColor: Theme.resolveColor(!BluetoothManager.enabled ? properties.disabledColor : connected.length > 0 ? properties.connectedColor : properties.backgroundColor)
  opacity: mouseArea.pressed ? 0.8 : 1

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    enabled: !root.hidden
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) {
        if (root.properties.middleCommand)
          Quickshell.execDetached(["sh", "-c", root.properties.middleCommand]);
      } else {
        BluetoothManager.toggleEnabled();
      }
    }
  }

  PopoutAnchor {
    popouts: root.popouts
    panel: root.panel
    popoutName: "Bluetooth"
    active: root.properties.showPopout && !root.hidden && BluetoothManager.available
  }
}
