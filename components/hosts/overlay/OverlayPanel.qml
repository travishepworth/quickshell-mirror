pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.config
import qs.services
import qs.components.views

// TODO: build from a reusable fullscreen panel
PanelWindow {
  id: root

  required property var screen

  property bool isOpen: false
  property real slideOffset: isOpen ? 0 : -height

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  // Normal exclusion with no zone of its own places the window inside the
  // border's and bars' reserved area, wherever the bars are; the
  // -borderWidth margin lines it up with their inner stroke (as EdgePopout)
  margins {
    left: -Appearance.borderWidth
    right: -Appearance.borderWidth
    top: -Appearance.borderWidth
    bottom: -Appearance.borderWidth
  }

  color: "transparent"
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.layer: WlrLayer.Overlay
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  function open() {
    visible = true;
    isOpen = true;
  }

  function close() {
    isOpen = false;
    hideTimer.start();
  }

  function toggle() {
    if (isOpen) {
      close();
    } else {
      open();
    }
  }

  Timer {
    id: hideTimer
    interval: Appearance.animSlow
    repeat: false
    onTriggered: {
      root.visible = false;
    }
  }

  Connections {
    target: ShellManager
    function onToggleOverlay() {
      if (ShellManager.isTarget(root.screen))
        root.toggle();
    }
  }

  IpcHandler {
    target: "overlay"
    // One handler per target name: the target screen's
    enabled: ShellManager.isTarget(root.screen)

    function open() {
      root.open();
    }

    function close() {
      root.close();
    }

    function toggle() {
      root.toggle();
    }
  }

  HyprlandFocusGrab {
    id: grab
    active: root.visible
    windows: [root]
    onCleared: {
      if (!root.isOpen) {
        grab.active = true;
      }
    }
  }

  Item {
    id: slideContainer
    anchors.fill: parent

    transform: Translate {
      y: root.slideOffset
      Behavior on y {
        NumberAnimation {
          duration: Appearance.animSlow
          easing.type: Easing.InOutQuad
        }
      }
    }

    Rectangle {
      id: background
      anchors.fill: parent
      border.color: Theme.foreground
      border.width: Math.max(Appearance.borderWidth, 2)
      radius: Appearance.borderRadius
      color: Appearance.darkMode ? Theme.background : Theme.foreground
      opacity: 0.85
    }

    OverlayPages {
      id: tabWrapper
      anchors.centerIn: parent
      screen: root.screen
      open: root.visible
    }

    OverlayPageNavigator {
      anchors {
        bottom: parent.bottom
        bottomMargin: Widget.padding * 2
        horizontalCenter: parent.horizontalCenter
      }
      currentIndex: tabWrapper.currentIndex
      count: tabWrapper.pageCount
      onPrevious: tabWrapper.currentIndex = (tabWrapper.currentIndex - 1 + tabWrapper.pageCount) % tabWrapper.pageCount
      onNext: tabWrapper.currentIndex = (tabWrapper.currentIndex + 1) % tabWrapper.pageCount
      onSelect: index => tabWrapper.currentIndex = index
    }
  }
}
