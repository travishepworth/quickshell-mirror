import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services

Item {
  id: root

  required property ShellScreen screen

  property string currentName: ""
  property var currentAnchor: null    // bar sub-item passed in
  property var currentData: null
  property bool hasCurrent: false

  property Item current: content.item?.current ?? null

  // Animation properties
  property int animLength: 200
  property list<real> animCurve: [0.4, 0.0, 0.2, 1.0]
  property int gap: 4                 // small gap between bar and popout

  function showWorkspaceGrid(anchor, data) {
    console.log("ShowWorkspaceGrid called");
    currentName = "workspace-grid";
    currentAnchor = anchor;
    currentData = data;
    hasCurrent = true;
    console.log("POP show ws grid", currentData.activeId);
    console.log("POP anchor", currentAnchor);
  }

  function close() {
    hasCurrent = false;
    hideTimer.restart();
  }

  PopupWindow {
    id: connectorWindow
    visible: popwin.visible
    color: "transparent"

    implicitWidth: content.item ? (content.item.implicitWidth - Settings.barHeight) : 0
    implicitHeight: content.item ? content.item.implicitHeight : 0

    anchor {
      window: currentAnchor
      rect {
        x: currentData ? (currentData.anchorX || 0) + Settings.barHeight - 10 : 0
        y: currentData ? (currentData.anchorY || 0) - 10 : 0 // Also solve this magic num
        width: 20
        height: currentData ? currentData.anchorHeight : 40
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Colors.surface
      radius: 8
      border.color: Colors.fg
    }
    // Rectangle {
    //   x: -width / 2
    //   y: -width / 2
    //   width: 12
    //   height: 12
    //   radius: 6
    //   color: "black"
    // }
    //
    // Rectangle {
    //   x: -width / 2
    //   y: parent.height - height / 2
    //   width: 12
    //   height: 12
    //   radius: 6
    //   color: "black"
    // }
    // Image {
    //   anchors.fill: parent
    //   source: "data:image/svg+xml," + encodeURIComponent('<svg viewBox="0 0 24 40" xmlns="http://www.w3.org/2000/svg"><path d="M 24,0 L 24,40 L 8,40 Q 0,40 0,32 L 0,8 Q 0,0 8,0 Z" fill="' + Colors.accent2 + '"/></svg>')
    //   sourceSize: Qt.size(24, 40)
    //   smooth: true
    // }
  }

  PopupWindow {
    id: popwin
    visible: root.hasCurrent
    color: "transparent"
    // WlrLayershell.keyboardFocus: KeyboardFocus.OnDemand
    // WlrLayershell.keyboardFocus: KeyboardFocus.OnDemand
    // flags: Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    implicitWidth: content.item ? content.item.implicitWidth : 0
    implicitHeight: content.item ? content.item.implicitHeight : 0

    anchor {
      window: currentAnchor
      rect {
        x: currentData ? (currentData.anchorX || 0) + 170 : 0 // TODO: resolve this magic number
        y: currentData ? (currentData.anchorY || 0) : 0
        width: currentData ? (currentData.anchorWidth || 1) : 1
        height: currentData ? (currentData.anchorHeight || 1) : 1
      }
      edges: Edges.Right  // Anchor to right edge of widget
      gravity: Edges.Left  // Use left edge of popup
      // This will place the popup to the right of the widget, vertically centered
    }

    Component.onCompleted: {
        // This forces the window to track mouse movement
        popwin.setMouseGrabEnabled(false);  // Don't grab mouse
        popwin.setKeyboardGrabEnabled(false);  // Don't grab keyboard
    }

    // Item {
    //   anchors.fill: parent
    //
    //   // Curved connector piece
    //   Rectangle {
    //     width: 16
    //     height: 40  // Height of the connection area
    //     x: -width + 4  // Extend to the left
    //     y: parent.height / 2 - height / 2
    //     color: Colors.accent2
    //     radius: 8
    //     z: -100  // Behind main content
    //   }
    //
    //   // Main popup background
    //   Rectangle {
    //     anchors.fill: parent
    //     color: Colors.accent2
    //     radius: 8
    //     z: 0  // Behind content but above connector
    //   }
    // }

    Loader {
      id: content
      active: hasCurrent
      asynchronous: false
      enabled: true
      onLoaded: {
        if (item) {
          item.wrapper = root;
          // consistent check (assuming your content sets currentName: "workspace-grid")
          if (item.currentName !== root.currentName)
            console.warn("POP warning: loaded item name mismatch", item?.currentName, root.currentName);
        }
        // debug so you see real size
        Qt.callLater(() => console.log("popwin size", popwin.width, popwin.height));
      }
      sourceComponent: {
        switch (root.currentName) {
        case "workspace-grid":
          return workspaceGridComponent;
        default:
          return null;
        }
      }
    }
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: {
      currentName = "";
      currentAnchor = null;
      currentData = null;
    }
  }

  // Size based on content
  implicitWidth: hasCurrent && content.item ? content.item.implicitWidth : 0
  implicitHeight: hasCurrent && content.item ? content.item.implicitHeight : 0

  // IMPORTANT: give the Item real size; implicit* alone don't size an Item
  width: implicitWidth
  height: implicitHeight

  // Show only when we actually have size
  visible: width > 0 && height > 0
  clip: true
  z: 1e4  // ensure on top of bar

  // ── POSITIONING (no anchors; compute x/y from the bar sub-item) ──

  // LEFT edge of popout = RIGHT edge of the hovered bar item (plus small gap)
  // x: currentAnchor ? (function () {
  //     const target = parent ? parent : null; // null maps to the scene
  //     const p = currentAnchor.mapToItem(target, currentAnchor.width, 0);
  //     return Math.round(p.x + gap);
  //   })() : x  // leave whatever parent set if no anchor
  //
  // // Vertically center on the hovered bar item
  // y: currentAnchor ? (function () {
  //     const target = parent ? parent : null;
  //     const p = currentAnchor.mapToItem(target, currentAnchor.width / 2, currentAnchor.height / 2);
  //     return Math.round(p.y - height / 2);
  //   })() : y

  Behavior on x {
    NumberAnimation {
      duration: root.animLength
      easing.bezierCurve: root.animCurve
    }
  }
  Behavior on y {
    NumberAnimation {
      duration: root.animLength
      easing.bezierCurve: root.animCurve
    }
  }
  Behavior on implicitWidth {
    NumberAnimation {
      duration: root.animLength
      easing.bezierCurve: root.animCurve
    }
  }
  Behavior on implicitHeight {
    NumberAnimation {
      duration: root.animLength
      easing.bezierCurve: root.animCurve
    }
  }
  onHasCurrentChanged: if (hasCurrent)
    Qt.callLater(() => console.log("POP size", implicitWidth, implicitHeight))

  // Loader for the actual popout content
  // Loader {
  //   id: content
  //   active: hasCurrent
  //   asynchronous: false
  //   onLoaded: {
  //     if (item) {
  //       item.wrapper = root;
  //       // consistent check (assuming your content sets currentName: "workspace-grid")
  //       if (item.currentName !== root.currentName)
  //         console.warn("POP warning: loaded item name mismatch", item?.currentName, root.currentName);
  //     }
  //     // debug so you see real size
  //     Qt.callLater(() => console.log("popwin size", popwin.width, popwin.height));
  //   }
  //
  //   // ❌ remove anchor-to-parent here; it causes crashes when parent is null
  //   // (no anchors are needed since we drive x/y on the wrapper)
  //
  //   sourceComponent: {
  //     switch (root.currentName) {
  //     case "workspace-grid":
  //       return workspaceGridComponent;
  //     default:
  //       return null;
  //     }
  //   }
  // }

  Component {
    id: workspaceGridComponent
    WorkspacePopOut {
      wrapper: root
    }
  }
}
