// EdgePopup.qml - Refactored version using PopupWindow
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.components.widgets.popouts
import qs.components.widgets.reusable

Item {
  id: root

  // Core properties
  property bool active: false
  default property alias content: contentArea.data

  // Panel window properties
  property bool aboveWindows: true
  property bool focusable: false

  // Animation configuration
  property int animationDuration: 300
  property var easingType: Easing.OutCubic

  // Edge configuration
  enum Edge {
    Left,
    Right,
    Top,
    Bottom
  }
  property int edge: EdgePopup.Edge.Right

  // Position along edge (0-1)
  property real position: 0.5
  property real positionOffset: 0  // Pixel offset

  // Size configuration
  property bool useImplicitSize: true  // Use content's implicit size
  property int customWidth: 300
  property int customHeight: 400
  property int edgeMargin: 0  // Distance from screen edge when visible

  // Optional fade
  property bool enableFade: true

  // Trigger configuration
  property bool enableTrigger: true
  property int triggerWidth: 5
  property int triggerLength: 200
  property bool triggerOnHover: true
  property bool triggerOnClick: false
  property int hoverDelay: 300
  property bool showTriggerIndicator: false

  // Close behavior
  property bool closeOnMouseExit: true
  property bool closeOnClickOutside: true

  // Trigger area (serves as anchor for the popup)
  EdgeTrigger {
    id: trigger

    edge: {
      switch (root.edge) {
      case EdgePopup.Edge.Left:
        return EdgeTrigger.Edge.Left;
      case EdgePopup.Edge.Right:
        return EdgeTrigger.Edge.Right;
      case EdgePopup.Edge.Top:
        return EdgeTrigger.Edge.Top;
      case EdgePopup.Edge.Bottom:
        return EdgeTrigger.Edge.Bottom;
      }
    }

    position: root.position
    positionOffset: root.positionOffset
    triggerWidth: root.triggerWidth
    triggerLength: root.triggerLength
    triggerOnHover: root.triggerOnHover
    triggerOnClick: root.triggerOnClick
    hoverDelay: root.hoverDelay

    onHoverStarted: {
      if (root.enableTrigger && root.triggerOnHover) {
        console.log("hover started");
        root.active = true;
      }
    }

    onTriggered: {
      root.active = true;
    }
  }

  // Main Popup Window - now anchored to the trigger
  PopupWindow {
    id: popup
    visible: root.active

    // Anchor to the trigger window
    anchor.window: trigger

    // Position the popup based on edge
    anchor.rect.x: {
      switch (root.edge) {
      case EdgePopup.Edge.Left:
        // Popup appears to the right of trigger
        return trigger.width + root.edgeMargin;
      case EdgePopup.Edge.Right:
        // Popup appears to the left of trigger
        return -(root.useImplicitSize ? contentArea.implicitWidth : root.customWidth) - root.edgeMargin;
      case EdgePopup.Edge.Top:
      case EdgePopup.Edge.Bottom:
        // Center horizontally on trigger
        return (trigger.width / 2) - (width / 2);
      }
    }

    anchor.rect.y: {
      switch (root.edge) {
      case EdgePopup.Edge.Top:
        // Popup appears below trigger
        return trigger.height + root.edgeMargin;
      case EdgePopup.Edge.Bottom:
        // Popup appears above trigger
        return -(root.useImplicitSize ? contentArea.implicitHeight : root.customHeight) - root.edgeMargin;
      case EdgePopup.Edge.Left:
      case EdgePopup.Edge.Right:
        // Center vertically on trigger
        return (trigger.height / 2) - (height / 2);
      }
    }

    // Size handling
    width: root.useImplicitSize ? contentArea.implicitWidth : root.customWidth
    height: root.useImplicitSize ? contentArea.implicitHeight : root.customHeight

    // Background color (can be transparent or styled)
    color: "transparent"

    // Content wrapper for future animation
    EdgeSlideContainer {
      id: contentWrapper
      anchors.fill: parent
      active: root.active
      edge: {
        switch (root.edge) {
        case EdgePopup.Edge.Left:
          return EdgeSlideContainer.Edge.Left;
        case EdgePopup.Edge.Right:
          return EdgeSlideContainer.Edge.Right;
        case EdgePopup.Edge.Top:
          return EdgeSlideContainer.Edge.Top;
        case EdgePopup.Edge.Bottom:
          return EdgeSlideContainer.Edge.Bottom;
        }
      }

      animationDuration: root.animationDuration
      easingType: root.easingType
      enableFade: root.enableFade
      fadeAnimationDuration: 200

      // Content holder
      Item {
        id: contentArea
        anchors.fill: parent

        // Each child can have its own MouseArea for interaction
        // This allows content to be self-contained with its own close behavior

        // Optional: Monitor if any child has mouse
        property bool childHasMouse: {
          for (let i = 0; i < children.length; i++) {
            let child = children[i];
            // Check if child has a mouseArea property and it contains mouse
            if (child.mouseArea && child.mouseArea.containsMouse) {
              return true;
            }
          }
          return false;
        }
      }

      // Background close area - only for clicking outside content
      MouseArea {
        id: closeArea
        anchors.fill: parent
        enabled: root.active && root.closeOnClickOutside
        z: -1  // Behind content so content mouse areas work

        onClicked: {
          // Only close if clicking on empty space
          root.active = false;
        }
      }

      // Hover exit detector - separate from click handling
      MouseArea {
        id: hoverExitDetector
        anchors.fill: parent
        enabled: root.active && root.closeOnMouseExit
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Don't interfere with clicks
        z: -2  // Behind everything

        onExited: {
          // Close when mouse leaves the popup entirely
          root.active = false;
        }
      }
    }
  }

  // Public functions
  function toggleAboveWindow() {
    aboveWindows = !aboveWindows;
  }

  function show() {
    active = true;
  }

  function hide() {
    active = false;
  }

  function toggle() {
    active = !active;
  }

  function setPosition(pos, offset = 0) {
    position = Math.max(0, Math.min(1, pos));
    positionOffset = offset;
  }

  Component.onCompleted: {
    console.log("EdgePopup initialized with edge:", edge);
  }
}
