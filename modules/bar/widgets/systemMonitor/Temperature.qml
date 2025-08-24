// Temperature.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

import "root:/" as App
import "root:/services" as Services

Item {
  id: root

  property string className: "cool"
  property string text: ""
  property string tooltip: ""

  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2
  height: App.Settings.widgetHeight

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent3
    radius: App.Settings.borderRadius
  }

  function readFile(url) {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open("GET", url, false);
      xhr.send();
      return xhr.status === 0 || xhr.status === 200 ? xhr.responseText : "";
    } catch (e) { return ""; }
  }

  function readTempC() {
    // Generic fallback: thermal_zone0
    const raw = readFile("file:///sys/class/thermal/thermal_zone0/temp");
    if (raw && /^\d+/.test(raw)) {
      const milli = parseInt(raw.match(/\d+/)[0], 10);
      return Math.round(milli / 1000);
    }
    return NaN;
  }

  function update() {
    const t = readTempC();
    if (isNaN(t)) {
      text = "N/A°C ";
      tooltip = "CPU Temperature: N/A";
      className = "cool";
    } else {
      if (t <= 60) className = "cool";
      else if (t <= 75) className = "warm";
      else className = "hot";

      text = t + "°C " + "";
      tooltip = "CPU Temperature: " + t + "°C";
    }
    label.text = text;
    tip.text = tooltip;
  }

  Timer {
    interval: 5000; running: true; repeat: true
    onTriggered: update()
  }
  Component.onCompleted: update()

  Text {
    id: label
    text: root.text
    anchors.centerIn: parent
    property string className: root.className
    color: Services.Colors.bg
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
  }

  ToolTip {
    id: tip
    visible: area.containsMouse
    delay: 200
    timeout: 10000
    text: root.tooltip
  }
  MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
}
