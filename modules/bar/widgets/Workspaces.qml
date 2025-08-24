import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/services" as Services
import "root:/" as App

RowLayout {
  id: root
  required property var screen

  property color activeColor: Services.Colors.accent
  property color inactiveColor: Services.Colors.outline
  property color emptyColor: Services.Colors.bgAlt

  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
  readonly property HyprlandWorkspace focusedWorkspace: Hyprland.workspaces.focused

  readonly property int groupBase: {
    const id = monitor.activeWorkspace ? monitor.activeWorkspace.id : 1;
    return Math.floor((id - 1) / 5) * 5 + 1;
  }
  readonly property int groupSize: 5

  Repeater {
    model: root.groupSize
    delegate: Rectangle {
      readonly property int realId: root.groupBase + index
      readonly property int fakeId: (function () {
        if (0 <= realId <= 5) return realId + 5;
        if (6 <= realId <= 10) return realId;
        if (11 <= realId <= 15) return realId - 5;
      })()

      readonly property HyprlandWorkspace ws: wsById(realId)

      readonly property bool isActive: monitor.activeWorkspace && monitor.activeWorkspace.id === realId
      readonly property bool exists: ws !== null
      readonly property bool hasWindows: ws && ws.toplevels && ws.toplevels.values.length > 0

      function wsById(id) {
        const arr = Hyprland.workspaces.values;
        for (let i = 0; i < arr.length; i++) {
          if (arr[i].id === id)
            return arr[i];
        }
        return null;
      }

      width: App.Settings.widgetHeight
      height: App.Settings.widgetHeight
      radius: App.Settings.borderRadius
      color: isActive ? root.activeColor : hasWindows ? root.inactiveColor : root.emptyColor
      border.width: 0
      border.color: Services.Colors.accent

      Text {
        id: wsIcon
        anchors.centerIn: parent

        color: isActive ? Services.Colors.bg : Services.Colors.fg
        font.pixelSize: 12
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          Hyprland.dispatch(`workspace ${realId}`); // create/activate it
        }
        hoverEnabled: true
        onEntered: parent.opacity = 0.8
        onExited: parent.opacity = 1.0
      }

      Behavior on color {
        ColorAnimation {
          duration: 200
        }
      }
    }
  }
}
