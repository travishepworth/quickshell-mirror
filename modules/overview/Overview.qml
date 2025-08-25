// modules/overview/Overview.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/" as App
import "root:/services" as Services
import "." // WorkspaceBox.qml

Item {
  id: overview
  // do NOT shadow Item.visible — use our own flag
  property bool open: false

  // Toggle via Hyprland: `hyprctl dispatch global qs:overview-toggle`
  GlobalShortcut {
    appid: "qs"
    name: "overview-toggle"
    description: "Toggle 3x5 Workspace Overview"
    onPressed: overview.open = !overview.open
  }

  // Optional, but nice to auto-close if focus is stolen
  HyprlandFocusGrab {
    id: grab
    active: overview.open
    onCleared: overview.open = false
  }

  // One window per output
  Variants {
    id: perScreen
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        WlrLayershell.layer: WlrLayer.Overlay
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        visible: overview.open

        // no color on PanelWindow; draw inside
        Rectangle {
          anchors.fill: parent
          color: Services.Colors.surface
          opacity: 0.6

          GridLayout {
            id: grid
            anchors.fill: parent
            anchors.margins: 20
            rowSpacing: 16
            columnSpacing: 16
            columns: 5

            Repeater {
              model: 15
              delegate: WorkspaceBox {
                workspaceId: index + 1

                // Settings-driven sizing / AR / radius
                boxWidth: App.Settings.resolutionWidth
                boxHeight: App.Settings.resolutionHeight
                borderRadius: App.Settings.borderRadius

                Layout.fillWidth: true
                readonly property real cellW: (grid.width - (grid.columnSpacing * (grid.columns - 1))) / grid.columns
                readonly property real ar: boxHeight / boxWidth
                Layout.preferredWidth: cellW
                Layout.preferredHeight: cellW * ar

                onRequestGoToWorkspace: ws => {
                  Hyprland.dispatch(`workspace ${ws}`)
                  overview.open = false
                }
                // onRequestMoveClientToWorkspace: (addr, ws) => {
                //   Hyprland.dispatch(`movetoworkspace ${ws},address:${addr}`)
                // }
              }
            }
          }
        }
      }
    }
  }
}

