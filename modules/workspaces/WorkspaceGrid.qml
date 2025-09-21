import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.services

Rectangle {
  id: root

  property real overviewScale: 0.15
  property int gridSize: 5
  property int workspaceSpacing: 10
  property var activeWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

  // property var screen: overlayWindow.screen ?? Screen.primaryScreen
  // property real workspaceWidth: (screen.width * overviewScale)
  // property real workspaceHeight: (screen.height * overviewScale)
  property real workspaceWidth: ((Hyprland.focusedMonitor?.width ?? 1920) * overviewScale)
  property real workspaceHeight: ((Hyprland.focusedMonitor?.height ?? 1080) * overviewScale)

  signal workspaceClicked(int workspaceId)

  implicitWidth: (workspaceWidth * gridSize) + (workspaceSpacing * (gridSize - 1)) + (padding * 2)
  implicitHeight: (workspaceHeight * gridSize) + (workspaceSpacing * (gridSize - 1)) + (padding * 2)

  property real padding: 20

  color: "#282828" // Gruvbox bg
  radius: 8
  border.width: 2
  border.color: "#3c3836" // Gruvbox bg1

  // Container for all workspace cells
  Item {
    id: workspaceContainer
    anchors.centerIn: parent
    width: (root.workspaceWidth * root.gridSize) + (root.workspaceSpacing * (root.gridSize - 1))
    height: (root.workspaceHeight * root.gridSize) + (root.workspaceSpacing * (root.gridSize - 1))

    // Create all 25 workspace cells explicitly
    Repeater {
      model: 25

      WorkspaceCell {
        id: workspaceCell
        workspaceId: index + 1
        width: root.workspaceWidth
        height: root.workspaceHeight
        isActive: workspaceId === root.activeWorkspace

        // Position in grid
        property int row: Math.floor(index / root.gridSize)
        property int col: index % root.gridSize

        x: col * (root.workspaceWidth + root.workspaceSpacing)
        y: row * (root.workspaceHeight + root.workspaceSpacing)

        onClicked: {
          root.workspaceClicked(workspaceId);
        }
      }
    }
  }

  // Window container - overlays on top of workspace cells
  Item {
    id: windowContainer
    anchors.centerIn: parent
    width: workspaceContainer.width
    height: workspaceContainer.height
    z: 1e6

    Repeater {
      model: HyprlandData.windowList

      delegate: DraggableWindow {
        id: windowDelegate
        required property var modelData
        required property int index

        windowData: modelData
        overviewScale: root.overviewScale
        gridSize: root.gridSize
        workspaceWidth: root.workspaceWidth
        workspaceHeight: root.workspaceHeight
        workspaceSpacing: root.workspaceSpacing

        // Calculate grid position from workspace ID
        property int wsId: modelData?.workspace?.id ?? 1
        property int wsIndex: wsId - 1
        property int gridRow: Math.floor(wsIndex / root.gridSize)
        property int gridCol: wsIndex % root.gridSize

        // Only show windows in the visible 5x5 grid (workspaces 1-25)
        visible: wsId >= 1 && wsId <= 25

        offsetX: gridCol * (root.workspaceWidth + root.workspaceSpacing)
        offsetY: gridRow * (root.workspaceHeight + root.workspaceSpacing)

        onWindowDropped: targetWorkspace => {
          if (modelData?.workspace?.id && targetWorkspace !== modelData.workspace.id) {
            Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${modelData.address}`);
            HyprlandData.updateAll();
          }
        }

        onWindowClicked: {
          if (modelData?.workspace?.id) {
            root.workspaceClicked(modelData.workspace.id);
            Hyprland.dispatch(`focuswindow address:${modelData.address}`);
          }
        }

        onWindowClosed: {
          if (modelData?.address) {
            Hyprland.dispatch(`closewindow address:${modelData.address}`);
            HyprlandData.updateAll();
          }
        }
      }
    }
  }

  // Component.onCompleted: {
  //   if (HyprlandData.windowList && HyprlandData.windowList.length > 0) {
  //     console.log("First window:", JSON.stringify(HyprlandData.windowList[0], null, 2));
  //   }
  // }
}
