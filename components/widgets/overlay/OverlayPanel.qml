pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.config
import qs.components.widgets.overlay
import qs.components.widgets.overlay.views

// TODO: build from a reusable fullscreen panel
PanelWindow {
  id: overlay

  required property var screen

  property bool isPrimaryScreen: screen.name === General.primaryMonitor
  property bool isOpen: false
  property bool enabled: overlay.isPrimaryScreen
  property real slideOffset: isOpen ? 0 : -height

  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }

  margins {
    left: Bar.extent
    right: Appearance.screenMargin - Appearance.borderWidth
    top: Appearance.screenMargin - Appearance.borderWidth
    bottom: Appearance.screenMargin - Appearance.borderWidth
  }

  color: "transparent"
  focusable: true
  visible: false
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusiveZone: -1

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
      overlay.visible = false;
    }
  }

  IpcHandler {
    target: "overlay"
    enabled: overlay.isPrimaryScreen

    function open() {
      overlay.open();
    }

    function close() {
      overlay.close();
    }

    function toggle() {
      overlay.toggle();
    }
  }

  HyprlandFocusGrab {
    id: grab
    active: overlay.visible && overlay.isPrimaryScreen
    windows: [overlay]
    onCleared: {
      if (!overlay.isOpen) {
        grab.active = true;
      }
    }
  }

  Item {
    id: slideContainer
    anchors.fill: parent

    transform: Translate {
      y: overlay.slideOffset
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

    OverlayTabWrapper {
      id: tabWrapper
      anchors.centerIn: parent
      screen: overlay.screen
    }

    OverlayPageNavigator {
      anchors {
        bottom: parent.bottom
        bottomMargin: Widget.padding * 2
        horizontalCenter: parent.horizontalCenter
      }
      visible: tabWrapper.viewsModel.length > 1
      currentIndex: tabWrapper.currentIndex
      count: tabWrapper.viewsModel.length
      onPrevious: tabWrapper.currentIndex = (tabWrapper.currentIndex - 1 + tabWrapper.viewsModel.length) % tabWrapper.viewsModel.length
      onNext: tabWrapper.currentIndex = (tabWrapper.currentIndex + 1) % tabWrapper.viewsModel.length
      onSelect: index => tabWrapper.currentIndex = index
    }
  }
}
