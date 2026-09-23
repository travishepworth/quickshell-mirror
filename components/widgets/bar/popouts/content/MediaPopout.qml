pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.services
import qs.config
import qs.components.reusable

Item {
  id: root

  required property var wrapper
  property string currentName: "media-player"

  // --- Seek state ---
  property bool isSeeking: false
  property real dragRatio: 0

  readonly property real displayProgress: isSeeking ? dragRatio : MprisController.progress
  readonly property real displayPosition: isSeeking ? dragRatio * MprisController.length : MprisController.position

  property bool hovered: hoverHandler.hovered || root.isSeeking

  readonly property int margins: 24
  readonly property int sectionSpacing: 16
  readonly property int artSize: 56
  readonly property int sliderHeight: 20
  readonly property int timeRowHeight: 16
  readonly property int controlsHeight: 44

  implicitWidth: 320
  implicitHeight: margins * 2 + artSize + sectionSpacing + sliderHeight + 4 + timeRowHeight + sectionSpacing + controlsHeight
  width: implicitWidth
  height: implicitHeight

  StyledContainer {
    id: content
    anchors.fill: parent

    backgroundColor: Theme.background
    borderColor: Theme.backgroundAlt
    borderWidth: 0
    borderRadius: Appearance.borderRadius + 2

    HoverHandler {
      id: hoverHandler
    }

    ColumnLayout {
      id: mainColumn
      anchors.fill: parent
      anchors.margins: root.margins
      spacing: root.sectionSpacing

      // --- Header: art + track info ---
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.artSize
        spacing: 12

        StyledContainer {
          id: artFrame
          Layout.preferredWidth: root.artSize
          Layout.preferredHeight: root.artSize
          Layout.alignment: Qt.AlignTop
          borderRadius: Appearance.borderRadius
          backgroundColor: Theme.backgroundAlt
          clip: true

          Image {
            id: artImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            // artVersion is bumped whenever a fresh file lands at
            // artFilePath, so referencing it here forces a reload.
            source: (MprisController.artDownloaded && MprisController.artVersion >= 0) ? ("file://" + MprisController.artFilePath) : ""
            visible: status === Image.Ready
          }

          StyledText {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready
            text: MprisController.isPlaying ? "♪" : "⏸"
            textSize: 22
            textColor: Theme.foregroundAlt
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.alignment: Qt.AlignVCenter
          spacing: 2

          StyledText {
            Layout.fillWidth: true
            text: MprisController.trackTitle || I18n.tr("No track playing")
            textColor: Theme.accent
            textSize: Appearance.fontSize * 1.05
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          StyledText {
            Layout.fillWidth: true
            text: MprisController.trackArtist || " "
            textColor: Theme.foregroundAlt
            textSize: Appearance.fontSize * 0.9
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          StyledText {
            Layout.fillWidth: true
            // MprisController doesn't surface the album itself, but the
            // underlying Mpris player object does.
            text: (MprisController.activePlayer?.trackAlbum ?? "") || " "
            textColor: Theme.foregroundAlt
            textSize: Appearance.fontSize * 0.8
            opacity: 0.7
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }
      }

      // --- Seek slider ---
      ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.sliderHeight + 4 + root.timeRowHeight
        spacing: 4

        Item {
          id: sliderArea
          Layout.fillWidth: true
          Layout.preferredHeight: root.sliderHeight

          readonly property real trackHeight: 6
          readonly property real thumbSize: 12

          StyledContainer {
            id: sliderTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: sliderArea.trackHeight
            borderRadius: height / 2
            borderWidth: 0
            backgroundColor: Theme.backgroundAlt

            StyledContainer {
              height: parent.height
              borderRadius: parent.borderRadius
              borderWidth: 0
              backgroundColor: Theme.accent
              width: Math.max(sliderArea.thumbSize / 2, parent.width * root.displayProgress)

              Behavior on width {
                enabled: !root.isSeeking
                NumberAnimation {
                  duration: Appearance.animNormal
                }
              }
            }
          }

          StyledContainer {
            id: sliderThumb
            width: sliderArea.thumbSize
            height: sliderArea.thumbSize
            borderRadius: width / 2
            backgroundColor: Theme.accent
            borderColor: Theme.background
            borderWidth: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.min(Math.max(0, sliderTrack.width * root.displayProgress - width / 2), sliderTrack.width - width / 2)
            scale: seekMouseArea.pressed ? 1.3 : 1.0

            Behavior on scale {
              NumberAnimation {
                duration: Appearance.animFast
              }
            }
          }

          // Floating time readout shown while dragging — the "feedback"
          // for the slider.
          StyledContainer {
            id: seekTooltip
            visible: root.isSeeking
            backgroundColor: Theme.background
            borderColor: Theme.backgroundAlt
            borderWidth: 1
            borderRadius: 4
            width: seekTooltipText.implicitWidth + 10
            height: seekTooltipText.implicitHeight + 6
            x: Math.min(Math.max(0, sliderThumb.x + sliderThumb.width / 2 - width / 2), sliderArea.width - width)
            y: -height - 6

            StyledText {
              id: seekTooltipText
              anchors.centerIn: parent
              text: MprisController.formatTime(root.displayPosition)
              textColor: Theme.foregroundAlt
              textSize: Appearance.fontSize * 0.8
            }
          }

          MouseArea {
            id: seekMouseArea
            anchors.fill: parent
            enabled: MprisController.canSeek
            cursorShape: Qt.PointingHandCursor

            function ratioFromX(mx) {
              return Math.min(1, Math.max(0, mx / sliderArea.width));
            }

            onPressed: mouse => {
              root.isSeeking = true;
              root.dragRatio = ratioFromX(mouse.x);
            }

            onPositionChanged: mouse => {
              if (root.isSeeking)
                root.dragRatio = ratioFromX(mouse.x);
            }

            onReleased: mouse => {
              if (root.isSeeking) {
                root.dragRatio = ratioFromX(mouse.x);
                MprisController.setPositionByRatio(root.dragRatio);
              }
              root.isSeeking = false;
            }

            onCanceled: {
              root.isSeeking = false;
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: root.timeRowHeight

          StyledText {
            text: MprisController.formatTime(root.displayPosition)
            textColor: Theme.foregroundAlt
            textSize: Appearance.fontSize * 0.8
          }

          Item {
            Layout.fillWidth: true
          }

          StyledText {
            text: MprisController.formatTime(MprisController.length)
            textColor: Theme.foregroundAlt
            textSize: Appearance.fontSize * 0.8
          }
        }
      }

      // --- Transport controls ---
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.controlsHeight
        Layout.alignment: Qt.AlignHCenter
        spacing: 22

        StyledIconButton {
          readonly property int size: 30

          Layout.fillWidth: false
          Layout.fillHeight: false
          Layout.preferredWidth: size
          Layout.preferredHeight: size

          iconText: "⏮"
          iconSize: size * 0.42
          borderRadius: size / 2
          iconColor: Theme.foregroundAlt
          backgroundColor: Theme.backgroundAlt
          hoverColor: Theme.accentAlt
          pressColor: Theme.accentAlt

          enabled: MprisController.canGoPrevious
          onClicked: MprisController.previous()
        }

        StyledIconButton {
          readonly property int size: 42

          Layout.fillWidth: false
          Layout.fillHeight: false
          Layout.preferredWidth: size
          Layout.preferredHeight: size

          iconText: MprisController.isPlaying ? "⏸" : "▶"
          iconSize: size * 0.42
          borderRadius: size / 2
          iconColor: Theme.background
          backgroundColor: Theme.accent
          hoverColor: Theme.accent
          pressColor: Theme.accent

          enabled: MprisController.canTogglePlaying
          onClicked: MprisController.togglePlayPause()
        }

        StyledIconButton {
          readonly property int size: 30

          Layout.fillWidth: false
          Layout.fillHeight: false
          Layout.preferredWidth: size
          Layout.preferredHeight: size

          iconText: "⏭"
          iconSize: size * 0.42
          borderRadius: size / 2
          iconColor: Theme.foregroundAlt
          backgroundColor: Theme.backgroundAlt
          hoverColor: Theme.accentAlt
          pressColor: Theme.accentAlt

          enabled: MprisController.canGoNext
          onClicked: MprisController.next()
        }
      }
    }
  }
}
