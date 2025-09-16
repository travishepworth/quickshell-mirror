import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "widgets" as Widgets

import "root:/services" as Services
import "root:/" as App

Item {
  id: root

  PanelWindow {
    id: backdrop
    visible: rightPanel.isOpen
    color: "transparent"
    aboveWindows: true
    focusable: false
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Clicking anywhere on the backdrop closes the panel
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onClicked: rightPanel.isOpen = false
      hoverEnabled: false
      propagateComposedEvents: false
    }
  }

  PanelWindow {
    id: rightPanel

    property bool isOpen: false
    property int panelWidth: screen.width / 6

    // keep panel above the backdrop
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    aboveWindows: true

    GlobalShortcut {
      appid: "qs"
      name: "right-panel-toggle"
      description: "Toggle Right Panel"
      onPressed: rightPanel.toggle()
    }

    anchors {
      top: true
      bottom: true
      right: true
    }

    margins {
      top: 4
      bottom: 4
      right: isOpen ? 10 : -panelWidth - 20
    }

    implicitWidth: panelWidth

    color: "transparent"
    visible: true
    focusable: isOpen

    Behavior on margins.right {
      NumberAnimation {
        duration: 150
        easing.type: Easing.InOutQuad
      }
    }

    function toggle() {
      isOpen = !isOpen;
    }

    // Close on Escape when open
    Item {
      anchors.fill: parent
      focus: rightPanel.isOpen
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          rightPanel.isOpen = false;
          event.accepted = true;
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Services.Colors.surfaceAlt
      radius: 12
      border.color: Services.Colors.accent
      border.width: 1
    }
  }
}
