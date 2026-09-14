pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import qs.services
import qs.config
import qs.components.methods
import qs.components.stolen

Item {
  id: root

  required property var wrapper
  property string currentName: "workspace-grid"

  property var monitor: wrapper.currentData?.monitor
  property int workspaceBase: wrapper.currentData?.workspaceBase ?? 1
  property int activeWorkspaceId: wrapper.currentData?.activeId ?? 1
  property int currentColumn: ((activeWorkspaceId - workspaceBase) % 5)
  readonly property int cell: (Widget.height && Widget.height > 0) ? Widget.height : 28

  // The bar widget that opened us — a live item reference, not a snapshot —
  // so we can keep checking whether the anchor itself is still hovered,
  // and so we can clear its popoutOpen flag when we actually close.
  readonly property var anchorItem: wrapper.currentData?.anchorItem ?? null
  readonly property bool anchorHovered: root.anchorItem?.hovered ?? false

  // Stay open as long as EITHER the popout or the widget that spawned it is
  // hovered. This stops the dismiss countdown from starting the instant the
  // popout appears, even though the mouse is usually still over the widget
  // (which is what triggered the open in the first place).
  readonly property bool keepAlive: hoverHandler.hovered || root.anchorHovered

  function updateDismissTimer() {
    if (root.keepAlive) {
      dismissTimer.stop();
    } else {
      dismissTimer.restart();
    }
  }

  // Central place to actually close: clears the widget's popoutOpen flag
  // (so hovering the widget again is allowed to open a fresh popout) before
  // asking the wrapper to tear us down.
  function dismiss() {
    if (root.anchorItem) {
      root.anchorItem.popoutOpen = false;
    }
    root.wrapper.closePopout();
  }

  onKeepAliveChanged: updateDismissTimer()

  // Safety net: however this popout ends up destroyed (dismiss(), the
  // panel system closing it some other way, etc.) make sure the widget's
  // flag never gets stuck true.
  Component.onDestruction: {
    if (root.anchorItem) {
      root.anchorItem.popoutOpen = false;
    }
  }

  Component.onCompleted: {
    console.log("WorkspacePopout initialized for monitor", monitor?.name ?? "unknown");
    console.log("Workspace range:", workspaceBase, "to", workspaceBase + 24);
    // Don't blindly start the countdown here — only arm it if neither the
    // popout nor its anchor widget is currently hovered.
    updateDismissTimer();
  }

  implicitWidth: (5 * cell + 6 * 6) + 20 // wtf is this
  implicitHeight: (5 * cell + 6 * 6) + 20
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    id: content
    anchors.centerIn: parent
    visible: true

    // 5 columns × widget height + spacing
    width: 5 * Widget.height + 4 * 6
    height: 5 * Widget.height + 4 * 6

    color: Theme.background
    border.color: Theme.backgroundAlt
    border.width: 0
    radius: Appearance.borderRadius + 2

    // Hover detection only. Whether that translates into "stay open" is
    // decided by root.keepAlive above (combined with the anchor's hover),
    // and root.updateDismissTimer() reacts to it.
    HoverHandler {
      id: hoverHandler
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
          required property var index

          readonly property int wsId: root.workspaceBase + index
          readonly property var workspace: root.getWorkspace(wsId)
          readonly property bool isActive: root.monitor?.activeWorkspace?.id === wsId
          readonly property bool hasWindows: workspace?.toplevels?.values?.length > 0
          // readonly property bool isCurrentColumn: (wsId - 1) % 5 === root.currentColumn
          readonly property bool isCurrentColumn: index % 5 === root.currentColumn
          readonly property bool showIcons: Appearance.workspacePopoutIcons
          property bool hovered: false

          Layout.preferredWidth: Widget.height
          Layout.preferredHeight: Widget.height

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

          radius: Appearance.borderRadius
          // property color baseColor: isActive ? Theme.accent : hasWindows ? Colors.outline : Theme.backgroundAlt

          color: isActive ? Theme.accent : hovered ? Theme.accentAlt : hasWindows ? Theme.border : Theme.backgroundAlt

          // Highlight the column shown in bar
          border.width: 0
          border.color: Theme.backgroundAlt
          // border.color: hovered ? Theme.accentAlt : Theme.backgroundAlt
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
            visible: Appearance.workspacePopoutIcons
          }

          Text {
            anchors.centerIn: parent
            text: parent.wsId
            color: parent.isActive ? Theme.background : Theme.backgroundAlt
            font.pixelSize: 11
            font.family: Appearance.fontFamily
            visible: false
          }

          MouseArea {
            id: boxMouseArea
            anchors.fill: parent
            hoverEnabled: true

            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              console.log("Click ws", parent.wsId);
              WorkspaceUtils.focusWorkspace(parent.wsId);
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
    id: dismissTimer
    interval: 500
    onTriggered: root.dismiss()
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
