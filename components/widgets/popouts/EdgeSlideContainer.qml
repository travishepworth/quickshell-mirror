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
    
    // Calculate hidden position based on edge
    property real hiddenX: {
      if (!root.parent || root.width <= 0) return 0;
      switch (root.edge) {
        case EdgeSlideContainer.Edge.Left:
          return -root.width;  // Slide out to the left
        case EdgeSlideContainer.Edge.Right:
          return root.width;   // Slide out to the right
        case EdgeSlideContainer.Edge.Top:
        case EdgeSlideContainer.Edge.Bottom:
          return 0;  // No horizontal movement for top/bottom
      }
    }
    
    property real hiddenY: {
      if (!root.parent || root.height <= 0) return 0;
      switch (root.edge) {
        case EdgeSlideContainer.Edge.Top:
          return -root.height;  // Slide out to the top
        case EdgeSlideContainer.Edge.Bottom:
          return root.height;   // Slide out to the bottom
        case EdgeSlideContainer.Edge.Left:
        case EdgeSlideContainer.Edge.Right:
          return 0;  // No vertical movement for left/right
      }
    }
    
    // Visible positions (centered)
    property real visibleX: 0
    property real visibleY: 0
    
    // State management
    states: [
      State {
        name: "visible"
        when: root.active && root.width > 0 && root.height > 0
        PropertyChanges {
          target: contentWrapper
          x: visibleX
          y: visibleY
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
  
  // Optional fade animation
  opacity: root.enableFade ? (root.active ? 1.0 : 0.0) : 1.0
  
  Behavior on opacity {
    enabled: root.enableFade && root.visible
    NumberAnimation {
      duration: root.fadeAnimationDuration
      easing.type: Easing.InOutQuad
    }
  }
  
  // Initialize position
  Component.onCompleted: {
    // Delay initialization to ensure everything is ready
    Qt.callLater(function() {
      if (root.width > 0 && root.height > 0) {
        if (!root.active) {
          // Start in hidden position
          contentWrapper.x = contentWrapper.hiddenX;
          contentWrapper.y = contentWrapper.hiddenY;
        } else {
          // Start in visible position
          contentWrapper.x = contentWrapper.visibleX;
          contentWrapper.y = contentWrapper.visibleY;
        }
      }
    });
  }
  
  // Update positions when size changes
  onWidthChanged: {
    if (width > 0) {
      updateHiddenPositions();
    }
  }
  
  onHeightChanged: {
    if (height > 0) {
      updateHiddenPositions();
    }
  }
  
  onEdgeChanged: {
    updateHiddenPositions();
    // Reset to appropriate position
    if (!root.active) {
      contentWrapper.x = contentWrapper.hiddenX;
      contentWrapper.y = contentWrapper.hiddenY;
    }
  }
  
  // Helper function to recalculate positions
  function updateHiddenPositions() {
    // Force binding re-evaluation
    contentWrapper.hiddenX = contentWrapper.hiddenX;
    contentWrapper.hiddenY = contentWrapper.hiddenY;
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
  
  // Debug helper
  function debugInfo() {
    console.log("EdgeSlideContainer Debug:");
    console.log("  Edge:", edge);
    console.log("  Active:", active);
    console.log("  Size:", width, "x", height);
    console.log("  Content position:", contentWrapper.x, contentWrapper.y);
    console.log("  Hidden position:", contentWrapper.hiddenX, contentWrapper.hiddenY);
  }
}
