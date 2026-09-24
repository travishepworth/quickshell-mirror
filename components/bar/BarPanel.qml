// BarPanel.qml
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.config
import qs.components.hosts.popout

PanelWindow {
  id: root

  required property var barConfig

  // An empty monitor means the first screen
  screen: Quickshell.screens.find(s => s.name === barConfig.monitor) ?? Quickshell.screens[0] ?? null
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusiveZone: !barConfig.reserveSpace ? 0 : barConfig.extent - Appearance.screenMargin + Appearance.borderWidth
  WlrLayershell.namespace: "axiom-bar"

  anchors {
    top: (barConfig.top || barConfig.vertical)
    bottom: (barConfig.bottom || barConfig.vertical)
    left: (barConfig.left || !barConfig.vertical)
    right: (barConfig.right || !barConfig.vertical)
  }

  visible: barConfig.enabled

  implicitHeight: barConfig.vertical ? 0 : barConfig.extent
  implicitWidth: barConfig.vertical ? barConfig.extent : 0

  Component.onCompleted: {
    console.log("========== BAR PANEL ==========");
    console.log("  > Screen:", barConfig.monitor, "->", screen ? "Found" : "Not Found");
    console.log("  > Panel width:", width, "height:", height);
    console.log("  > Visible:", visible);
    console.log("  > implicitWidth:", implicitWidth, "implicitHeight:", implicitHeight);
    console.log("================================");
  }

  BarPopouts {
    id: popouts
    barConfig: root.barConfig
    panel: root
    screen: root.screen
    layoutSource: bar.barContainer
  }

  // Use the standalone Bar component
  StandaloneBar {
    id: bar
    anchors.fill: parent
    barConfig: root.barConfig
    popouts: popouts
    panel: root
    screen: root.screen
  }
}
