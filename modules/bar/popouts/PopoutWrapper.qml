import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.services
import qs.components

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

  function showMediaPlayer(anchor, data) {
    console.log("ShowMediaPlayer called");
    currentName = "media-player";
    currentAnchor = anchor;
    currentData = data;
    hasCurrent = true;
    console.log("POP show media player");
    console.log("POP anchor", currentAnchor);
  }

  function close() {
    hasCurrent = false;
    hideTimer.restart();
  }

  PopupWindow {
    id: combinedPopup
    visible: root.hasCurrent && implicitWidth > 0 && implicitHeight > 0
    color: "transparent"

    // Calculate total bounds to encompass both connector and main content
    implicitWidth: {
      var connectorEnd = connectorX + connectorWidth;
      var mainEnd = mainContentX + mainContentWidth;
      return Math.max(1, Math.max(connectorEnd, mainEnd));
    }

    implicitHeight: Math.max(1, Math.max(connectorHeight, mainContentHeight))

    // Position at the leftmost point (connector start)
    anchor {
      window: currentAnchor
      rect {
        x: currentData ? (currentData.anchorX || 0) + Settings.barHeight - 50 : 0
        y: currentData ? (currentData.anchorY || 0) - 10 : 0
        width: Math.max(1, 20)
        height: Math.max(1, currentData ? currentData.anchorHeight : 40)
      }
    }

    // Properties for layout calculations
    property int connectorX: 0
    property int connectorWidth: connectorContent.implicitWidth
    property int connectorHeight: currentData ? currentData.anchorHeight + 20 : 60

    property int mainContentX: 0
    property int mainContentWidth: content.item ? content.item.implicitWidth : 200
    property int mainContentHeight: content.item ? content.item.implicitHeight : 100

    // Container for both elements
    Item {
      anchors.fill: parent
      SlideAnimationContainer {
        id: mainAnimation
        x: combinedPopup.mainContentX
        y: 0
        width: combinedPopup.mainContentWidth + combinedPopup.connectorWidth
        height: combinedPopup.mainContentHeight

        active: root.hasCurrent && content.item
        slideFromRight: Settings.rightVerticalBar
        animationDuration: 250
        enableFade: true
        easingType: Easing.OutCubic

        Rectangle {
          id: connectorContent
          anchors.fill: parent
          color: Colors.surface
          radius: Settings.borderRadius
          border.color: Colors.fg

          Rectangle {
            anchors {
              left: parent.left
              top: parent.top
              bottom: parent.bottom
            }
            width: 3
            height: parent.height
            color: Colors.surface
            // color: "red"
          }
        }

        Loader {
          id: content // anchors.fill: parent anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right

          active: hasCurrent
          asynchronous: false
          enabled: true

          onLoaded: {
            if (item) {
              item.wrapper = root;
              if (item.currentName !== root.currentName) {
                console.warn("POP warning: loaded item name mismatch", item?.currentName, root.currentName);
              }
            }
            popwinSizeTimer.restart();
          }

          sourceComponent: {
            switch (root.currentName) {
            case "workspace-grid":
              return workspaceGridComponent;
            case "media-player":
              return mediaPlayerComponent;
            default:
              return null;
            }
          }
        }
      }
    }

    Timer {
      id: popwinSizeTimer
      interval: 1
      onTriggered: {
        console.log("popup size", combinedPopup.width, combinedPopup.height);
      }
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

  Component {
    id: workspaceGridComponent
    WorkspacePopOut {
      wrapper: root
    }
  }
  Component {
    id: mediaPlayerComponent
    MediaPanel {
      wrapper: root
    }
  }
}
