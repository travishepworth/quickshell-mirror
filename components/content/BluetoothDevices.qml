pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

import qs.services
import qs.config
import qs.components.reusable
import qs.components.content.base
import qs.components.content.parts

// Bluetooth menu for the Bluetooth widget: power switch, a Devices tab for
// paired devices (connect / disconnect / forget) and a Discover tab that
// scans while it's open and pairs + connects on click.
Panel {
  id: root

  property int currentTab: 0
  // Only stop a scan this popout started
  property bool _startedScan: false

  readonly property var shownDevices: currentTab === 0 ? BluetoothManager.pairedDevices : BluetoothManager.discoveredDevices

  margins: 16
  readonly property int maxListHeight: 360

  compactContent: StatFigure {
    value: BluetoothManager.enabled ? String(BluetoothManager.connectedDevices.length) : I18n.tr("off")
    label: I18n.tr("connected")
    valueColor: BluetoothManager.connectedDevices.length > 0 ? Theme.accent : Theme.foreground
  }

  implicitWidth: 360

  function updateScan() {
    const want = currentTab === 1 && BluetoothManager.enabled;
    if (want && !BluetoothManager.discovering) {
      BluetoothManager.setDiscovering(true);
      _startedScan = true;
    } else if (!want && _startedScan) {
      BluetoothManager.setDiscovering(false);
      _startedScan = false;
    }
  }

  onCurrentTabChanged: {
    updateScan();
    fadeIn.restart();
  }
  Connections {
    target: BluetoothManager
    function onEnabledChanged() {
      root.updateScan();
    }
  }
  Component.onDestruction: {
    if (_startedScan)
      BluetoothManager.setDiscovering(false);
  }

  component DeviceRow: Rectangle {
    id: row
    required property var modelData
    readonly property var device: modelData
    readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + Widget.spacing * 2
    radius: Appearance.borderRadius
    color: device.connected ? Theme.backgroundHighlight : rowMouse.containsMouse ? Qt.rgba(Theme.backgroundHighlight.r, Theme.backgroundHighlight.g, Theme.backgroundHighlight.b, 0.5) : "transparent"
    border.width: device.connected ? Appearance.borderWidth : 0
    border.color: Theme.accent

    Behavior on color {
      ColorAnimation {
        duration: Appearance.animFast
      }
    }

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: row.busy ? Qt.BusyCursor : Qt.PointingHandCursor
      onClicked: BluetoothManager.toggleDevice(row.device)
    }

    RowLayout {
      id: rowLayout
      anchors.fill: parent
      anchors.margins: Widget.spacing
      anchors.leftMargin: Widget.padding
      anchors.rightMargin: Widget.spacing
      spacing: Widget.padding

      StyledText {
        Layout.preferredWidth: 26
        horizontalAlignment: Text.AlignHCenter
        text: BluetoothManager.deviceIcon(row.device)
        textSize: Appearance.fontSize * 1.4
        textColor: row.device.connected ? Theme.accent : Theme.foreground
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
          Layout.fillWidth: true
          text: BluetoothManager.deviceLabel(row.device)
          elide: Text.ElideRight
          textSize: Appearance.fontSize - 1
        }
        StyledText {
          Layout.fillWidth: true
          text: BluetoothManager.deviceStatus(row.device)
          elide: Text.ElideRight
          textSize: Appearance.fontSize - 3
          textColor: row.busy ? Theme.accent : Theme.foregroundAlt
        }
      }

      StyledRectButton {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        enabled: !row.busy
        opacity: enabled ? 1 : 0.5
        iconText: row.device.connected ? "\u{F0338}" : "\u{F0337}"
        backgroundColor: "transparent"
        borderHoverColor: Theme.accent
        tooltipText: I18n.tr(row.device.connected ? "Disconnect" : (row.device.paired ? "Connect" : "Pair and connect"))
        onClicked: BluetoothManager.toggleDevice(row.device)
      }

      StyledRectButton {
        visible: row.device.paired || row.device.bonded
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        iconText: "\u{F01B4}"
        iconColor: Theme.error
        backgroundColor: "transparent"
        borderHoverColor: Theme.error
        tooltipText: I18n.tr("Forget")
        onClicked: BluetoothManager.forget(row.device)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Widget.spacing

    StyledText {
      Layout.fillWidth: true
      text: BluetoothManager.adapter?.name ? I18n.tr("Bluetooth · {0}", BluetoothManager.adapter.name) : I18n.tr("Bluetooth")
      elide: Text.ElideRight
      font.bold: true
      textColor: Theme.accent
    }

    StyledText {
      visible: BluetoothManager.discovering
      text: I18n.tr("Scanning…")
      textSize: Appearance.fontSize - 2
      textColor: Theme.foregroundAlt
    }

    StyledSwitch {
      enabled: BluetoothManager.available && !BluetoothManager.blocked
      checked: BluetoothManager.enabled
      onToggled: BluetoothManager.setEnabled(checked)
    }
  }

  StyledText {
    Layout.fillWidth: true
    Layout.topMargin: Widget.padding
    Layout.bottomMargin: Widget.padding
    visible: !BluetoothManager.enabled
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    text: I18n.tr(!BluetoothManager.available ? "No Bluetooth adapter found" : BluetoothManager.blocked ? "Bluetooth is blocked (rfkill)" : "Bluetooth is off")
    textColor: Theme.foregroundAlt
  }

  StyledSeparator {
    visible: BluetoothManager.enabled
    Layout.fillWidth: true
    separatorColor: Theme.backgroundHighlight
  }

  RowLayout {
    visible: BluetoothManager.enabled
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    spacing: Widget.spacing

    Repeater {
      model: [I18n.tr("Devices ({0})", BluetoothManager.pairedDevices.length), I18n.tr("Discover")]

      StyledTabButton {
        required property int index
        required property string modelData
        text: modelData
        checked: root.currentTab === index
        onClicked: root.currentTab = index
      }
    }
  }

  StyledScrollView {
    id: scroll
    visible: BluetoothManager.enabled
    Layout.fillWidth: true
    Layout.preferredHeight: root.embedded ? -1 : Math.min(root.maxListHeight, list.implicitHeight)
    Layout.fillHeight: root.embedded
    contentPadding: 0
    showScrollBar: root.embedded || list.implicitHeight > root.maxListHeight

    ColumnLayout {
      id: list
      width: scroll.availableWidth
      spacing: 2

      NumberAnimation on opacity {
        id: fadeIn
        from: 0
        to: 1
        duration: Appearance.animNormal
      }

      Repeater {
        model: root.shownDevices

        DeviceRow {}
      }

      StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Widget.padding
        Layout.bottomMargin: Widget.padding
        visible: root.shownDevices.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr(root.currentTab === 0 ? "No paired devices" : "Looking for devices…")
        textColor: Theme.foregroundAlt
      }
    }
  }
}
