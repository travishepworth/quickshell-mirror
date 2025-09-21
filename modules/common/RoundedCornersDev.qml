import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services

Item {
  PanelWindow {
    id: workspaceContainer
    property int borderWidth: 8
    property int innerBorderWidth: 1
    property int borderRadius: Settings.borderRadius
    property color borderColor: Colors.fg
    
    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }
    
    aboveWindows: false
    color: "transparent"
    
    WrapperManager {
      id: wrapperManager
      
      wrapper: ClippingWrapperRectangle {
        anchors.fill: parent
        radius: workspaceContainer.borderRadius
        color: "black"  // This is the background color
      }
      
      child: Rectangle {
        anchors.fill: parent
        color: "black"
      }
    }
  }
}
