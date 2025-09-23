import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.services
import qs.components.methods

Item {
  id: root

  required property var wrapper  // Reference to the popout wrapper
  property string currentName: "workspace-grid"

  // Data passed from the workspace widget
  property var monitor: wrapper.currentData?.monitor
  property int activeWorkspaceId: wrapper.currentData?.activeId ?? 1
  property int currentColumn: ((activeWorkspaceId - 1) % 5)
  readonly property int cell: (Settings.widgetHeight && Settings.widgetHeight > 0) ? Settings.widgetHeight : 28

  // Size of the expanded grid
  // implicitWidth: content.width + 20
  // implicitHeight: content.height + 20
  implicitWidth: (5 * cell + 4 * 6) + 20
  implicitHeight: (5 * cell + 4 * 6) + 20
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    id: content
    anchors.centerIn: parent
    visible: true

    // 5 columns × widget height + spacing
    width: 5 * Settings.widgetHeight + 4 * 6
    height: 5 * Settings.widgetHeight + 4 * 6

    color: Colors.bg
    border.color: Colors.surface
    border.width: 0
    radius: Settings.borderRadius + 2

    // TODO: Figure out how to not define this here
    HoverHandler {
      id: hoverHandler
      onHoveredChanged: {
        if (hovered) {
          exitTimer.stop();
        } else {
          exitTimer.restart();
        }
      }
    }

    GridLayout {
      anchors.centerIn: parent
      columns: 5
      rows: 5
      columnSpacing: 6
      rowSpacing: 6

      Repeater {
        model: 25

        Rectangle {
          id: wsCell

          readonly property int wsId: index + 1
          readonly property var workspace: root.getWorkspace(wsId)
          readonly property bool isActive: root.monitor?.activeWorkspace?.id === wsId
          readonly property bool hasWindows: workspace?.toplevels?.values?.length > 0
          readonly property bool isCurrentColumn: (wsId - 1) % 5 === root.currentColumn
          readonly property bool showIcons: Settings.workspacePopoutIcons
          property bool hovered: false

          Layout.preferredWidth: Settings.widgetHeight
          Layout.preferredHeight: Settings.widgetHeight

          property var iconPath: findIconPath()
          property var windowData: HyprlandData.biggestWindowForWorkspace(wsId)

          function findIconPath() {
            let baseIcon = Quickshell.iconPath(AppSearch.guessIcon(windowData?.class), "image-missing");
            // Check if icon is kitty, and check if it is running nvim, and use nvim icon if so
            if (baseIcon.includes("kitty")) {
              for (let win of HyprlandData.windowList) {
                if (win.class === "kitty" && windowData?.title.toLowerCase().includes("nvim")) {
                  return Quickshell.iconPath("nvim", "image-missing");
                }
              }
            }
            return baseIcon;
          }

          radius: Settings.borderRadius
          // property color baseColor: isActive ? Colors.accent : hasWindows ? Colors.outline : Colors.bgAlt

          color: isActive ? Colors.accent : hovered ? Colors.accent2 : hasWindows ? Colors.outline : Colors.bgAlt

          // Highlight the column shown in bar
          border.width: 0
          border.color: Colors.surface
          // border.color: hovered ? Colors.accent2 : Colors.surface
          opacity: isCurrentColumn ? 1.0 : 0.85

          transitions: Transition {
            ColorAnimation {
              duration: 100
            }
          }

          Image {
            id: windowIcon
            source: (parent.hasWindows && parent.iconPath) ? parent.iconPath : ""
            width: parent.width * 0.7
            height: parent.height * 0.7
            anchors.centerIn: parent
            visible: Settings.workspacePopoutIcons
          }

          Text {
            anchors.centerIn: parent
            text: parent.wsId
            color: parent.isActive ? Colors.bg : Colors.surface
            font.pixelSize: 11
            font.family: Settings.fontFamily
            visible: false
          }

          MouseArea {
            id: boxMouseArea
            anchors.fill: parent
            hoverEnabled: true

            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              console.log("Click ws", parent.wsId);
              WorkspaceUtils.gotoWorkspace(parent.wsId);
            }

            onContainsMouseChanged:
            // Handled by HoverHandler
            {}

            onEntered: {
              parent.hovered = true;
            }

            onExited: {
              parent.hovered = false;
            }
          }

          Behavior on scale {
            NumberAnimation {
              duration: 100
              easing.type: Easing.OutCubic
            }
          }

          Behavior on color {
            ColorAnimation {
              duration: 150
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: 150
            }
          }
        }
      }
    }
  }

  Timer {
    id: exitTimer
    interval: 40
    onTriggered: {
      root.wrapper.closePopout();
    }
  }

  function getWorkspace(id) {
    const arr = Hyprland.workspaces.values;
    for (let i = 0; i < arr.length; i++) {
      if (arr[i].id === id)
        return arr[i];
    }
    return null;
  }
}
