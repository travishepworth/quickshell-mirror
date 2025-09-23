pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.services

Item {
  id: root

  // TODO: less spaghetti
  property var windowData: null
  property var windowList: HyprlandData.windowList
  property var toplevel: getToplevelFromAddress(windowData?.address)
  property real overviewScale: 0.15
  property int gridSize: 5
  property real workspaceWidth: 0
  property real workspaceHeight: 0
  property real workspaceSpacing: 0
  property real offsetX: 0
  property real offsetY: 0

  property var iconPath: findIconPath()
  property string windowTitle: windowData?.title ?? windowData?.class ?? "Unknown"

  property var matchedToplevel: toplevel

  function getToplevelFromAddress(address) {
    for (let toplevel of Hyprland.toplevels.values) {
      let formattedAddress = "0x" + toplevel.address;
      if (formattedAddress === address) {
        return toplevel.wayland;
      }
    }
  }

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

  signal windowDropped(int targetWorkspace)
  signal windowClicked
  signal windowClosed
  signal windowResized

  // Calculate scaled position within workspace with null checks
  property real scaledX: ((windowData?.at[0] ?? 0) * overviewScale)
  property real scaledY: ((windowData?.at[1] ?? 0) * overviewScale)
  property real scaledWidth: Math.max((windowData?.size[0] ?? 100) * overviewScale, 20)
  property real scaledHeight: Math.max((windowData?.size[1] ?? 100) * overviewScale, 20)

  // Constrain to workspace bounds
  property real constrainedX: Math.min(Math.max(scaledX, 0), Math.max(workspaceWidth - scaledWidth, 0))
  property real constrainedY: Math.min(Math.max(scaledY, 0), Math.max(workspaceHeight - scaledHeight, 0))

  x: offsetX + constrainedX
  y: offsetY + constrainedY
  implicitWidth: scaledWidth
  implicitHeight: scaledHeight

  visible: windowData !== null && windowData !== undefined
  z: dragHandler.active ? 1000 : ((windowData?.floating ?? false) ? 100 : 10)

  Behavior on x {
    enabled: !dragHandler.active
    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  Behavior on y {
    enabled: !dragHandler.active
    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    id: windowRect
    anchors.fill: parent

    color: "#504945" // Gruvbox bg2
    radius: 4 * overviewScale
    border.width: 2
    border.color: (windowData?.focusHistoryID ?? 999) === 0 ? "#d79921" : "#665c54" // Gruvbox yellow/bg3
    opacity: (windowData?.floating ?? false) ? 0.95 : 0.9
    clip: true

    ScreencopyView {
      id: screencopy
      anchors.fill: parent
      anchors.margins: windowRect.border.width

      captureSource: matchedToplevel

      visible: captureSource !== null
    }

    Column {
      anchors.centerIn: parent
      spacing: 4
      visible: true

      Image {
        id: windowIcon
        source: root.iconPath
        width: Math.min(parent.parent.width * 0.4, 50)
        height: width
        fillMode: Image.PreserveAspectFit
        smooth: true
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: root.windowTitle
        font.family: "VictorMono Nerd Font"
        font.pixelSize: 10
        color: "#ebdbb2" // Gruvbox fg
        opacity: 0.7
        width: windowRect.width - 8
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Rectangle {
      visible: (windowData?.xwayland ?? false) && !screencopy.visible
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: 4
      width: 16
      height: 16
      radius: 8
      color: "#fabd2f" // Gruvbox yellow bright
      opacity: 0.5

      Text {
        anchors.centerIn: parent
        text: "X"
        font.family: "VictorMono Nerd Font"
        font.pixelSize: 10
        font.bold: true
        color: "#282828" // Gruvbox bg
      }
    }
  }

  // Mouse interaction
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: dragHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        root.windowClicked();
      } else if (mouse.button === Qt.MiddleButton) {
        root.windowClosed();
      } else if (mouse.button === Qt.RightButton) {
        root.windowResized();
      }
    }

    onEntered: {
      windowRect.opacity = 1;
      windowRect.border.color = "#d79921"; // Gruvbox yellow
    }

    onExited: {
      windowRect.opacity = (windowData?.floating ?? false) ? 0.95 : 0.9;
      windowRect.border.color = (windowData?.focusHistoryID ?? 999) === 0 ? "#d79921" : "#665c54"; // Gruvbox yellow/bg3
    }
  }

  DragHandler {
    id: dragHandler
    target: root

    onActiveChanged: {
      if (!active) {
        // Calculate which workspace we're over
        let totalX = root.x + (root.width / 2);
        let totalY = root.y + (root.height / 2);

        let col = Math.floor(totalX / (workspaceWidth + workspaceSpacing));
        let row = Math.floor(totalY / (workspaceHeight + workspaceSpacing));

        col = Math.max(0, Math.min(col, gridSize - 1));
        row = Math.max(0, Math.min(row, gridSize - 1));

        let targetWorkspace = row * gridSize + col + 1;

        if (windowData?.workspace?.id && targetWorkspace !== windowData.workspace.id) {
          root.windowDropped(targetWorkspace);
        } else {
          // Snap back to original position
          root.x = Qt.binding(() => root.offsetX + root.constrainedX);
          root.y = Qt.binding(() => root.offsetY + root.constrainedY);
        }
      }
    }
  }

  // Visual feedback during drag
  states: [
    State {
      name: "dragging"
      when: dragHandler.active
      PropertyChanges {
        target: windowRect
        scale: 1.05
        opacity: 0.8
      }
    }
  ]

  transitions: Transition {
    NumberAnimation {
      properties: "scale,opacity"
      duration: 150
      easing.type: Easing.OutCubic
    }
  }
}
