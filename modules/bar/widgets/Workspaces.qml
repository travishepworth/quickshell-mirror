import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/services" as Services
import "root:/" as App

import qs
import qs.services

Item {
  id: root
  required property var screen
  
  // Orientation support
  property int orientation: Settings.orientation  // Accept orientation from parent
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
      // If on workspace 1-5, show column 1 (1,6,11,16,21)
      // If on workspace 6-10, show column 2 (2,7,12,17,22), etc.
      return ((id - 1) % 5) + 1;
    } else {
      // For horizontal: groups are 1-5 | 6-10 | 11-15 | etc
      return Math.floor((id - 1) / 5) * 5 + 1;
    }
  }
  
  readonly property int groupSize: 5
  property var addressClassMap: populateAddressClassMap()
  
  // Dynamic dimensions
  implicitWidth: isVertical ? App.Settings.widgetHeight : (groupSize * App.Settings.widgetHeight + (groupSize - 1) * layout.spacing)
  implicitHeight: isVertical ? (groupSize * App.Settings.widgetHeight + (groupSize - 1) * layout.spacing) : App.Settings.widgetHeight

  Loader {
    id: layout
    anchors.centerIn: parent
    sourceComponent: isVertical ? columnComponent : rowComponent
    
    property int spacing: 4
    
    Component {
      id: rowComponent
      RowLayout {
        spacing: layout.spacing
        
        Repeater {
          model: root.groupSize
          delegate: workspaceDelegate
        }
      }
    }
    
    Component {
      id: columnComponent
      ColumnLayout {
        spacing: layout.spacing
        
        Repeater {
          model: root.groupSize
          delegate: workspaceDelegate
        }
      }
    }
  }
  
  Component {
    id: workspaceDelegate
    Rectangle {
      // Calculate the real workspace ID based on orientation
      readonly property int realId: {
        if (root.isVertical) {
          // Vertical: show column workspaces
          // groupBase gives us column number (1-5)
          // index gives us row position (0-4)
          // Formula: column + (row * 5)
          return root.groupBase + (index * 5);
        } else {
          // Horizontal: increment by 1 for each position (1,2,3,4,5)
          return root.groupBase + index;
        }
      }

      readonly property HyprlandWorkspace ws: wsById(realId)
      readonly property bool isActive: monitor.activeWorkspace && monitor.activeWorkspace.id === realId
      readonly property bool exists: ws !== null
      readonly property bool hasWindows: ws && ws.toplevels && ws.toplevels.values.length > 0

      // function findIconPath(appClass) {
      //   if (!appClass || appClass === "")
      //     return "";
      //
      //   let iconName = appClass.toLowerCase();
      //
      //   if (iconName.includes(".")) {
      //     const parts = iconName.split(".");
      //     iconName = parts[parts.length - 1];
      //   }
      //
      //   const iconPaths = [
      //     `/usr/share/icons/hicolor/256x256/apps/${iconName}.png`,
      //     `/usr/share/icons/hicolor/128x128/apps/${iconName}.png`,
      //     `/usr/share/icons/hicolor/64x64/apps/${iconName}.png`,
      //     `/usr/share/icons/hicolor/48x48/apps/${iconName}.png`,
      //     `/usr/share/icons/hicolor/scalable/apps/${iconName}.svg`,
      //     `/usr/share/pixmaps/${iconName}.png`,
      //     `/usr/share/pixmaps/${iconName}.svg`,
      //     `/usr/share/icons/Papirus/64x64/apps/${iconName}.svg`,
      //     `/usr/share/icons/Papirus/48x48/apps/${iconName}.svg`,
      //     `/usr/share/icons/breeze/apps/64/${iconName}.svg`,
      //     `/usr/share/icons/breeze/apps/48/${iconName}.svg`,
      //     `/usr/share/icons/Adwaita/256x256/apps/${iconName}.png`,
      //     `/usr/share/icons/Adwaita/48x48/apps/${iconName}.png`,
      //   ];
      //
      //   return iconPaths[0];
      // }

      readonly property var largestWindow: {
        if (!hasWindows || !ws)
          return null;

        let largest = null;
        let maxSize = 0;

        for (let client of ws.toplevels.values) {
          let width = client.size?.width || client.width || 0;
          let height = client.size?.height || client.height || 0;
          let size = width * height;

          if (size > maxSize) {
            maxSize = size;
            largest = client;
          }
        }

        if (!largest) {
          for (let client of Hyprland.toplevels.values) {
            if (client.workspace && client.workspace.id === realId) {
              let width = client.size?.width || client.width || 0;
              let height = client.size?.height || client.height || 0;
              let size = width * height;

              if (size > maxSize) {
                maxSize = size;
                largest = client;
              }
            }
          }
        }

        return largest;
      }

      readonly property string iconPath: {
        if (!largestWindow)
          return "";
        console.log("has largest window for WS " + realId + ": ", largestWindow.handle);
        return findIconPath(largestWindow.appClass);
      }

      function wsById(id) {
        const arr = Hyprland.workspaces.values;
        for (let i = 0; i < arr.length; i++) {
          if (arr[i].id === id)
            return arr[i];
        }
        return null;
      }

      function echoIconPath() {
        console.log("Icon Path for WS " + realId + ": " + iconPath);
        if (largestWindow) {
          console.log("Largest window: ", largestWindow);
          console.log("Largest window properties:", 
            "\n  address:", largestWindow.address,
            "\n  handle:", largestWindow.handle,
            "\n  wayland:", largestWindow.wayland,
            "\n  lastIpcObject:", largestWindow.lastIpcObject,
            "\n  title:", largestWindow.title);
        }
      }

      Layout.preferredWidth: App.Settings.widgetHeight
      Layout.preferredHeight: App.Settings.widgetHeight
      
      radius: App.Settings.borderRadius
      color: isActive ? root.activeColor : hasWindows ? root.inactiveColor : root.emptyColor
      border.width: 0
      border.color: Colors.accent

      // Optional workspace number label
      Text {
        anchors {
          top: parent.top
          right: parent.right
          margins: 2
        }
        text: parent.realId
        color: Colors.bg
        font.pixelSize: 8
        font.family: App.Settings.fontFamily
        visible: false  // Set to true if you want to see workspace numbers
      }

      Image {
        id: wsWindowIcon
        anchors.centerIn: parent
        source: parent.iconPath
        width: parent.width * 0.7
        height: parent.height * 0.7
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (ws) {
            Hyprland.dispatch(`workspace ${realId}`);
          }
          echoIconPath();
        }
        hoverEnabled: true
        onEntered: parent.opacity = 0.8
        onExited: parent.opacity = 1.0
      }

      Behavior on color {
        ColorAnimation {
          duration: 50
        }
      }
    }
  }
}
