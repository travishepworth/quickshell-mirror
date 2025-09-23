import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.services
import qs.config

Scope {
  id: root
  objectName: "osd"
  property color backgroundColor: Colors.bg
  property color foregroundColor: Colors.fg
  
  // Connect to the AudioService singleton
  Connections {
    target: Audio
    
    function onVolumeChanged() {
      root.shouldShowOsd = true;
      hideTimer.restart();
    }
    
    function onMutedChanged() {
      // Optional: show OSD on mute toggle as well
      root.shouldShowOsd = true;
      hideTimer.restart();
    }
  }
  
  property bool shouldShowOsd: false
  
  Timer {
    id: hideTimer
    interval: 1000
    onTriggered: root.shouldShowOsd = false
  }
  
  // The OSD window will be created and destroyed based on shouldShowOsd.
  // PanelWindow.visible could be set instead of using a loader, but using
  // a loader will reduce the memory overhead when the window isn't open.
  LazyLoader {
    active: root.shouldShowOsd
    
    PanelWindow {
      // Since the panel's screen is unset, it will be picked by the compositor
      // when the window is created. Most compositors pick the current active monitor.
      anchors.bottom: true
      margins.bottom: screen.height / 5
      exclusiveZone: 0
      implicitWidth: 400
      implicitHeight: 50
      color: "transparent"
      
      // An empty click mask prevents the window from blocking mouse events.
      mask: Region {}
      
      Rectangle {
        anchors.fill: parent
        border.width: Settings.borderWidth
        border.color: Colors.accent
        radius: Settings.borderRadius
        color: Colors.surface
        
        RowLayout {
          anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 15
          }
          
          IconImage {
            implicitSize: 30
            source: {
              const iconBase = "file:///home/" + Settings.userName + "/.config/quickshell/travmonkey/assets/icons/"
              if (Audio.muted) {
                return iconBase + "volume-muted.svg"
              } else if (Audio.volume > 0.66) {
                return iconBase + "volume-high.svg"
              } else if (Audio.volume > 0.33) {
                return iconBase + "volume-low.svg"
              } else if (Audio.volume > 0) {
                return iconBase + "volume-low.svg"
              } else {
                return iconBase + "volume-muted.svg"
              }
            }
          }
          
          Rectangle {
            // Volume bar container/trough
            Layout.fillWidth: true
            implicitHeight: 10
            radius: Settings.borderRadius
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.2) // Semi-transparent foreground color for trough
            
            Rectangle {
              // Volume bar fill
              anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
              }
              width: parent.width * Audio.volume
              radius: parent.radius
              color: Audio.muted ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5) : Colors.accent
              
              Behavior on width {
                NumberAnimation {
                  duration: 100
                  easing.type: Easing.OutCubic
                }
              }
            }
          }
          
          Text {
            text: Math.round(Audio.volume * 100) + "%"
            color: Colors.fg
            font.pixelSize: 14
            font.family: "VictorMono Nerd Font"
          }
        }
      }
    }
  }
}
