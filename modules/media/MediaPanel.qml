import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import "root:/" as App
import qs.services

Scope {
  id: root
  objectName: "mediaPanel"

  function toggle() {
    popupWindow.visible = !popupWindow.visible;
  }
  function open() {
    popupWindow.visible = true;
  }
  function close() {
    popupWindow.visible = false;
  }

  Component.onCompleted: {
    console.log("MediaPanel: Initialized");
    console.log("MediaPanel: Player available:", Mpris.activePlayer !== null);
    MediaController.panelWindow = popupWindow;
  }

  // IPC handler for external control
  IpcHandler {
    target: "mediaPanel"

    function toggle(): void {
      popupWindow.visible = !popupWindow.visible;
    }

    function open(): void {
      popupWindow.visible = true;
    }

    function close(): void {
      popupWindow.visible = false;
    }
  }

  // Main popup window
  PanelWindow {
    id: popupWindow

    visible: false
    focusable: visible

    Item {
      anchors.fill: parent
      focus: mediaPanel.focusable
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          rightPanel.isOpen = false;
          event.accepted = true;
        }
      }
    }

    Timer {
      id: closeTimer
      interval: 800
      onTriggered: {
        popupWindow.visible = false;
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onEntered: {
        closeTimer.stop();
      }
      onExited: {
        if (popupWindow.visible) {
          closeTimer.start();
        }
      }
    }

    // Global shortcut inside the window
    GlobalShortcut {
      appid: "qs"
      name: "mediaPanel"
      description: "Toggle media popup"

      onPressed: {
        popupWindow.visible = !popupWindow.visible;
      }
    }

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    // Self-sizing
    implicitWidth: mainContent.width + 8
    implicitHeight: mainContent.height + 8

    WlrLayershell.namespace: "quickshell:mediaPanel"

    // Top left corner
    anchors {
      top: true
      left: true
    }

    margins {
      top: 10
      left: 10 + App.Settings.barHeight
    }

    // Focus management
    HyprlandFocusGrab {
      windows: [popupWindow]
      active: popupWindow.visible
      onCleared: {
        if (!active) {
          popupWindow.visible = false;
        }
      }
    }

    // Main container
    Rectangle {
      id: mainContent
      anchors.centerIn: parent
      width: contentLayout.width + 24
      height: contentLayout.height + 24

      color: Colors.surface
      radius: App.Settings.borderRadius
      border.color: Colors.outline
      border.width: 1

      // Shadow
      Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        z: -1
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, 0.3)
      }

      // Player content
      RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 12
        visible: Mpris.activePlayer !== null

        // Album art
        Rectangle {
          width: 80
          height: 80
          radius: App.Settings.borderRadius
          color: Colors.surfaceAlt
          clip: true

          Image {
            anchors.fill: parent
            source: Mpris.artDownloaded ? Qt.resolvedUrl(Mpris.artFilePath) : ""
            fillMode: Image.PreserveAspectCrop
            visible: Mpris.artDownloaded
            asynchronous: true
          }

          Text {
            anchors.centerIn: parent
            text: "♪"
            color: Colors.accent
            font.pixelSize: 28
            font.family: App.Settings.fontFamily
            visible: !Mpris.artDownloaded
          }
        }

        // Info and controls
        Column {
          spacing: 4
          width: 250

          // Track title
          Text {
            text: Mpris.trackTitle
            color: Colors.accent
            font.pixelSize: App.Settings.fontSize
            font.family: App.Settings.fontFamily
            font.weight: Font.Medium
            elide: Text.ElideRight
            width: parent.width
          }

          // Artist
          Text {
            text: Mpris.trackArtist
            color: Colors.accent2
            font.pixelSize: App.Settings.fontSize - 2
            font.family: App.Settings.fontFamily
            elide: Text.ElideRight
            width: parent.width
          }

          // Progress bar
          Rectangle {
            width: parent.width
            height: 3
            radius: 1.5
            color: Colors.surfaceAlt2

            Rectangle {
              width: parent.width * Mpris.progress
              height: parent.height
              radius: parent.radius
              color: Mpris.isPlaying ? Colors.purple : Colors.accent

              Behavior on width {
                NumberAnimation {
                  duration: 100
                }
              }
            }
          }

          // Controls
          Row {
            spacing: 8

            // Previous
            MouseArea {
              width: 28
              height: 28
              cursorShape: Qt.PointingHandCursor
              onClicked: Mpris.previous()

              Rectangle {
                anchors.fill: parent
                radius: App.Settings.borderRadius
                color: parent.containsMouse ? Colors.surfaceAlt : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "⏮"
                  color: Colors.accent
                  font.pixelSize: 14
                  font.family: App.Settings.fontFamily
                }
              }
            }

            // Play/Pause
            MouseArea {
              width: 36
              height: 36
              cursorShape: Qt.PointingHandCursor
              onClicked: Mpris.playPause()

              Rectangle {
                anchors.fill: parent
                radius: parent.width / 2
                color: Mpris.isPlaying ? Colors.purple : Colors.surfaceAlt

                Text {
                  anchors.centerIn: parent
                  text: Mpris.isPlaying ? "⏸" : "▶"
                  color: Mpris.isPlaying ? Colors.surface : Colors.accent
                  font.pixelSize: 16
                  font.family: App.Settings.fontFamily
                }

                Behavior on color {
                  ColorAnimation {
                    duration: 150
                  }
                }
              }
            }

            // Next
            MouseArea {
              width: 28
              height: 28
              cursorShape: Qt.PointingHandCursor
              onClicked: Mpris.next()

              Rectangle {
                anchors.fill: parent
                radius: App.Settings.borderRadius
                color: parent.containsMouse ? Colors.surfaceAlt : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "⏭"
                  color: Colors.accent
                  font.pixelSize: 14
                  font.family: App.Settings.fontFamily
                }
              }
            }

            Item {
              width: 20
            }

            // Time display
            Text {
              text: Mpris.formatTime(Mpris.position) + " / " + Mpris.formatTime(Mpris.length)
              color: Colors.accent3
              font.pixelSize: App.Settings.fontSize - 4
              font.family: App.Settings.fontFamily
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }
      }

      // No player message
      Text {
        anchors.centerIn: parent
        text: "No media player"
        color: Colors.accent
        font.pixelSize: App.Settings.fontSize
        font.family: App.Settings.fontFamily
        visible: Mpris.activePlayer === null
      }
    }
  }
}
