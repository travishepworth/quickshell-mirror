import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "./widgets" as Widgets
import "root:/" as App

import qs.services

Scope {
  property int barHeight: App.Settings.barHeight
  property int barWidth: App.Settings.verticalBar ? App.Settings.barHeight : undefined
  property string backgroundColor: Colors.bg
  property string foregroundColor: Colors.fg
  
  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        id: panel
        required property var modelData
        screen: modelData
        
        anchors {
          top: App.Settings.verticalBar ? true : (modelData.name === "DP-1")
          bottom: App.Settings.verticalBar ? true : (modelData.name === "DP-2")
          left: App.Settings.verticalBar ? !App.Settings.rightVerticalBar : true
          right: App.Settings.verticalBar ? App.Settings.rightVerticalBar : true
        }
        
        implicitHeight: App.Settings.verticalBar ? undefined : barHeight
        implicitWidth: App.Settings.verticalBar ? barWidth : undefined
        
        Rectangle {
          anchors.fill: parent
          color: backgroundColor
          
          // Workspaces centered
          Widgets.Workspaces {
            id: workspaces
            screen: panel.screen
            anchors.centerIn: parent
            orientation: App.Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
          }
          
          // Top/Left group
          Loader {
            id: leftGroup
            sourceComponent: App.Settings.verticalBar ? verticalLeftGroup : horizontalLeftGroup
            
            anchors {
              left: App.Settings.verticalBar ? undefined : parent.left
              top: App.Settings.verticalBar ? parent.top : undefined
              horizontalCenter: App.Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: App.Settings.verticalBar ? undefined : parent.verticalCenter
              leftMargin: App.Settings.verticalBar ? 0 : App.Settings.screenMargin
              topMargin: App.Settings.verticalBar ? App.Settings.screenMargin : 0
            }
            
            Component {
              id: horizontalLeftGroup
              RowLayout {
                Widgets.Window {
                  id: window
                  orientation: App.Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
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
            sourceComponent: App.Settings.verticalBar ? verticalLeftCenterGroup : horizontalLeftCenterGroup
            
            anchors {
              right: App.Settings.verticalBar ? undefined : workspaces.left
              bottom: App.Settings.verticalBar ? workspaces.top : undefined
              horizontalCenter: App.Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: App.Settings.verticalBar ? undefined : parent.verticalCenter
              rightMargin: App.Settings.verticalBar ? 0 : App.Settings.screenMargin
              bottomMargin: App.Settings.verticalBar ? App.Settings.screenMargin : 0
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
            sourceComponent: App.Settings.verticalBar ? verticalRightCenterGroup : horizontalRightCenterGroup
            
            anchors {
              left: App.Settings.verticalBar ? undefined : workspaces.right
              top: App.Settings.verticalBar ? workspaces.bottom : undefined
              horizontalCenter: App.Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: App.Settings.verticalBar ? undefined : parent.verticalCenter
              leftMargin: App.Settings.verticalBar ? 0 : App.Settings.screenMargin
              topMargin: App.Settings.verticalBar ? App.Settings.screenMargin : 0
            }
            
            Component {
              id: horizontalRightCenterGroup
              RowLayout {
                spacing: App.Settings.widgetSpacing
                Widgets.SystemMonitor {
                  id: systemMonitor
                  visible: modelData.name === "DP-1"
                }
              }
            }
            
            Component {
              id: verticalRightCenterGroup
              ColumnLayout {
                spacing: App.Settings.widgetSpacing
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
            sourceComponent: App.Settings.verticalBar ? verticalRightGroup : horizontalRightGroup
            
            anchors {
              right: App.Settings.verticalBar ? undefined : parent.right
              bottom: App.Settings.verticalBar ? parent.bottom : undefined
              horizontalCenter: App.Settings.verticalBar ? parent.horizontalCenter : undefined
              verticalCenter: App.Settings.verticalBar ? undefined : parent.verticalCenter
              rightMargin: App.Settings.verticalBar ? 0 : App.Settings.screenMargin
              bottomMargin: App.Settings.verticalBar ? App.Settings.screenMargin : 0
            }
            
            Component {
              id: horizontalRightGroup
              RowLayout {
                spacing: App.Settings.widgetSpacing
                Widgets.Tailscale {
                  id: tailscale
                }
                Widgets.Network {
                  id: network
                }
                Widgets.SystemTray {
                  id: tray
                  visible: modelData.name === "DP-1"
                  orientation: App.Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
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
                spacing: App.Settings.widgetSpacing
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
