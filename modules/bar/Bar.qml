import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "./widgets" as Widgets

Scope {
  property int barHeight: 30
  property string backgroundColor: "#1e1e2e"
  property string foregroundColor: "#cdd6f4"

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData
        screen: modelData   // this is the output (DP-1, DP-2, ...)

        anchors {
          top: true
          left: true
          right: true
        }

        implicitHeight: barHeight

        Rectangle {
          anchors.fill: parent
          color: backgroundColor

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            // Left section: workspaces for this monitor
            Widgets.Workspaces {
              screen: panel.screen
              Layout.alignment: Qt.AlignVCenter
            }

            // spacer / other sections...
            Item {
              Layout.fillWidth: true
            }

            // Right section: system tray
            // Widgets.Tray { Layout.alignment: Qt.AlignRight }
          }
        }
      }
    }
  }
}
