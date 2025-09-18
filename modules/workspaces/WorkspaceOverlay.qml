import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services

Scope {
  id: root
  objectName: "workspaceOverlay"

  property int gridSize: 5
  property int totalWorkspaces: 25
  property real overviewScale: 0.15 // Adjust this for window sizing
  Component.onCompleted: {
    console.log("Grid size:", implicitWidth, "x", implicitHeight);
    console.log("Window count:", HyprlandData.windowList.length);
  }

  IpcHandler {
    target: "workspaceOverlay"

    function toggle(): void {
      overlayWindow.visible = !overlayWindow.visible;
      if (overlayWindow.visible) {
        HyprlandData.updateAll();
      }
    }

    function show(): void {
      overlayWindow.visible = true;
      HyprlandData.updateAll();
    }

    function hide(): void {
      overlayWindow.visible = false;
    }
  }

  PanelWindow {
    id: overlayWindow

    anchors { top: true; bottom: true; left: true; right: true }

    visible: false
    focusable: visible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
      anchors.fill: parent
      focus: overlayWindow.focusable

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          overlayWindow.visible = false;
          event.accepted = true;
        }
      }
    }

    HyprlandFocusGrab {
      windows: [overlayWindow]
      active: overlayWindow.visible
      onCleared: {
        if (!active) {
          overlayWindow.visible = false;
        }
      }
    }

    // Semi-transparent background
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.7)

      MouseArea {
        anchors.fill: parent
        onClicked: {
          overlayWindow.visible = false;
        }
      }
    }

    // Main overlay content
    WorkspaceGrid {
      id: workspaceGrid
      anchors.centerIn: parent
      overviewScale: root.overviewScale
      onWorkspaceClicked: workspaceId => {
        overlayWindow.visible = false;
        Hyprland.dispatch(`workspace ${workspaceId}`);
      }
    }
  }
}
