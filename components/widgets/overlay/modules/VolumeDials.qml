pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common
import qs.components.widgets.overlay

// Output and microphone volume as two dials: scroll to adjust, click to
// mute. Side by side in wide and square slots, stacked in tall ones;
// compact shows the output only.
OverlayCard {
  id: root

  component Dial: Item {
    id: dial
    property real level: 0
    property bool muted: false
    property string icon
    property string label
    signal toggled
    signal stepped(real delta)

    ColumnLayout {
      anchors.fill: parent
      spacing: Widget.spacing / 2
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        PercentageCircle {
          readonly property real side: Math.min(parent.width, parent.height)
          anchors.centerIn: parent
          width: side
          height: side
          percentage: dial.muted ? 0 : Math.round(dial.level * 100)
          iconText: dial.icon
          iconColor: dial.muted ? Theme.error : Theme.foreground
          fillColor: Theme.accent
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: dial.toggled()
          onWheel: wheel => dial.stepped(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }
      }
      StyledText {
        visible: !root.compact
        Layout.alignment: Qt.AlignHCenter
        text: dial.muted ? I18n.tr("{0} · muted", dial.label) : `${dial.label} · ${Math.round(dial.level * 100)}%`
        textSize: Appearance.fontSize - 2
        opacity: 0.8
      }
    }
  }

  GridLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    columns: root.shape === "vertical" ? 1 : 2
    columnSpacing: root.pad
    rowSpacing: root.pad

    Dial {
      Layout.fillWidth: true
      Layout.fillHeight: true
      level: AudioManager.volume
      muted: AudioManager.muted
      icon: AudioManager.muted ? "\u{F0581}" : "\u{F057E}"
      label: I18n.tr("Output")
      onToggled: AudioManager.toggleMute()
      onStepped: delta => AudioManager.setVolume(Math.max(0, Math.min(1, AudioManager.volume + delta)))
    }
    Dial {
      visible: !root.compact
      Layout.fillWidth: true
      Layout.fillHeight: true
      level: AudioManager.sourceVolume
      muted: AudioManager.sourceMuted
      icon: AudioManager.sourceMuted ? "\u{F036D}" : "\u{F036C}"
      label: I18n.tr("Mic")
      onToggled: AudioManager.toggleSourceMute()
      onStepped: delta => AudioManager.setSourceVolume(Math.max(0, Math.min(1, AudioManager.sourceVolume + delta)), 1)
    }
  }
}
