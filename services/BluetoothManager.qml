pragma Singleton
import QtQuick
import Quickshell.Bluetooth

// Bluetooth state and actions over the default adapter (BlueZ via
// Quickshell.Bluetooth). Named BluetoothManager so it doesn't shadow
// Quickshell's `Bluetooth` singleton, or the `Bluetooth` bar widget.
QtObject {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool available: adapter !== null
  readonly property bool enabled: adapter?.enabled ?? false
  readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
  readonly property bool discovering: adapter?.discovering ?? false

  // Connected first, then paired, then by name
  readonly property var devices: [...(adapter?.devices?.values ?? [])].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || deviceLabel(a).localeCompare(deviceLabel(b)))
  readonly property var pairedDevices: devices.filter(d => d.paired || d.bonded)
  // Nearby devices found by a scan; unnamed ones (bare addresses) are noise
  readonly property var discoveredDevices: devices.filter(d => !d.paired && !d.bonded && d.deviceName)
  readonly property var connectedDevices: devices.filter(d => d.connected)

  // Devices whose connect should follow a pair started from here
  property var _connectAfterPair: []

  function setEnabled(on) {
    if (adapter)
      adapter.enabled = on;
  }

  function toggleEnabled() {
    setEnabled(!enabled);
  }

  function setDiscovering(on) {
    if (adapter && enabled && adapter.discovering !== on)
      adapter.discovering = on;
  }

  // Connected: disconnect. Paired: connect. New: trust, pair, then connect.
  function toggleDevice(device) {
    if (!device || device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting)
      return;
    if (device.connected) {
      device.disconnect();
    } else if (device.paired || device.bonded) {
      device.connect();
    } else {
      device.trusted = true;
      _connectAfterPair = _connectAfterPair.concat([device]);
      device.pair();
    }
  }

  function forget(device) {
    device?.forget();
  }

  function deviceLabel(device) {
    return device?.name || device?.deviceName || device?.address || "Unknown";
  }

  function deviceStatus(device) {
    if (!device)
      return "";
    if (device.pairing)
      return "Pairing…";
    switch (device.state) {
    case BluetoothDeviceState.Connecting:
      return "Connecting…";
    case BluetoothDeviceState.Disconnecting:
      return "Disconnecting…";
    case BluetoothDeviceState.Connected:
      return device.batteryAvailable ? `Connected · ${Math.round(device.battery * 100)}%` : "Connected";
    }
    return device.paired || device.bonded ? "Paired" : "Not paired";
  }

  // Glyph for a device's freedesktop icon name (BlueZ "icon" property)
  function deviceIcon(device) {
    const icon = device?.icon || "";
    if (icon.includes("headset"))
      return "\u{F02CE}";
    if (icon.includes("headphone") || icon === "audio-card")
      return "\u{F02CB}";
    if (icon.startsWith("audio"))
      return "\u{F04C3}";
    if (icon.includes("mouse"))
      return "\u{F037D}";
    if (icon.includes("keyboard"))
      return "\u{F030C}";
    if (icon.includes("gaming"))
      return "\u{F0EB5}";
    if (icon.includes("phone"))
      return "\u{F011C}";
    if (icon.includes("computer"))
      return "\u{F0322}";
    return "\u{F00AF}";
  }

  // Finish "pair then connect" for devices paired from here
  property Instantiator _pairWatcher: Instantiator {
    model: root._connectAfterPair

    delegate: Connections {
      required property var modelData
      target: modelData

      function onPairedChanged() {
        root._connectAfterPair = root._connectAfterPair.filter(d => d !== modelData);
        if (modelData.paired)
          modelData.connect();
      }

      function onPairingChanged() {
        // Pairing ended without success (rejected, timed out)
        if (!modelData.pairing && !modelData.paired)
          root._connectAfterPair = root._connectAfterPair.filter(d => d !== modelData);
      }
    }
  }
}
