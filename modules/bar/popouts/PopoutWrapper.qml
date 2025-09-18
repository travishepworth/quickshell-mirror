import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services

Item {
  id: root

  required property var screen

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
  }

  function close() {
    hasCurrent = false;
    hideTimer.restart();
  }

  PopupWindow {
    id: popwin
    visible: root.hasCurrent
    // flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: Colors.accent2   // keep everything outside the panel invisible
    // modality: Qt.NonModal
    anchor.window: toplevel

    // WlrLayershell.layer: WlrLayershell.Overlay
    // WlrLayershell.exclusiveZone: 0

    // place to the RIGHT of the hovered bar item using global coords
    // x: (root.currentAnchor && root.currentAnchor.window) ? root.currentAnchor.window.mapToGlobal(root.currentAnchor.mapToScene(root.currentAnchor.width, 0)).x + root.gap : 0
    // y: (root.currentAnchor && root.currentAnchor.window) ? root.currentAnchor.window.mapToGlobal(root.currentAnchor.mapToScene(root.currentAnchor.width / 2, root.currentAnchor.height / 2)).y - height / 2 : 0

    // size the window to the loaded content
    implicitWidth: content.item ? content.item.implicitWidth : 0
    implicitHeight: content.item ? content.item.implicitHeight : 0

    // you can add simple fade/slide behaviors if you want, not required
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
  x: currentAnchor ? (function () {
      const target = parent ? parent : null; // null maps to the scene
      const p = currentAnchor.mapToItem(target, currentAnchor.width, 0);
      return Math.round(p.x + gap);
    })() : x  // leave whatever parent set if no anchor

  // Vertically center on the hovered bar item
  y: currentAnchor ? (function () {
      const target = parent ? parent : null;
      const p = currentAnchor.mapToItem(target, currentAnchor.width / 2, currentAnchor.height / 2);
      return Math.round(p.y - height / 2);
    })() : y

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
  Loader {
    id: content
    active: hasCurrent
    asynchronous: false
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

    // ❌ remove anchor-to-parent here; it causes crashes when parent is null
    // (no anchors are needed since we drive x/y on the wrapper)

    sourceComponent: {
      switch (root.currentName) {
      case "workspace-grid":
        return workspaceGridComponent;
      default:
        return null;
      }
    }
  }

  Component {
    id: workspaceGridComponent
    WorkspacePopOut {
      wrapper: root
    }
  }
}
