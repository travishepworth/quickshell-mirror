pragma Singleton
import QtQuick
import Quickshell

import qs.services

QtObject {
  enum Location {
    Top,
    Bottom,
    Left,
    Right
  }
  // Adds derived orientation flags to a bar entry from the Bars section
  // (whose keys are always filled in from the schema defaults).
  function enrichBarConfig(barConfig, index = 0) {
    const loc = Bar.getLocationFromString(barConfig.location);
    const extent = barConfig.extent;
    // Thickness of the bar's widgets, so they always fit inside it
    const widgetSize = Math.max(0, extent - 2 * (barConfig.inset ?? 0));
    const background = barConfig.background ?? "solid";
    // A pill covers the screen border's stroke where it joins it
    const overlap = Appearance.screenBorder ? Appearance.borderWidth : 0;
    // Padding around a pill's widgets, capped so the pill (and its far
    // stroke) fits the bar
    const pillPad = Math.min(barConfig.pillPadding ?? 0, Math.max(0, Math.floor((extent - widgetSize - overlap - Appearance.borderWidth) / 2)));

    return {
      "id": barConfig.id,
      "primary": index === 0,
      "enabled": barConfig.enabled,
      "monitor": barConfig.monitor,
      "extent": barConfig.extent,
      "inset": barConfig.inset ?? 0,
      "widgetSize": widgetSize,
      "background": background,
      "pills": background === "pills",
      // Transparent and pill bars sit inside the screen border, not under it
      "floating": background !== "solid" && Appearance.screenBorder,
      "overlap": overlap,
      "pillPad": pillPad,
      "pillMerge": barConfig.pillMerge ?? 0,
      // How far a pill reaches in from the bar's outer edge: the border
      // stroke it covers, the padding each side of its widgets, and its own
      // far stroke
      "pillDepth": overlap + 2 * pillPad + widgetSize + Appearance.borderWidth,
      "spacing": barConfig.spacing,
      "lockCenter": barConfig.lockCenter,
      "location": loc,
      "reserveSpace": barConfig.reserveSpace,
      "widgets": barConfig.widgets,
      "vertical": loc === Bar.Left || loc === Bar.Right,
      "left": loc === Bar.Left,
      "right": loc === Bar.Right,
      "top": loc === Bar.Top,
      "bottom": loc === Bar.Bottom
    };
  }

  // The first entry in Bars is the primary bar
  readonly property var bars: ConfigManager.config.Bars.map((bar, i) => Bar.enrichBarConfig(bar, i))

  readonly property var availableWidgetTypes: {
    const oneOf = ConfigManager.configSchema?.definitions?.BarWidget?.oneOf || [];
    return oneOf.map(refObj => {
      const refName = refObj.$ref.replace("#/definitions/", "");
      const def = ConfigManager.configSchema.definitions[refName];
      if (!def)
        return null;
      return {
        "type": def.properties?.type?.const,
        "label": def.properties?.type?.description || def.properties?.type?.const,
        "propertiesSchema": def.properties?.properties?.properties || null
      };
    }).filter(t => t !== null);
  }
  // Global convenience properties for first bar
  // Convenience values for the primary bar (Bars may be empty)
  readonly property bool enabled: Bar.bars[0]?.enabled ?? false
  readonly property int extent: Bar.bars[0]?.extent ?? 0
  readonly property int location: Bar.bars[0]?.location ?? Bar.Top
  readonly property var widgets: Bar.bars[0]?.widgets ?? null
  readonly property int spacing: Bar.bars[0]?.spacing ?? 0

  readonly property bool vertical: location === Bar.Left || location === Bar.Right
  readonly property bool left: location === Bar.Left
  readonly property bool right: location === Bar.Right
  readonly property bool top: location === Bar.Top
  readonly property bool bottom: location === Bar.Bottom

  // The enabled bars on a screen by edge ({ top, bottom, left, right },
  // null where there is none). A bar with no monitor is on the first screen,
  // as in BarPanel.
  function edgesFor(screen) {
    const edges = {
      "top": null,
      "bottom": null,
      "left": null,
      "right": null
    };
    const first = Quickshell.screens[0]?.name ?? "";
    Bar.bars.forEach(bar => {
      if (!bar.enabled)
        return;
      const named = Quickshell.screens.some(s => s.name === bar.monitor);
      if ((named ? bar.monitor : first) !== screen?.name)
        return;
      const edge = bar.top ? "top" : bar.bottom ? "bottom" : bar.left ? "left" : "right";
      if (!edges[edge])
        edges[edge] = bar;
    });
    return edges;
  }

  // Whether a screen edge (a Bar.Location) is bare: no screen border and no
  // bar on it, so surfaces there run straight off the screen
  function screenEdgeOpen(screen, location) {
    if (Appearance.screenBorder)
      return false;
    const name = ["top", "bottom", "left", "right"][location];
    return !Bar.edgesFor(screen)[name];
  }

  function getLocationFromString(locStr) {
    switch (locStr) {
    case "Top":
      return Bar.Top;
    case "Bottom":
      return Bar.Bottom;
    case "Left":
      return Bar.Left;
    case "Right":
      return Bar.Right;
    default:
      return Bar.Top;
    }
  }
}
