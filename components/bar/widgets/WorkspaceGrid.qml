import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.services
import qs.config
import qs.components.hosts.popout

// A 5x5 grid of workspaces per monitor (25 ids each): the bar shows the
// active row (horizontal bar) or column (vertical bar), the popout the grid.
// The plain 1..N switcher is Workspaces.
Item {
  id: root
  property var screen
  property var popouts
  property var panel
  property var barConfig
  property var properties

  property bool isVertical: barConfig.vertical

  readonly property color activeColor: Theme.resolveColor(properties.activeColor)
  readonly property color inactiveColor: Theme.resolveColor(properties.occupiedColor)
  readonly property color emptyColor: Theme.resolveColor(properties.emptyColor)
  readonly property color iconColor: Theme.resolveColor(properties.iconColor)

  property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

  // First id of this monitor's 25-workspace range
  readonly property int workspaceBase: HyprlandManager.gridBase(root.monitor)

  // Get workspaces for THIS monitor only
  readonly property var monitorWorkspaces: {
    if (!monitor)
      return [];

    const all = Hyprland.workspaces.values;
    const filtered = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].monitor && all[i].monitor.id === monitor.id) {
        filtered.push(all[i].id);
      }
    }
    filtered.sort((a, b) => a - b);
    return filtered;
  }

  // Dynamic group calculation based on orientation
  readonly property int groupBase: {
    if (!monitor || !monitor.activeWorkspace)
      return 1;

    const id = monitor.activeWorkspace.id;
    const relativeId = id - workspaceBase + 1;

    if (isVertical) {
      return ((relativeId - 1) % 5) + 1;
    } else {
      return Math.floor((relativeId - 1) / 5) * 5 + 1;
    }
  }

  readonly property int groupSize: 5
  readonly property int priority: 10

  implicitWidth: isVertical ? root.barConfig.widgetSize : (groupSize * root.barConfig.widgetSize + (groupSize - 1) * 6)
  implicitHeight: isVertical ? (groupSize * root.barConfig.widgetSize + (groupSize - 1) * 6) : root.barConfig.widgetSize

  function wsById(id) {
    const arr = Hyprland.workspaces.values;
    for (let i = 0; i < arr.length; i++) {
      if (arr[i].id === id)
        return arr[i];
    }
    return null;
  }

  function formatIconVertical(relativeIndex) {
    const col = (relativeIndex - 1) % 5;
    switch (col) {
    case 0:
      return "";
    case 1:
      return "";
    case 2:
      return "";
    case 3:
      return "";
    case 4:
      return "";
    default:
      return "";
    }
  }

  function formatIconHorizontal(relativeIndex) {
    const row = Math.floor((relativeIndex - 1) / 5);
    switch (row) {
    case 0:
      return "";
    case 1:
      return "";
    case 2:
      return "";
    case 3:
      return "";
    case 4:
      return "";
    default:
      return "";
    }
  }

  Item {
    id: clippedContainer
    anchors.fill: parent
    clip: true

    GridLayout {
      id: mainGrid
      columns: 5
      rows: 5
      columnSpacing: 6
      rowSpacing: 6

      x: {
        if (isVertical) {
          const columnIndex = groupBase - 1;
          return -(columnIndex * (root.barConfig.widgetSize + 6));
        }
        return 0;
      }

      y: {
        if (!isVertical) {
          const rowIndex = Math.floor((groupBase - 1) / 5);
          return -(rowIndex * (root.barConfig.widgetSize + 6));
        }
        return 0;
      }

      Repeater {
        model: 25
        delegate: workspaceDelegate
      }
    }
  }

  PopoutAnchor {
    id: anchor
    popouts: root.popouts
    panel: root.panel
    popoutName: "WorkspaceGrid"
    active: root.properties.showPopout
    extraData: ({
        monitor: root.monitor,
        workspaceBase: root.workspaceBase,
        activeId: root.monitor?.activeWorkspace?.id ?? root.workspaceBase,
        cellSize: root.barConfig.widgetSize
      })
  }

  Component {
    id: workspaceDelegate
    Rectangle {
      readonly property int relativeIndex: index + 1
      readonly property int realId: root.workspaceBase + index
      readonly property HyprlandWorkspace ws: root.wsById(realId)
      readonly property bool isActive: root.monitor && root.monitor.activeWorkspace && root.monitor.activeWorkspace.id === realId
      readonly property bool hasWindows: ws && ws.toplevels && ws.toplevels.values.length > 0

      Layout.preferredWidth: root.barConfig.widgetSize
      Layout.preferredHeight: root.barConfig.widgetSize

      radius: Appearance.borderRadius
      color: isActive ? root.activeColor : hasWindows ? root.inactiveColor : root.emptyColor

      Text {
        anchors.centerIn: parent
        text: root.isVertical ? root.formatIconVertical(relativeIndex) : root.formatIconHorizontal(relativeIndex)
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize * 1.2
        visible: isActive && root.properties.showActiveIcon
        color: root.iconColor
      }

      Behavior on color {
        ColorAnimation {
          duration: Appearance.animFast
        }
      }
      Behavior on opacity {
        NumberAnimation {
          duration: Appearance.animNormal
        }
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.properties.clickToSwitch
        cursorShape: Qt.PointingHandCursor
        onClicked: HyprlandManager.gotoWorkspace(realId)
      }
    }
  }
}
