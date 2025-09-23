import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.services
import qs.config

PanelWindow {
  id: workspaceContainer
  property int borderWidth: Settings.containerWidth
  property int innerBorderWidth: 1
  property int borderRadius: Settings.borderRadius
  property color borderColor: Colors.fg

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  aboveWindows: true
  WlrLayershell.layer: WlrLayer.Top
  color: "transparent"
  mask: Region {}

  // TODO: Figure out a better way to do this without a small black dot in
  // each corner.
  // Create the border effect with multiple rectangles
  // Top border (excluding corners)
  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      leftMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
      rightMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    }
    height: workspaceContainer.borderWidth
    color: Colors.surface
  }

  // Bottom border (excluding corners)
  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      bottom: parent.bottom
      leftMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
      rightMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    }
    height: workspaceContainer.borderWidth
    color: Colors.surface
  }

  // Left border (excluding corners)
  // Rectangle {
  //   anchors {
  //     left: parent.left
  //     top: parent.top
  //     bottom: parent.bottom
  //     topMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
  //     bottomMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
  //   }
  //   width: workspaceContainer.borderWidth
  //   color: Colors.surface
  // }

  // Right border (excluding corners)
  Rectangle {
    anchors {
      right: parent.right
      top: parent.top
      bottom: parent.bottom
      topMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
      bottomMargin: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    }
    width: workspaceContainer.borderWidth
    color: Colors.surface
  }

  // Top-left corner
  Rectangle {
    anchors {
      left: parent.left
      top: parent.top
    }
    width: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    height: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    color: Colors.surface

    Item {
      clip: true
      Rectangle {
        anchors {
          right: parent.right
          bottom: parent.bottom
        }
        width: workspaceContainer.borderRadius
        height: workspaceContainer.borderRadius
        color: Colors.accent
        radius: workspaceContainer.borderRadius
      }
    }
  }

  // Top-right corner
  Rectangle {
    anchors {
      right: parent.right
      top: parent.top
    }
    width: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    height: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        left: parent.left
        bottom: parent.bottom
      }
      width: workspaceContainer.borderRadius
      height: workspaceContainer.borderRadius
      color: "transparent"
      radius: workspaceContainer.borderRadius
    }
  }

  // Bottom-left corner
  Rectangle {
    anchors {
      left: parent.left
      bottom: parent.bottom
    }
    width: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    height: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        right: parent.right
        top: parent.top
      }
      width: workspaceContainer.borderRadius
      height: workspaceContainer.borderRadius
      color: "transparent"
      radius: workspaceContainer.borderRadius
    }
  }

  // Bottom-right corner
  Rectangle {
    anchors {
      right: parent.right
      bottom: parent.bottom
    }
    width: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    height: workspaceContainer.borderWidth + workspaceContainer.borderRadius
    color: Colors.surface

    Rectangle {
      anchors {
        left: parent.left
        top: parent.top
      }
      width: workspaceContainer.borderRadius
      height: workspaceContainer.borderRadius
      color: "transparent"
      radius: workspaceContainer.borderRadius
    }
  }

  // Inner border around the cutout
  Rectangle {
    anchors {
      fill: parent
      margins: workspaceContainer.borderWidth - workspaceContainer.innerBorderWidth
      leftMargin: 0
    }
    radius: workspaceContainer.borderRadius
    color: "transparent"
    border.width: workspaceContainer.innerBorderWidth
    border.color: workspaceContainer.borderColor
  }
}
