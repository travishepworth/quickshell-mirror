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
Item {
  id: root

  required property var wrapper
  property bool hovered: hoverHandler.hovered

  // Set from the widget's PopoutAnchor payload
  property string mode: "output"
  property real maxVolume: 1.0

  property int currentTab: 0

  readonly property bool isInput: mode === "input"
  readonly property var defaultDevice: isInput ? Audio.defaultSource : Audio.defaultSink
  readonly property var apps: isInput ? Audio.recordingApps : Audio.playbackApps
  readonly property var devices: isInput ? Audio.sources : Audio.sinks
  readonly property string mutedGlyph: isInput ? "\u{F036D}" : "\u{F0581}"
  readonly property string unmutedGlyph: isInput ? "\u{F036C}" : "\u{F057E}"

  readonly property int margins: 16
  readonly property int maxListHeight: 360

  implicitWidth: 380
  implicitHeight: column.implicitHeight + margins * 2
  width: implicitWidth
  height: implicitHeight

  function deviceName(node) {
    return node?.description || node?.nickname || node?.name || "No device";
  }
  function deviceIcon(node, muted, level) {
    const kind = Audio.deviceKind(node);
    return isInput ? Audio.inputIcon(kind, muted) : Audio.outputIcon(kind, muted, level);
  }

  onCurrentTabChanged: fadeIn.restart()

  StyledContainer {
    anchors.fill: parent
    backgroundColor: Theme.background
    borderWidth: 0
    borderRadius: Appearance.borderRadius + 2

    HoverHandler {
      id: hoverHandler
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: root.margins
      spacing: Widget.spacing

      StyledText {
        text: root.isInput ? "Input" : "Output"
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
        onVolumeMoved: value => Audio.setNodeVolume(node, value, root.maxVolume)
        onMuteToggled: Audio.toggleNodeMute(node)
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
          model: [`Applications (${root.apps.length})`, "Devices"]

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
        Layout.preferredHeight: Math.min(root.maxListHeight, list.implicitHeight + contentPadding * 2)
        contentPadding: 0
        showScrollBar: list.implicitHeight > root.maxListHeight

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
              onVolumeMoved: value => appRow.modelData.nodes.forEach(n => Audio.setNodeVolume(n, value, root.maxVolume))
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
            text: root.isInput ? "No apps recording" : "No apps playing audio"
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
              onClicked: Audio.setDefault(deviceRow.modelData)
              onVolumeMoved: value => Audio.setNodeVolume(deviceRow.modelData, value, root.maxVolume)
              onMuteToggled: Audio.toggleNodeMute(deviceRow.modelData)
            }
          }

          StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Widget.padding
            Layout.bottomMargin: Widget.padding
            visible: root.currentTab === 1 && root.devices.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: "No devices found"
            textColor: Theme.foregroundAlt
          }
        }
      }
    }
  }
}
