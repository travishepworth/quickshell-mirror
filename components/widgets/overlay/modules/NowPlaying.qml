pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay

// The active media player: art over a blurred copy of itself, track info,
// a seek bar and controls. Wide: art beside the info. Square/tall: stacked.
// Compact: just the art and play/pause.
OverlayCard {
  id: root

  readonly property bool hasPlayer: MediaManager.hasActivePlayer
  readonly property string artSource: MediaManager.artDownloaded && MediaManager.artVersion >= 0 ? "file://" + MediaManager.artFilePath : ""
  readonly property bool wide: root.shape === "horizontal"

  component MediaButton: Rectangle {
    id: button
    property string icon
    property real size: Widget.height
    property bool primary: false
    signal clicked
    implicitWidth: button.size
    implicitHeight: button.size
    radius: button.size / 2
    color: button.primary ? Theme.accent : buttonArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
    StyledText {
      anchors.centerIn: parent
      text: button.icon
      textColor: button.primary ? Theme.background : Theme.foreground
      textSize: button.size * 0.5
    }
    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  component Art: Rectangle {
    radius: Appearance.borderRadius
    color: Theme.backgroundAlt
    clip: true
    Image {
      anchors.fill: parent
      source: root.artSource
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      visible: status === Image.Ready
    }
    StyledText {
      anchors.centerIn: parent
      visible: root.artSource === ""
      text: "\u{F075A}"
      textSize: Math.min(parent.width, parent.height) * 0.4
      opacity: 0.4
    }
  }

  // Blurred, dimmed art behind everything
  Image {
    id: backdrop
    anchors.fill: parent
    source: root.artSource
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }
  MultiEffect {
    anchors.fill: parent
    anchors.margins: root.border.width
    source: backdrop
    visible: root.hasPlayer && backdrop.status === Image.Ready
    blurEnabled: true
    blur: 1
    blurMax: 48
    brightness: -0.35
    saturation: 0.2
  }

  // --- No player ---
  ColumnLayout {
    anchors.centerIn: parent
    visible: !root.hasPlayer
    spacing: Widget.spacing
    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: "\u{F075A}"
      textSize: Appearance.fontSize * 2.5
      opacity: 0.4
    }
    StyledText {
      visible: !root.compact
      Layout.alignment: Qt.AlignHCenter
      text: I18n.tr("Nothing playing")
      opacity: 0.6
    }
  }

  // --- Compact: art + play/pause ---
  Item {
    anchors.fill: parent
    anchors.margins: root.pad
    visible: root.hasPlayer && root.compact
    Art {
      anchors.fill: parent
    }
    MediaButton {
      anchors.centerIn: parent
      primary: true
      size: Math.min(parent.width, parent.height) * 0.4
      icon: MediaManager.isPlaying ? "\u{F03E4}" : "\u{F040A}"
      onClicked: MediaManager.togglePlayPause()
    }
  }

  // --- Full ---
  GridLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    visible: root.hasPlayer && !root.compact
    columns: root.wide ? 2 : 1
    columnSpacing: root.pad
    rowSpacing: Widget.spacing

    Art {
      readonly property real side: root.wide ? parent.height : Math.min(parent.width, parent.height * 0.5)
      Layout.preferredWidth: side
      Layout.preferredHeight: side
      Layout.alignment: Qt.AlignHCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Widget.spacing / 2

      // Player name; click to switch when there are several
      StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: MediaManager.identity + (MediaManager.players.length > 1 ? "  \u{F0450}" : "")
        textSize: Appearance.fontSize - 2
        opacity: 0.6
        MouseArea {
          anchors.fill: parent
          enabled: MediaManager.players.length > 1
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            const players = MediaManager.players;
            MediaManager.selectPlayer(players[(players.indexOf(MediaManager.activePlayer) + 1) % players.length]);
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }

      StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: MediaManager.trackTitle || I18n.tr("Unknown track")
        textSize: Appearance.fontSize + 4
        font.bold: true
      }
      StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: MediaManager.trackArtist
        opacity: 0.8
      }

      // Seek bar
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Widget.spacing * 2
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: 4
          radius: 2
          color: Qt.rgba(1, 1, 1, 0.15)
          Rectangle {
            width: parent.width * Math.min(1, Math.max(0, MediaManager.progress))
            height: parent.height
            radius: 2
            color: Theme.accent
          }
        }
        MouseArea {
          anchors.fill: parent
          enabled: MediaManager.canSeek
          cursorShape: Qt.PointingHandCursor
          onClicked: mouse => MediaManager.setPositionByRatio(mouse.x / width)
        }
      }
      RowLayout {
        Layout.fillWidth: true
        StyledText {
          text: MediaManager.formatTime(MediaManager.position)
          textSize: Appearance.fontSize - 3
          opacity: 0.6
        }
        Item {
          Layout.fillWidth: true
        }
        StyledText {
          text: MediaManager.formatTime(MediaManager.length)
          textSize: Appearance.fontSize - 3
          opacity: 0.6
        }
      }

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Widget.spacing
        MediaButton {
          icon: "\u{F04AE}"
          enabled: MediaManager.canGoPrevious
          opacity: enabled ? 1 : 0.4
          onClicked: MediaManager.previous()
        }
        MediaButton {
          primary: true
          size: Widget.height * 1.4
          icon: MediaManager.isPlaying ? "\u{F03E4}" : "\u{F040A}"
          onClicked: MediaManager.togglePlayPause()
        }
        MediaButton {
          icon: "\u{F04AD}"
          enabled: MediaManager.canGoNext
          opacity: enabled ? 1 : 0.4
          onClicked: MediaManager.next()
        }
      }
    }
  }
}
