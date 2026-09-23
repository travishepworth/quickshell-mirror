pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.common
import qs.components.widgets.bar.popouts.content

// Bluetooth devices (the bar's list: connect, pair, discover). Compact
// shows how many are connected.
OverlayCard {
  id: root

  StatFigure {
    visible: root.compact
    anchors.centerIn: parent
    value: BluetoothManager.enabled ? String(BluetoothManager.connectedDevices.length) : I18n.tr("off")
    label: I18n.tr("connected")
    valueColor: BluetoothManager.connectedDevices.length > 0 ? Theme.accent : Theme.foreground
  }

  Loader {
    anchors.fill: parent
    // Created only when shown: its Discover tab starts scanning
    active: !root.compact
    sourceComponent: BluetoothPopout {
      wrapper: null
      embedded: true
    }
  }
}
