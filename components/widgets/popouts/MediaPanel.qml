import QtQuick
import QtQuick.Layouts
// import Quickshell
// import Quickshell.Io
// import Quickshell.Wayland
// import Quickshell.Hyprland

import qs.services
import qs.config

Item {
  id: root

  required property var wrapper  // Reference to the popout wrapper
  property string currentName: "media-panel"

  // Data passed from the media widget (if needed)
  property var currentData: wrapper.currentData

  // Size of the expanded panel
  implicitWidth: mainContent.width
  implicitHeight: mainContent.height
  width: implicitWidth
  height: implicitHeight

  Component.onCompleted: {
    console.log("MediaPanel: Initialized");
    console.log("MediaPanel: Player available:", Mpris.activePlayer !== null);
  }

  // Main container
  Rectangle {
    id: mainContent
    anchors.centerIn: parent
    width: contentLayout.width + 40
    height: contentLayout.height + 40

    color: Colors.bg
    border.color: Colors.fg
    border.width: 1
    radius: Settings.borderRadius + 2

    // Hover handler to control popout closure
    HoverHandler {
      id: hoverHandler
      onHoveredChanged: {
        if (hovered) {
          exitTimer.stop();
        } else {
          exitTimer.restart();
        }
      }
    }

    // Player content
    RowLayout {
      id: contentLayout
      anchors.centerIn: parent
      spacing: 16
      visible: Mpris.activePlayer !== null

      // Album art
      Rectangle {
        id: albumArtContainer
        width: 120
        height: 120
        radius: Settings.borderRadius
        color: Colors.bgAlt
        clip: true

        property int reloadCounter: 0

        Connections {
          target: Mpris
          function onArtReady() {
            console.log("Art downloaded changed:", Mpris.artDownloaded, "path:", Mpris.artFilePath);
            artReloadDelay.restart();
          }
        }

        Timer {
          id: artReloadDelay
          interval: 200
          repeat: false
          onTriggered: {
            albumArtContainer.reloadCounter++;
            artImage.source = "";
            artImage.source = Mpris.artDownloaded ? Qt.resolvedUrl(Mpris.artFilePath) : "";
          }
        }

        property string artSource: ""
        function loadAlbumArt() {
          while (reloadCounter < 10) {
            reloadCounter++;
            if (Mpris.artDownloaded) {
              artSource = Qt.resolvedUrl(Mpris.artFilePath) + "?v=" + Date.now();  // Cache buster
              artImage.source = artSource;
              break;
            } else {
              artSource = "";
              artImage.source = "";
            }
          }
        }

        Image {
          id: artImage
          anchors.fill: parent
          source: Mpris.artDownloaded ? Qt.resolvedUrl(Mpris.artFilePath) : ""
          fillMode: Image.PreserveAspectCrop
          visible: Mpris.artDownloaded
          asynchronous: true
          cache: false  // Force reload when artDownloaded changes

          Behavior on opacity {
            NumberAnimation {
              duration: 150
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: "♪"
          color: Colors.accent
          font.pixelSize: 40
          font.family: Settings.fontFamily
          visible: !Mpris.artDownloaded
          opacity: 0.5
        }
      }

      // Info and controls
      Column {
        spacing: 8
        width: 280

        // Track title
        Text {
          text: Mpris.trackTitle || "Unknown Track"
          color: Colors.outline
          font.pixelSize: Settings.fontSize + 2
          font.family: Settings.fontFamily
          font.weight: Font.Medium
          elide: Text.ElideLeft
          // width: parent.width
        }

        // Artist
        Text {
          text: Mpris.trackArtist || "Unknown Artist"
          color: Colors.outline
          font.pixelSize: Settings.fontSize
          font.family: Settings.fontFamily
          elide: Text.ElideRight
          // width: parent.width
        }

        // Album (if available)
        Text {
          text: Mpris.trackAlbum || ""
          color: Colors.outline
          font.pixelSize: Settings.fontSize - 1
          font.family: Settings.fontFamily
          elide: Text.ElideRight
          width: parent.width
          visible: text !== ""
          opacity: 0.8
        }

        Item {
          height: 4
        }

        // Progress bar
        Rectangle {
          width: parent.width
          height: 4
          radius: 2
          color: Colors.bgAlt
          Rectangle {
            id: progressBar
            width: parent.width * (seekMouseArea.isDragging ? seekMouseArea.dragPosition : Mpris.progress)
            height: parent.height
            radius: parent.radius
            color: Mpris.isPlaying ? Colors.accent : Colors.accent2
            Behavior on width {
              enabled: !seekMouseArea.isDragging
              NumberAnimation {
                duration: 100
              }
            }
            Behavior on color {
              ColorAnimation {
                duration: 150
              }
            }
          }
          MouseArea {
            id: seekMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            property bool isDragging: false
            property real dragPosition: 0

            Timer {
              id: seekThrottle
              interval: 50  // Throttle to 20 updates per second
              repeat: false
              onTriggered: {
                if (seekMouseArea.isDragging) {
                  Mpris.commitSeek(seekMouseArea.dragPosition);
                }
              }
            }

            onPressed: {
              isDragging = true;
              dragPosition = mouseX / width;
              Mpris.commitSeek(dragPosition);  // Immediate seek on press
            }

            onReleased: {
              isDragging = false;
              seekThrottle.stop();
              Mpris.commitSeek(mouseX / width);  // Final precise seek
            }

            onPositionChanged: {
              if (isDragging && Mpris.activePlayer && Mpris.activePlayer.canSeek) {
                dragPosition = Math.max(0, Math.min(1, mouseX / width));
                seekThrottle.restart();  // Throttled seeking while dragging
              }
            }
          }
        }

        // Time display
        Row {
          width: parent.width
          spacing: 4

          Text {
            text: Mpris.formatTime(Mpris.position)
            color: Colors.outline
            font.pixelSize: Settings.fontSize - 2
            font.family: Settings.fontFamily
            opacity: 0.9
          }

          Text {
            text: " / "
            color: Colors.outline
            font.pixelSize: Settings.fontSize - 2
            font.family: Settings.fontFamily
            opacity: 0.7
          }

          Text {
            text: Mpris.formatTime(Mpris.length)
            color: Colors.outline
            font.pixelSize: Settings.fontSize - 2
            font.family: Settings.fontFamily
            opacity: 0.9
          }
        }

        Item {
          height: 4
        }

        // Controls
        Row {
          spacing: 12
          anchors.horizontalCenter: parent.horizontalCenter

          // Previous
          Rectangle {
            width: 36
            height: 36
            radius: Settings.borderRadius
            color: prevMouseArea.containsMouse ? Colors.accent2 : (prevMouseArea.pressed ? Colors.accent : Colors.bgAlt)
            property bool hovered: false

            MouseArea {
              id: prevMouseArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Mpris.previous()
              onEntered: parent.hovered = true
              onExited: parent.hovered = false
            }

            Text {
              anchors.centerIn: parent
              text: "⏮"
              color: prevMouseArea.containsMouse ? Colors.bg : Colors.surface
              font.pixelSize: 16
              font.family: Settings.fontFamily
            }

            Behavior on color {
              ColorAnimation {
                duration: 150
              }
            }

            Behavior on scale {
              NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
              }
            }

            scale: prevMouseArea.pressed ? 0.95 : 1.0
          }

          // Play/Pause
          Rectangle {
            width: 44
            height: 44
            radius: width / 2
            color: playMouseArea.containsMouse ? (Mpris.isPlaying ? Colors.accent : Colors.accent2) : (Mpris.isPlaying ? Colors.accent2 : Colors.accent)
            property bool hovered: false

            MouseArea {
              id: playMouseArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Mpris.playPause()
              onEntered: parent.hovered = true
              onExited: parent.hovered = false
            }

            Text {
              anchors.centerIn: parent
              text: Mpris.isPlaying ? "⏸" : "▶"
              color: Colors.bg
              font.pixelSize: 18
              font.family: Settings.fontFamily
            }

            Behavior on color {
              ColorAnimation {
                duration: 150
              }
            }

            Behavior on scale {
              NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
              }
            }

            scale: playMouseArea.pressed ? 0.95 : 1.0
          }

          // Next
          Rectangle {
            width: 36
            height: 36
            radius: Settings.borderRadius
            color: nextMouseArea.containsMouse ? Colors.accent2 : (nextMouseArea.pressed ? Colors.accent : Colors.bgAlt)
            property bool hovered: false

            MouseArea {
              id: nextMouseArea
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Mpris.next()
              onEntered: parent.hovered = true
              onExited: parent.hovered = false
            }

            Text {
              anchors.centerIn: parent
              text: "⏭"
              color: nextMouseArea.containsMouse ? Colors.bg : Colors.surface
              font.pixelSize: 16
              font.family: Settings.fontFamily
            }

            Behavior on color {
              ColorAnimation {
                duration: 150
              }
            }

            Behavior on scale {
              NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
              }
            }

            scale: nextMouseArea.pressed ? 0.95 : 1.0
          }
        }

        Item {
          height: 4
        }

        // Volume control (if available)
        Row {
          spacing: 8
          visible: Mpris.activePlayer.canControl && Mpris.activePlayer.volume !== undefined
          anchors.horizontalCenter: parent.horizontalCenter

          Text {
            text: "🔊"
            color: Colors.outline
            font.pixelSize: Settings.fontSize
            font.family: Settings.fontFamily
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: 100
            height: 4
            radius: 2
            color: Colors.bgAlt
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
              width: parent.width * (Mpris.activePlayer.volume || 0)
              height: parent.height
              radius: parent.radius
              color: Colors.accent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor

              property bool isDragging: false

              onPressed: {
                isDragging = true;
                updateVolume(mouseX);
              }

              onReleased: {
                isDragging = false;
              }

              onPositionChanged: {
                if (isDragging && Mpris.activePlayer.canControl) {
                  updateVolume(mouseX);
                }
              }

              function updateVolume(x) {
                if (Mpris.activePlayer.canControl) {
                  let newVolume = Math.max(0, Math.min(1, x / width));
                  Mpris.activePlayer.volume = newVolume;
                }
              }
            }
          }

          Text {
            text: Math.round((Mpris.activePlayer.volume || 0) * 100) + "%"
            color: Colors.outline
            font.pixelSize: Settings.fontSize - 2
            font.family: Settings.fontFamily
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }

    // No player message
    Column {
      anchors.centerIn: parent
      spacing: 8
      visible: Mpris.activePlayer === null

      Text {
        text: "No Media Playing"
        color: Colors.surface
        font.pixelSize: Settings.fontSize
        font.family: Settings.fontFamily
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: "Start playing something to see controls"
        color: Colors.outline
        font.pixelSize: Settings.fontSize - 2
        font.family: Settings.fontFamily
        opacity: 0.7
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  // Timer to handle popout closure when not hovered
  Timer {
    id: exitTimer
    interval: 40
    onTriggered: {
      root.wrapper.closePopout();
    }
  }

  // Helper functions
  function getPlayerInfo() {
    return {
      player: Mpris.activePlayer,
      playing: Mpris.isPlaying,
      title: Mpris.trackTitle,
      artist: Mpris.trackArtist
    };
  }
}
