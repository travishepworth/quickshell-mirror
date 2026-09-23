pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.config
import qs.components.reusable

// One mixer line: icon, title (+ dim subtitle), volume slider, percentage
// and a mute button. `selected` highlights it (the default device), and
// `selectable` makes clicking the row itself emit clicked().
Rectangle {
  id: root

  signal volumeMoved(real volume)
  signal muteToggled
  signal clicked

  // Glyph shown when there's no image (or it fails to load)
  property string icon: ""
  property string iconSource: ""
  property string title: ""
  property string subtitle: ""
  property real volume: 0
  property bool muted: false
  property real maxVolume: 1.0
  property bool selected: false
  property bool selectable: false
  property string mutedGlyph: "\u{F0581}"
  property string unmutedGlyph: "\u{F057E}"

  implicitHeight: layout.implicitHeight + Widget.spacing * 2
  Layout.fillWidth: true

  radius: Appearance.borderRadius
  color: selected ? Theme.backgroundHighlight : rowMouse.containsMouse && selectable ? Qt.rgba(Theme.backgroundHighlight.r, Theme.backgroundHighlight.g, Theme.backgroundHighlight.b, 0.5) : "transparent"
  border.width: selected ? Appearance.borderWidth : 0
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
    enabled: root.selectable
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  RowLayout {
    id: layout
    anchors.fill: parent
    anchors.margins: Widget.spacing
    anchors.leftMargin: Widget.padding
    anchors.rightMargin: Widget.padding
    spacing: Widget.padding

    Item {
      Layout.preferredWidth: 26
      Layout.preferredHeight: 26

      IconImage {
        id: image
        anchors.fill: parent
        source: root.iconSource
        visible: root.iconSource !== "" && status === Image.Ready
        opacity: root.muted ? 0.5 : 1
      }

      Text {
        anchors.centerIn: parent
        visible: !image.visible
        text: root.icon
        color: root.muted ? Theme.foregroundAlt : (root.selected ? Theme.accent : Theme.foreground)
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize * 1.4
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      RowLayout {
        Layout.fillWidth: true
        spacing: Widget.spacing

        StyledText {
          Layout.fillWidth: !subtitleText.visible
          Layout.maximumWidth: subtitleText.visible ? implicitWidth : -1
          text: root.title
          elide: Text.ElideRight
          textSize: Appearance.fontSize - 1
          textColor: root.muted ? Theme.foregroundAlt : Theme.foreground
        }

        StyledText {
          id: subtitleText
          Layout.fillWidth: true
          visible: root.subtitle !== "" && root.subtitle !== root.title
          text: root.subtitle
          elide: Text.ElideRight
          textSize: Appearance.fontSize - 3
          textColor: Theme.foregroundAlt
        }
      }

      StyledSlider {
        Layout.fillWidth: true
        Layout.preferredHeight: 16
        troughHeight: 6
        fillColor: root.muted ? Theme.foregroundAlt : Theme.accent
        // Not `value`: dragging assigns that, which would drop the binding
        targetValue: Math.min(1, root.volume / root.maxVolume)
        onMoved: value => root.volumeMoved(value * root.maxVolume)
        onReleased: value => root.volumeMoved(value * root.maxVolume)
      }
    }

    StyledText {
      Layout.preferredWidth: percentMetrics.width
      horizontalAlignment: Text.AlignRight
      text: `${Math.round(root.volume * 100)}%`
      textSize: Appearance.fontSize - 2
      textColor: Theme.foregroundAlt

      TextMetrics {
        id: percentMetrics
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize - 2
        text: "150%"
      }
    }

    StyledRectButton {
      Layout.preferredWidth: 28
      Layout.preferredHeight: 28
      iconText: root.muted ? root.mutedGlyph : root.unmutedGlyph
      iconColor: root.muted ? Theme.error : Theme.foreground
      backgroundColor: "transparent"
      borderHoverColor: Theme.accent
      tooltipText: root.muted ? "Unmute" : "Mute"
      onClicked: root.muteToggled()
    }
  }
}
