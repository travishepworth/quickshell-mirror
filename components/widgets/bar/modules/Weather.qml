pragma ComponentBehavior: Bound
import QtQuick

import qs.config
import qs.components.reusable
import qs.components.widgets.bar.popouts

// Current conditions from Open-Meteo (no API key). Location comes from the
// latitude/longitude properties, else the `location` name (geocoded), else
// the machine's IP. Hovering opens a 5-day forecast. A failed refresh keeps
// showing the last good data.
IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  // { latitude, longitude, name }, resolved once per location setting
  property var place: null
  // Open-Meteo forecast response
  property var weather: null
  property bool _failing: false

  readonly property string locationKey: [properties.latitude, properties.longitude, properties.location].join("|")
  readonly property string unitSymbol: properties.units === "fahrenheit" ? "°F" : "°C"
  readonly property var current: weather?.current ?? null
  readonly property var condition: current ? conditionFor(current.weather_code, current.is_day) : null

  isVertical: barConfig.vertical

  icon: condition?.icon ?? "\u{F0590}"
  text: current ? `${Math.round(current.temperature_2m)}°` + (properties.showCondition ? ` ${condition.label}` : "") : "…"

  backgroundColor: Theme.resolveColor(properties.backgroundColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)

  // WMO weather interpretation codes
  function conditionFor(code, isDay) {
    const day = isDay !== 0;
    if (code === 0)
      return {
        "icon": day ? "\u{F0599}" : "\u{F0594}",
        "label": "Clear"
      };
    if (code <= 2)
      return {
        "icon": day ? "\u{F0595}" : "\u{F0F31}",
        "label": "Partly cloudy"
      };
    if (code === 3)
      return {
        "icon": "\u{F0590}",
        "label": "Overcast"
      };
    if (code === 45 || code === 48)
      return {
        "icon": "\u{F0591}",
        "label": "Fog"
      };
    if (code >= 51 && code <= 57)
      return {
        "icon": "\u{F0597}",
        "label": "Drizzle"
      };
    if ([65, 67, 82].includes(code))
      return {
        "icon": "\u{F0596}",
        "label": "Heavy rain"
      };
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
      return {
        "icon": "\u{F0597}",
        "label": "Rain"
      };
    if ((code >= 71 && code <= 77) || code === 85 || code === 86)
      return {
        "icon": "\u{F0598}",
        "label": "Snow"
      };
    if (code >= 95)
      return {
        "icon": "\u{F0593}",
        "label": "Thunderstorm"
      };
    return {
      "icon": "\u{F0590}",
      "label": "Unknown"
    };
  }

  function getJson(url, onResult) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      let result = null;
      if (xhr.status === 200) {
        try {
          result = JSON.parse(xhr.responseText);
        } catch (e) {}
      }
      if (!result) {
        // Warn once per outage, not on every retry
        if (!root._failing)
          console.warn(`[Weather] Request failed (${xhr.status}): ${url}`);
        root._failing = true;
        return;
      }
      root._failing = false;
      onResult(result);
    };
    xhr.send();
  }

  function resolvePlace(then) {
    const p = properties;
    const lat = parseFloat(p.latitude);
    const lon = parseFloat(p.longitude);
    if (!isNaN(lat) && !isNaN(lon)) {
      place = {
        "latitude": lat,
        "longitude": lon,
        "name": p.location || `${lat.toFixed(2)}, ${lon.toFixed(2)}`
      };
      then();
    } else if (p.location) {
      getJson(`https://geocoding-api.open-meteo.com/v1/search?count=1&name=${encodeURIComponent(p.location)}`, data => {
        const r = data.results?.[0];
        if (!r) {
          console.warn(`[Weather] Unknown location: ${p.location}`);
          return;
        }
        root.place = {
          "latitude": r.latitude,
          "longitude": r.longitude,
          "name": [r.name, r.admin1, r.country_code].filter(Boolean).join(", ")
        };
        then();
      });
    } else {
      getJson("https://ipapi.co/json/", data => {
        if (data.latitude === undefined)
          return;
        root.place = {
          "latitude": data.latitude,
          "longitude": data.longitude,
          "name": [data.city, data.region_code].filter(Boolean).join(", ")
        };
        then();
      });
    }
  }

  function refresh() {
    if (!place) {
      resolvePlace(refresh);
      return;
    }
    const params = ["latitude=" + place.latitude, "longitude=" + place.longitude, "current=temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m,relative_humidity_2m", "daily=weather_code,temperature_2m_max,temperature_2m_min", "timezone=auto", "forecast_days=5", "temperature_unit=" + properties.units, "wind_speed_unit=" + (properties.units === "fahrenheit" ? "mph" : "kmh")];
    getJson("https://api.open-meteo.com/v1/forecast?" + params.join("&"), data => root.weather = data);
  }

  onLocationKeyChanged: {
    place = null;
    refreshSoon.restart();
  }
  onUnitSymbolChanged: refreshSoon.restart()

  // Coalesces setting changes into one refresh. A Timer rather than
  // Qt.callLater, so it dies with this instance on a config reload.
  Timer {
    id: refreshSoon
    interval: 250
    onTriggered: root.refresh()
  }

  Timer {
    interval: root.properties.intervalMinutes * 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  PopoutAnchor {
    popouts: root.popouts
    panel: root.panel
    popoutName: "weather"
    active: root.properties.showPopout && root.weather !== null
    extraData: ({
        "weather": root.weather,
        "placeName": root.place?.name ?? "",
        "unitSymbol": root.unitSymbol,
        "conditionFor": root.conditionFor
      })
  }
}
