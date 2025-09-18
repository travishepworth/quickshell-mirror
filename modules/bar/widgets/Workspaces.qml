import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.services

Item {
  id: root
  required property var screen
  property var popouts: null

  // Orientation support
  property int orientation: Settings.orientation
  property bool isVertical: orientation === Qt.Vertical

  property color activeColor: Colors.accent
  property color inactiveColor: Colors.outline
  property color emptyColor: Colors.bgAlt

  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
  readonly property HyprlandWorkspace focusedWorkspace: Hyprland.workspaces.focused

  // Dynamic group calculation based on orientation
  readonly property int groupBase: {
    const id = monitor.activeWorkspace ? monitor.activeWorkspace.id : 1;
    if (isVertical) {
      // For vertical: show the column that contains the active workspace
      return ((id - 1) % 5) + 1;
    } else {
      // For horizontal: groups are 1-5 | 6-10 | 11-15 | etc
      return Math.floor((id - 1) / 5) * 5 + 1;
    }
  }

  readonly property int groupSize: 5

  // Size for the clipped view in the bar
  implicitWidth: isVertical ? Settings.widgetHeight : (groupSize * Settings.widgetHeight + (groupSize - 1) * 6)
  implicitHeight: isVertical ? (groupSize * Settings.widgetHeight + (groupSize - 1) * 6) : Settings.widgetHeight

  function wsById(id) {
    const arr = Hyprland.workspaces.values;
    for (let i = 0; i < arr.length; i++) {
      if (arr[i].id === id)
        return arr[i];
    }
    return null;
  }

  // Main clipped container that shows only the relevant column/row
  Item {
    id: clippedContainer
    anchors.fill: parent
    clip: true  // Clip the full grid to show only what we need

    // Full 5x5 grid, but positioned so only the relevant part shows
    GridLayout {
      id: mainGrid
      columns: 5
      rows: 5
      columnSpacing: 6
      rowSpacing: 6

      // Position the grid so the right column/row is visible
      x: {
        if (isVertical) {
          // Show only the specific column
          const columnIndex = groupBase - 1;  // 0-4
          return -(columnIndex * (Settings.widgetHeight + 6));
        } else {
          return 0;  // Show all columns for horizontal
        }
      }

      y: {
        if (!isVertical) {
          // Show only the specific row
          const rowIndex = Math.floor((groupBase - 1) / 5);  // 0-4
          return -(rowIndex * (Settings.widgetHeight + 6));
        } else {
          return 0;  // Show all rows for vertical
        }
      }

      Repeater {
        model: 25
        delegate: workspaceDelegate
      }
    }
  }

  // Mouse area for hover detection
  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true

    onEntered: {
      if (root.popouts) {
        console.log("Hover enter - show workspace grid popout");
        showTimer.restart();
      }
    }

    onExited: {
      showTimer.stop();
      // if (Popouts.WorkspaceGridPopout.shown) {
      //   hideTimer.restart();
      // }
    }
  }

  // Timer to show popout after hover
  Timer {
    id: showTimer
    interval: 200
    onTriggered: {
      if (root.popouts) {
        console.log("Show workspace grid popout");
        console.log("Monitor:", root.monitor);
        console.log("Active WS:", root.monitor?.activeWorkspace);
        // console.log("Window:", root.Window.window);
        console.log("QsWindow:", QsWindow);
        root.popouts.showWorkspaceGrid(root, {
          monitor: root.monitor,
          activeId: root.monitor?.activeWorkspace?.id ?? 1,
          window: QsWindow.window
        });
      }
    }
  }

  // Timer to hide popout after mouse leaves
  // Timer {
  //   id: hideTimer
  //   interval: 300
  //   onTriggered: {
  //     Popouts.Wrapper.hidePopout(Popouts.WorkspaceGridPopout, hoverArea);
  //   }
  // }

  // Workspace delegate component used in the bar grid
  Component {
    id: workspaceDelegate
    Rectangle {
      readonly property int realId: index + 1
      readonly property HyprlandWorkspace ws: root.wsById(realId)
      readonly property bool isActive: monitor.activeWorkspace && monitor.activeWorkspace.id === realId
      readonly property bool hasWindows: ws && ws.toplevels && ws.toplevels.values.length > 0

      Layout.preferredWidth: Settings.widgetHeight
      Layout.preferredHeight: Settings.widgetHeight

      radius: Settings.borderRadius
      color: isActive ? root.activeColor : hasWindows ? root.inactiveColor : root.emptyColor

      MouseArea {
        anchors.fill: parent
        onClicked: {
          Hyprland.dispatch(`workspace ${realId}`);
        }
        hoverEnabled: true
        onEntered: {
          parent.opacity = 0.8;
        }
        onExited: {
          parent.opacity = 1.0;
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: 50
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
