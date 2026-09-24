// BarPanel.qml
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import qs.config
import qs.components.hosts.popout

PanelWindow {
  id: root

  required property var barConfig

  // An empty monitor means the first screen
  screen: Quickshell.screens.find(s => s.name === barConfig.monitor) ?? Quickshell.screens[0] ?? null
  // A solid bar sits at the screen edge, and the screen border's strip
  // (arranged after it) overlaps its inner part, drawing the bar's inner
  // stroke. A floating bar (transparent or pills, with the border on) sits
  // inside the border instead: on the Overlay layer, whose exclusive zones
  // are arranged after the border's, with its outer edge on the border's
  // stroke so pills can cover it. Overlay draws over fullscreen windows, so
  // it hides while its workspace has one.
  WlrLayershell.layer: barConfig.floating ? WlrLayer.Overlay : WlrLayer.Top
  WlrLayershell.exclusiveZone: {
    if (!barConfig.reserveSpace)
      return 0;
    // Hyprland counts the -borderWidth margin into the reserved space
    if (barConfig.floating)
      return barConfig.extent;
    return Appearance.screenBorder ? barConfig.extent - Appearance.screenMargin + Appearance.borderWidth : barConfig.extent;
  }
  WlrLayershell.namespace: "axiom-bar"
  // The bar container paints the background (or not, when transparent)
  color: "transparent"

  anchors {
    top: (barConfig.top || barConfig.vertical)
    bottom: (barConfig.bottom || barConfig.vertical)
    left: (barConfig.left || !barConfig.vertical)
    right: (barConfig.right || !barConfig.vertical)
  }

  margins {
    top: root.barConfig.floating && root.barConfig.top ? -Appearance.borderWidth : 0
    bottom: root.barConfig.floating && root.barConfig.bottom ? -Appearance.borderWidth : 0
    left: root.barConfig.floating && root.barConfig.left ? -Appearance.borderWidth : 0
    right: root.barConfig.floating && root.barConfig.right ? -Appearance.borderWidth : 0
  }

  readonly property bool fullscreenBelow: Hyprland.monitorFor(root.screen)?.activeWorkspace?.hasFullscreen ?? false

  visible: barConfig.enabled && !(barConfig.floating && fullscreenBelow)

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
