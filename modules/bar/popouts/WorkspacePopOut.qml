import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.services

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
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    visible: true

    // 5 columns × widget height + spacing
    width: 5 * Settings.widgetHeight + 4 * 6
    height: 5 * Settings.widgetHeight + 4 * 6

    color: Colors.bg
    border.color: Colors.outline
    border.width: 1
    radius: Settings.borderRadius + 2

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

          Layout.preferredWidth: Settings.widgetHeight
          Layout.preferredHeight: Settings.widgetHeight

          radius: Settings.borderRadius
          color: isActive ? Colors.accent : hasWindows ? Colors.outline : Colors.bgAlt

          // Highlight the column shown in bar
          border.width: isCurrentColumn ? 2 : 0
          border.color: Colors.accent
          opacity: isCurrentColumn ? 1.0 : 0.85

          // Optional: Show workspace number
          Text {
            anchors.centerIn: parent
            text: parent.wsId
            color: parent.isActive ? Colors.bg : Colors.surface
            font.pixelSize: 11
            font.family: Settings.fontFamily
            visible: Settings.showWorkspaceNumbers ?? false
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
              Hyprland.dispatch(`workspace ${parent.wsId}`);
              root.wrapper.hasCurrent = false;  // Close the popout
            }

            onEntered: {
              parent.scale = 1.05;
              cursorShape = Qt.PointingHandCursor;
            }

            onExited: {
              parent.scale = 1.0;
              cursorShape = Qt.ArrowCursor;
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

  // Keep popout open while hovering over it
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    propagateComposedEvents: true

    onExited: {
      // Only close if mouse truly left the popout area
      if (!containsMouse) {
        exitTimer.restart();
      }
    }

    onEntered: {
      exitTimer.stop();
    }
  }

  Timer {
    id: exitTimer
    interval: 300
    onTriggered: {
      root.wrapper.hasCurrent = false;
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
