pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable
import qs.services
import qs.components.content.base

// Current weather, plus the next hours (wide/large slots) and days (tall /
// large slots) as room allows. Same source and settings as the bar widget.
// properties: { location, latitude, longitude, units }
Card {
  id: root

  // From config only (acquire() must not follow live values)
  readonly property var weatherRequest: ({
      "latitude": root.properties.latitude ?? "",
      "longitude": root.properties.longitude ?? "",
      "location": root.properties.location ?? "",
      "units": root.properties.units ?? "celsius"
    })
  readonly property var source: WeatherManager.sourceFor(weatherRequest)
  onWeatherRequestChanged: WeatherManager.acquire(root, weatherRequest)
  Component.onCompleted: WeatherManager.acquire(root, weatherRequest)
  Component.onDestruction: WeatherManager.release(root)

  readonly property var current: source.current
  readonly property bool showHourly: !root.compact && root.cols >= 2 && (root.shape === "horizontal" || root.rows >= 3)
  readonly property bool showDaily: !root.compact && root.rows >= 2 && root.shape !== "horizontal"

  StyledText {
    anchors.centerIn: parent
    visible: !root.current
    text: "\u{F0590}  …"
    opacity: 0.5
  }

  ColumnLayout {
    visible: root.current !== null
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    RowLayout {
      Layout.fillWidth: true
      spacing: root.pad
      StyledText {
        text: source.condition?.icon ?? ""
        textColor: Theme.accent
        textSize: root.compact ? Appearance.fontSize * 2 : Appearance.fontSize * 3.2
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        StyledText {
          text: root.current ? `${Math.round(root.current.temperature_2m)}${source.unitSymbol}` : ""
          textSize: root.compact ? Appearance.fontSize * 1.5 : Appearance.fontSize * 2.2
          font.bold: true
        }
        StyledText {
          visible: !root.compact
          Layout.fillWidth: true
          elide: Text.ElideRight
          text: I18n.tr("{0} · feels {1}°", source.condition?.label ?? "", Math.round(root.current?.apparent_temperature ?? 0))
          opacity: 0.8
        }
        StyledText {
          visible: !root.compact
          Layout.fillWidth: true
          elide: Text.ElideRight
          text: `${source.place?.name ?? ""}  ·  \u{F059D} ${Math.round(root.current?.wind_speed_10m ?? 0)}  \u{F058E} ${root.current?.relative_humidity_2m ?? 0}%`
          textSize: Appearance.fontSize - 2
          opacity: 0.6
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }

    // Next hours
    RowLayout {
      visible: root.showHourly
      Layout.fillWidth: true
      spacing: 0
      Repeater {
        model: root.showHourly ? Math.min(12, Math.floor(root.width / 70)) : 0
        ColumnLayout {
          required property int index
          readonly property var hourly: source.weather?.hourly
          Layout.fillWidth: true
          spacing: 2
          StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: parent.hourly ? Qt.formatTime(new Date(parent.hourly.time[parent.index]), "HH") : ""
            textSize: Appearance.fontSize - 3
            opacity: 0.6
          }
          StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: parent.hourly ? source.conditionFor(parent.hourly.weather_code[parent.index], parent.hourly.is_day[parent.index]).icon : ""
          }
          StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: parent.hourly ? `${Math.round(parent.hourly.temperature_2m[parent.index])}°` : ""
            textSize: Appearance.fontSize - 1
          }
        }
      }
    }

    // Next days
    ColumnLayout {
      visible: root.showDaily
      Layout.fillWidth: true
      spacing: 2
      Repeater {
        model: root.showDaily ? (source.weather?.daily?.time?.length ?? 0) : 0
        RowLayout {
          required property int index
          readonly property var daily: source.weather.daily
          Layout.fillWidth: true
          StyledText {
            Layout.preferredWidth: Appearance.fontSize * 4
            text: parent.index === 0 ? I18n.tr("Today") : I18n.formatDate(new Date(parent.daily.time[parent.index]), "ddd")
          }
          StyledText {
            text: source.conditionFor(parent.daily.weather_code[parent.index], 1).icon
            textColor: Theme.accent
          }
          Item {
            Layout.fillWidth: true
          }
          StyledText {
            text: `${Math.round(parent.daily.temperature_2m_min[parent.index])}°`
            opacity: 0.6
          }
          StyledText {
            text: `${Math.round(parent.daily.temperature_2m_max[parent.index])}°`
            font.bold: true
          }
        }
      }
    }
  }
}
