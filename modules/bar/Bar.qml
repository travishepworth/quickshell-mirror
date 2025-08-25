import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "./widgets" as Widgets

import "root:/services" as Services
import "root:/" as App

Scope {
  property int barHeight: App.Settings.barHeight
  property string backgroundColor: Services.Colors.bg
  property string foregroundColor: Services.Colors.fg

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData
        screen: modelData

        anchors {
          top: true
          left: true
          right: true
        }

        implicitHeight: barHeight

        Rectangle {
          anchors.fill: parent
          color: backgroundColor

          Widgets.Workspaces {
            id: workspaces
            screen: panel.screen
            anchors.centerIn: parent
          }

          RowLayout {
            id: leftGroup
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: App.Settings.screenMargin
            Widgets.Window {
              id: window
            }
            Widgets.Media {
              id: media
            }
          }

          RowLayout {
            id: leftCenterGroup
            anchors.right: workspaces.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: App.Settings.screenMargin
            Widgets.Time {
              id: time
            }
            Widgets.WorkspaceIndicator {
              id: workspaceIndicator
            }
          }

          RowLayout {
            id: rightCenterGroup
            anchors.left: workspaces.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: App.Settings.widgetSpacing
            anchors.leftMargin: App.Settings.screenMargin
            Widgets.SystemMonitor {
              id: systemMonitor
            }
          }

          RowLayout {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            spacing: App.Settings.widgetSpacing
            anchors.rightMargin: App.Settings.screenMargin


            Widgets.Tailscale {
              id: tailscale
            }
            Widgets.Network {
              id: network
            }
            Widgets.SystemTray {
              id: tray
              visible: modelData.primary
            }
            Widgets.Notifications {
              id: notifications
            }
            Widgets.Logo {
              id: logo
            }
          }
        }
      }
    }
  }
}
