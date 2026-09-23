pragma Singleton
import QtQuick

import qs.services
import qs.config

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

    return {
      "id": barConfig.id,
      "primary": index === 0,
      "enabled": barConfig.enabled,
      "monitor": barConfig.monitor,
      "extent": barConfig.extent,
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
