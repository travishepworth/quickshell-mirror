pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.services
import qs.config
import qs.components.reusable

// Volume mixer for the Volume ("output") and Microphone ("input") widgets:
// the default device on top, then an Applications tab (per-app volume,
// one row per app however many streams it has) and a Devices tab (pick the
// default, adjust each device).
PopoutContent {
  id: root

  // Set from the widget's PopoutAnchor payload
  property string mode: "output"
  property real maxVolume: 1.0

  property int currentTab: 0

  readonly property bool isInput: mode === "input"
  readonly property var defaultDevice: isInput ? AudioManager.defaultSource : AudioManager.defaultSink
  readonly property var apps: isInput ? AudioManager.recordingApps : AudioManager.playbackApps
  readonly property var devices: isInput ? AudioManager.sources : AudioManager.sinks
  readonly property string mutedGlyph: isInput ? "\u{F036D}" : "\u{F0581}"
  readonly property string unmutedGlyph: isInput ? "\u{F036C}" : "\u{F057E}"

  margins: 16
  readonly property int maxListHeight: 360

  implicitWidth: 380

  function deviceName(node) {
    return node?.description || node?.nickname || node?.name || I18n.tr("No device");
  }
  function deviceIcon(node, muted, level) {
    const kind = AudioManager.deviceKind(node);
    return isInput ? AudioManager.inputIcon(kind, muted) : AudioManager.outputIcon(kind, muted, level);
  }

  onCurrentTabChanged: fadeIn.restart()

  StyledText {
    text: I18n.tr(root.isInput ? "Input" : "Output")
    font.bold: true
    textColor: Theme.accent
  }

  // Default device, visible on both tabs
  AudioRow {
    readonly property var node: root.defaultDevice
    icon: root.deviceIcon(node, muted, volume)
    title: root.deviceName(node)
    volume: node?.audio?.volume ?? 0
    muted: node?.audio?.muted ?? false
    maxVolume: root.maxVolume
    mutedGlyph: root.mutedGlyph
    unmutedGlyph: root.unmutedGlyph
    onVolumeMoved: value => AudioManager.setNodeVolume(node, value, root.maxVolume)
    onMuteToggled: AudioManager.toggleNodeMute(node)
  }

  StyledSeparator {
    Layout.fillWidth: true
    separatorColor: Theme.backgroundHighlight
  }

  RowLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    spacing: Widget.spacing

    Repeater {
      model: [I18n.tr("Applications ({0})", root.apps.length), I18n.tr("Devices")]

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
    Layout.fillWidth: true
    Layout.preferredHeight: root.embedded ? -1 : Math.min(root.maxListHeight, list.implicitHeight + contentPadding * 2)
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

      // Applications
      Repeater {
        model: root.currentTab === 0 ? root.apps : []

        AudioRow {
          id: appRow
          required property var modelData
          readonly property var node: modelData.nodes[0]
          icon: root.unmutedGlyph
          iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
          title: modelData.name
          subtitle: modelData.subtitle
          volume: node?.audio?.volume ?? 0
          muted: node?.audio?.muted ?? false
          maxVolume: root.maxVolume
          mutedGlyph: root.mutedGlyph
          unmutedGlyph: root.unmutedGlyph
          onVolumeMoved: value => appRow.modelData.nodes.forEach(n => AudioManager.setNodeVolume(n, value, root.maxVolume))
          onMuteToggled: {
            const mute = !appRow.muted;
            appRow.modelData.nodes.forEach(n => {
              if (n.audio)
                n.audio.muted = mute;
            });
          }
        }
      }

      StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Widget.padding
        Layout.bottomMargin: Widget.padding
        visible: root.currentTab === 0 && root.apps.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr(root.isInput ? "No apps recording" : "No apps playing audio")
        textColor: Theme.foregroundAlt
      }

      // Devices
      Repeater {
        model: root.currentTab === 1 ? root.devices : []

        AudioRow {
          id: deviceRow
          required property var modelData
          icon: root.deviceIcon(modelData, false, 1)
          title: root.deviceName(modelData)
          volume: modelData.audio?.volume ?? 0
          muted: modelData.audio?.muted ?? false
          maxVolume: root.maxVolume
          mutedGlyph: root.mutedGlyph
          unmutedGlyph: root.unmutedGlyph
          selected: modelData === root.defaultDevice
          selectable: true
          onClicked: AudioManager.setDefault(deviceRow.modelData)
          onVolumeMoved: value => AudioManager.setNodeVolume(deviceRow.modelData, value, root.maxVolume)
          onMuteToggled: AudioManager.toggleNodeMute(deviceRow.modelData)
        }
      }

      StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Widget.padding
        Layout.bottomMargin: Widget.padding
        visible: root.currentTab === 1 && root.devices.length === 0
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("No devices found")
        textColor: Theme.foregroundAlt
      }
    }
  }
}
