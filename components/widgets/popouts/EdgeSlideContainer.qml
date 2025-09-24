// EdgeSlideContainer.qml - Animation container for edge-based popups
import QtQuick
import Quickshell

Item {
  id: root

  // Core properties
  property bool active: false

  // Edge configuration - determines slide direction
  enum Edge {
    Left,
    Right,
    Top,
    Bottom
  }
  property int edge: EdgeSlideContainer.Edge.Right

  // Animation configuration
  property int animationDuration: 300
  property var easingType: Easing.OutCubic

  // Optional fade animation
  property bool enableFade: true
  property int fadeAnimationDuration: 200

  // Content
  default property alias content: contentArea.children

  // Size based on content
  implicitWidth: Math.max(1, contentArea.implicitWidth)
  implicitHeight: Math.max(1, contentArea.implicitHeight)

  // Clip content during animation
  clip: true

  // Main animation wrapper
  Item {
    id: contentWrapper
    width: parent.width > 0 ? parent.width : 1
    height: parent.height > 0 ? parent.height : 1

    // Target positions (visible state)
    property real targetX: 0
    property real targetY: 0

    // Hidden positions based on edge
    property real hiddenX: {
      if (!root.parent)
        return 0;
      var w = root.width > 0 ? root.width : 1;
      switch (root.edge) {
      case EdgeSlideContainer.Edge.Left:
        return -w;  // Slide from left
      case EdgeSlideContainer.Edge.Right:
        return w;   // Slide from right
      default:
        return 0;   // No horizontal movement for top/bottom
      }
    }

    property real hiddenY: {
      if (!root.parent)
        return 0;
      var h = root.height > 0 ? root.height : 1;
      switch (root.edge) {
      case EdgeSlideContainer.Edge.Top:
        return -h;  // Slide from top
      case EdgeSlideContainer.Edge.Bottom:
        return h;   // Slide from bottom
      default:
        return 0;   // No vertical movement for left/right
      }
    }

    // State management
    states: [
      State {
        name: "visible"
        when: root.active && root.width > 0 && root.height > 0
        PropertyChanges {
          target: contentWrapper
          x: targetX
          y: targetY
        }
      },
      State {
        name: "hidden"
        when: !root.active || root.width <= 0 || root.height <= 0
        PropertyChanges {
          target: contentWrapper
          x: hiddenX
          y: hiddenY
        }
      }
    ]

    // Smooth transitions
    transitions: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "x"
          duration: root.animationDuration
          easing.type: root.easingType
        }
        NumberAnimation {
          property: "y"
          duration: root.animationDuration
          easing.type: root.easingType
        }
      }
    }

    // Content area
    Item {
      id: contentArea
      anchors.fill: parent
    }
  }

  // Optional opacity animation
  opacity: root.enableFade ? (root.active ? 1.0 : 0.0) : 1.0

  Behavior on opacity {
    enabled: root.enableFade && root.visible
    NumberAnimation {
      duration: root.fadeAnimationDuration
      easing.type: Easing.InOutQuad
    }
  }

  // Defensive initialization
  Component.onCompleted: {
    // Delay initialization to ensure parent is ready
    Qt.callLater(function () {
      if (root.width > 0 && root.height > 0) {
        contentWrapper.x = root.active ? contentWrapper.targetX : contentWrapper.hiddenX;
        contentWrapper.y = root.active ? contentWrapper.targetY : contentWrapper.hiddenY;
      }
    });
  }

  // Update hidden position when size changes
  onWidthChanged: {
    if (width > 0) {
      // Force binding re-evaluation
      contentWrapper.hiddenX = contentWrapper.hiddenX;
    }
  }

  onHeightChanged: {
    if (height > 0) {
      // Force binding re-evaluation
      contentWrapper.hiddenY = contentWrapper.hiddenY;
    }
  }

  // Public API
  function show() {
    active = true;
  }

  function hide() {
    active = false;
  }

  function toggle() {
    active = !active;
  }
}
