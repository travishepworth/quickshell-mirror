import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "./widgets" as Widgets

import qs.services
import qs.modules.bar.popouts

Scope {
  id: root
  property int barHeight: Settings.barHeight
  property int barWidth: Settings.verticalBar ? Settings.barHeight : undefined
  property color backgroundColor: Colors.bg
  property color foregroundColor: Colors.fg

  property var popouts: null

  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData
        screen: modelData

        anchors {
          top: Settings.verticalBar ? true : (modelData.name === "DP-1")
          bottom: Settings.verticalBar ? true : (modelData.name === "DP-2")
          left: Settings.verticalBar ? !Settings.rightVerticalBar : true
          right: Settings.verticalBar ? Settings.rightVerticalBar : true
        }

        visible: if (modelData.name === "DP-1")
          true
        else if (modelData.name === "DP-2" && !Settings.singleMonitor)
          true
        else
          false

        implicitHeight: Settings.verticalBar ? undefined : barHeight
        implicitWidth: Settings.verticalBar ? barWidth : undefined
        // implicitWidth: Settings.verticalBar ? (barWidth + (popouts.hasCurrent ? (popouts.width + popouts.gap) : 0)) : undefined

        Rectangle {
          anchors.fill: parent
          color: backgroundColor

          // PopoutWrapper {
          //   id: popouts
          //   screen: panel.screen
          //   z: 10000 // ON TOP
          // }

          // Workspaces centered
          Widgets.Workspaces {
            id: workspaces
            screen: panel.screen
            popouts: root.popouts
            anchors.centerIn: parent
            orientation: Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
          }

          // Top/Left group
          Loader {
            id: leftGroup
            sourceComponent: Settings.verticalBar ? verticalLeftGroup : horizontalLeftGroup

            anchors {
              left: Settings.verticalBar ? undefined : parent.left
              top: Settings.verticalBar ? parent.top : undefined
              horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
              leftMargin: Settings.verticalBar ? 0 : Settings.screenMargin
              topMargin: Settings.verticalBar ? Settings.screenMargin : 0
            }

            Component {
              id: horizontalLeftGroup
              RowLayout {
                Widgets.Window {
                  id: window
                  orientation: Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
                }
                Widgets.Media {
                  id: media
                  visible: modelData.name === "DP-1"
                }
              }
            }

            Component {
              id: verticalLeftGroup
              ColumnLayout {
                Widgets.Window {
                  id: window
                  Layout.alignment: Qt.AlignHCenter
                }
                Widgets.Media {
                  id: media
                  visible: modelData.name === "DP-1"
                  Layout.alignment: Qt.AlignHCenter
                }
              }
            }
          }

          // Left-Center/Top-Center group
          Loader {
            id: leftCenterGroup
            sourceComponent: Settings.verticalBar ? verticalLeftCenterGroup : horizontalLeftCenterGroup

            anchors {
              right: Settings.verticalBar ? undefined : workspaces.left
              bottom: Settings.verticalBar ? workspaces.top : undefined
              horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
              rightMargin: Settings.verticalBar ? 0 : Settings.screenMargin
              bottomMargin: Settings.verticalBar ? Settings.screenMargin : 0
            }

            Component {
              id: horizontalLeftCenterGroup
              RowLayout {
                Widgets.Time {
                  id: time
                }
                Widgets.WorkspaceIndicator {
                  id: workspaceIndicator
                  screen: panel.screen
                }
              }
            }

            Component {
              id: verticalLeftCenterGroup
              ColumnLayout {
                Widgets.Time {
                  id: time
                  Layout.alignment: Qt.AlignHCenter
                }
                // Widgets.WorkspaceIndicator {
                //   id: workspaceIndicator
                //   screen: panel.screen
                //   Layout.alignment: Qt.AlignHCenter
                // }
              }
            }
          }

          // Right-Center/Bottom-Center group
          Loader {
            id: rightCenterGroup
            sourceComponent: Settings.verticalBar ? verticalRightCenterGroup : horizontalRightCenterGroup

            anchors {
              left: Settings.verticalBar ? undefined : workspaces.right
              top: Settings.verticalBar ? workspaces.bottom : undefined
              horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
              leftMargin: Settings.verticalBar ? 0 : Settings.screenMargin
              topMargin: Settings.verticalBar ? Settings.screenMargin : 0
            }

            Component {
              id: horizontalRightCenterGroup
              RowLayout {
                spacing: Settings.widgetSpacing
                Widgets.SystemMonitor {
                  id: systemMonitor
                  visible: modelData.name === "DP-1"
                }
              }
            }

            Component {
              id: verticalRightCenterGroup
              ColumnLayout {
                spacing: Settings.widgetSpacing
                // Widgets.SystemMonitor {
                //   id: systemMonitor
                //   visible: modelData.name === "DP-1"
                //   Layout.alignment: Qt.AlignHCenter
                // }
                Widgets.WorkspaceIndicator {
                  id: workspaceIndicator
                  screen: panel.screen
                  Layout.alignment: Qt.AlignHCenter
                }
              }
            }
          }

          // Bottom/Right group
          Loader {
            id: rightGroup
            sourceComponent: Settings.verticalBar ? verticalRightGroup : horizontalRightGroup

            anchors {
              right: Settings.verticalBar ? undefined : parent.right
              bottom: Settings.verticalBar ? parent.bottom : undefined
              horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
              rightMargin: Settings.verticalBar ? 0 : Settings.screenMargin
              bottomMargin: Settings.verticalBar ? Settings.screenMargin : 0
            }

            Component {
              id: horizontalRightGroup
              RowLayout {
                spacing: Settings.widgetSpacing
                Widgets.Tailscale {
                  id: tailscale
                }
                Widgets.Network {
                  id: network
                }
                Widgets.SystemTray {
                  id: tray
                  visible: modelData.name === "DP-1"
                  orientation: Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
                  Layout.alignment: Qt.AlignHCenter  // for vertical mode
                }
                Widgets.Notifications {
                  id: notifications
                }
                Widgets.Logo {
                  id: logo
                }
              }
            }

            Component {
              id: verticalRightGroup
              ColumnLayout {
                spacing: Settings.widgetSpacing
                Widgets.Tailscale {
                  id: tailscale
                  Layout.alignment: Qt.AlignHCenter
                }
                Widgets.Network {
                  id: network
                  Layout.alignment: Qt.AlignHCenter
                }
                Widgets.SystemTray {
                  id: tray
                  visible: modelData.name === "DP-1"
                  Layout.alignment: Qt.AlignHCenter
                }
                Widgets.Notifications {
                  id: notifications
                  Layout.alignment: Qt.AlignHCenter
                }
                Widgets.Logo {
                  id: logo
                  Layout.alignment: Qt.AlignHCenter
                }
              }
            }
          }
        }
      }
    }
  }
}
