pragma ComponentBehavior: Bound
import QtQuick

import qs.config
import qs.components.reusable
import qs.components.widgets.common
import qs.components.widgets.bar.popouts

// Current conditions (see WeatherSource). Hovering opens a 5-day forecast.
BarIconWidget {
  id: root

  readonly property var current: source.current
  readonly property var condition: source.condition

  icon: condition?.icon ?? "\u{F0590}"
  text: current ? `${Math.round(current.temperature_2m)}°` + (properties.showCondition ? ` ${condition.label}` : "") : "…"

  WeatherSource {
    id: source
    latitude: root.properties.latitude
    longitude: root.properties.longitude
    location: root.properties.location
    units: root.properties.units
    intervalMinutes: root.properties.intervalMinutes
  }

  PopoutAnchor {
    popouts: root.popouts
    panel: root.panel
    popoutName: "Weather"
    active: root.properties.showPopout && source.weather !== null
    extraData: ({
        "weather": source.weather,
        "placeName": source.place?.name ?? "",
        "unitSymbol": source.unitSymbol,
        "conditionFor": source.conditionFor
      })
  }
}
