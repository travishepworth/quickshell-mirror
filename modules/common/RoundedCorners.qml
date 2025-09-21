import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services

PanelWindow {
  id: workspaceContainer
  property int borderWidth: 8
  property int innerBorderWidth: 1
  property int borderRadius: Settings.borderRadius
  property color surfaceColor: Colors.accent3
  property color borderColor: "#cdd6f4"

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.namespace: "rounded-corners"

  // Make the entire window transparent
  color: "transparent"

  // Create the border effect with multiple rectangles
  // Top border (excluding corners)
  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      leftMargin: borderWidth + borderRadius
      rightMargin: borderWidth + borderRadius
    }
    height: borderWidth
    color: Colors.surface
  }

  // Bottom border (excluding corners)
  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      bottom: parent.bottom
      leftMargin: borderWidth + borderRadius
      rightMargin: borderWidth + borderRadius
    }
    height: borderWidth
    color: Colors.surface
  }

  // Left border (excluding corners)
  // Rectangle {
  //   anchors {
  //     left: parent.left
  //     top: parent.top
  //     bottom: parent.bottom
  //     topMargin: borderWidth + borderRadius
  //     bottomMargin: borderWidth + borderRadius
  //   }
  //   width: borderWidth
  //   color: Colors.surface
  // }

  // Right border (excluding corners)
  Rectangle {
    anchors {
      right: parent.right
      top: parent.top
      bottom: parent.bottom
      topMargin: borderWidth + borderRadius
      bottomMargin: borderWidth + borderRadius
    }
    width: borderWidth
    color: Colors.surface
  }

  // Top-left corner
  Rectangle {
    anchors {
      left: parent.left
      top: parent.top
    }
    width: borderWidth + borderRadius
    height: borderWidth + borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        right: parent.right
        bottom: parent.bottom
      }
      width: borderRadius
      height: borderRadius
      color: "transparent"
      radius: borderRadius
    }
  }

  // Top-right corner
  Rectangle {
    anchors {
      right: parent.right
      top: parent.top
    }
    width: borderWidth + borderRadius
    height: borderWidth + borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        left: parent.left
        bottom: parent.bottom
      }
      width: borderRadius
      height: borderRadius
      color: "transparent"
      radius: borderRadius
    }
  }

  // Bottom-left corner
  Rectangle {
    anchors {
      left: parent.left
      bottom: parent.bottom
    }
    width: borderWidth + borderRadius
    height: borderWidth + borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        right: parent.right
        top: parent.top
      }
      width: borderRadius
      height: borderRadius
      color: "transparent"
      radius: borderRadius
    }
  }

  // Bottom-right corner
  Rectangle {
    anchors {
      right: parent.right
      bottom: parent.bottom
    }
    width: borderWidth + borderRadius
    height: borderWidth + borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        left: parent.left
        top: parent.top
      }
      width: borderRadius
      height: borderRadius
      color: "transparent"
      radius: borderRadius
    }
  }

  // Inner border around the cutout
  Rectangle {
    anchors {
      fill: parent
      margins: borderWidth - innerBorderWidth
      leftMargin: 0
    }
    radius: borderRadius
    color: "transparent"
    border.width: innerBorderWidth
    border.color: borderColor
  }
}
