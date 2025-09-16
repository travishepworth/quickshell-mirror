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
  readonly property int row: 5
  readonly property int column: 5
  property var addressClassMap: populateAddressClassMap()
  // function populateAddressClassMap() {
  //   console.log("Populating address-class map");
  //   let addressClassMap = {};
  //
  //   try {
  //     const process = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root);
  //     process.command = ["hyprctl", "-j", "clients"];
  //     process.running = true;
  //
  //     while (process.running) {}
  //
  //     if (process.stdout) {
  //       const clients = JSON.parse(process.stdout);
  //       for (let client of clients) {
  //         if (client.address) {
  //           addressClassMap[client.address] = client.class || client.initial_class || "";
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     console.log("Error populating address map:", e);
  //   }
  //
  //   return addressClassMap;
  // }
  //
  // function getClassFromAddress(addressClassMap, address) {
  //   return addressClassMap[address] || "";
  // }

  Repeater {
    model: root.groupSize
    delegate: Rectangle {
      readonly property int realId: root.groupBase + index

      readonly property HyprlandWorkspace ws: wsById(realId)

      readonly property bool isActive: monitor.activeWorkspace && monitor.activeWorkspace.id === realId
      readonly property bool exists: ws !== null
      readonly property bool hasWindows: ws && ws.toplevels && ws.toplevels.values.length > 0

      function findIconPath(appClass) {
        if (!appClass || appClass === "")
          return "";

        // Convert app class to lowercase for icon lookup
        // Also handle cases where the class might have a dot notation (e.g., org.mozilla.firefox)
        let iconName = appClass.toLowerCase();

        // Handle common transformations
        if (iconName.includes(".")) {
          // For names like org.mozilla.firefox, try the last part
          const parts = iconName.split(".");
          iconName = parts[parts.length - 1];
        }

        // Common icon theme paths to search - return the first one that might exist
        const iconPaths = [`/usr/share/icons/hicolor/256x256/apps/${iconName}.png`, `/usr/share/icons/hicolor/128x128/apps/${iconName}.png`, `/usr/share/icons/hicolor/64x64/apps/${iconName}.png`, `/usr/share/icons/hicolor/48x48/apps/${iconName}.png`, `/usr/share/icons/hicolor/scalable/apps/${iconName}.svg`, `/usr/share/pixmaps/${iconName}.png`, `/usr/share/pixmaps/${iconName}.svg`, `/usr/share/icons/Papirus/64x64/apps/${iconName}.svg`, `/usr/share/icons/Papirus/48x48/apps/${iconName}.svg`, `/usr/share/icons/breeze/apps/64/${iconName}.svg`, `/usr/share/icons/breeze/apps/48/${iconName}.svg`, `/usr/share/icons/Adwaita/256x256/apps/${iconName}.png`, `/usr/share/icons/Adwaita/48x48/apps/${iconName}.png`,];

        // Return the most likely path (you may want to implement actual file checking)
        return iconPaths[0];
      }

      // Fixed largestWindow property
      readonly property var largestWindow: {
        if (!hasWindows || !ws)
          return null;

        let largest = null;
        let maxSize = 0;

        // Iterate through the workspace's toplevels directly
        for (let client of ws.toplevels.values) {
          return client;
          // Calculate window size
          let width = client.size?.width || client.width || 0;
          let height = client.size?.height || client.height || 0;
          let size = width * height;

          if (size > maxSize) {
            maxSize = size;
            largest = client;
          }
        }

        // If no toplevels in ws.toplevels, check all Hyprland.toplevels as fallback
        if (!largest) {
          for (let client of Hyprland.toplevels.values) {
            // Check if client is on this workspace
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

      // Computed icon path based on largest window
      readonly property string iconPath: {
        if (!largestWindow)
          return "";
        console.log("has largest window for WS " + realId + ": ", largestWindow.handle);

        // if (appClass) {
        //   console.log("WS " + realId + " largest window app: " + appClass);
        // }

        return findIconPath(appClass);
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
          console.log("Largest window properties:", "\n  address:", largestWindow.address, "\n  handle:", largestWindow.handle, "\n  wayland:", largestWindow.wayland, "\n  lastIpcObject:", largestWindow.lastIpcObject, "\n  title:", largestWindow.title);
        }
      }

      width: App.Settings.widgetHeight
      height: App.Settings.widgetHeight
      radius: App.Settings.borderRadius
      color: isActive ? root.activeColor : hasWindows ? root.inactiveColor : root.emptyColor
      border.width: 0
      border.color: Services.Colors.accent

      Image {
        id: wsWindowIcon
        anchors.centerIn: parent
        // source: parent.iconPath
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
