// Memory.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  property string text: ""
  property string tooltip: ""

  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2
  implicitHeight: App.Settings.widgetHeight

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.green
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

  function update() {
    const meminfo = readFile("file:///proc/meminfo");
    if (!meminfo) return;
    let totalKB = 0, availKB = 0;
    const lines = meminfo.split("\n");
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("MemTotal:")) totalKB = parseInt(lines[i].match(/\d+/)[0], 10);
      if (lines[i].startsWith("MemAvailable:")) availKB = parseInt(lines[i].match(/\d+/)[0], 10);
    }
    if (totalKB > 0 && availKB >= 0) {
      const usedGB = (totalKB - availKB) / (1024 * 1024);
      const totalGB = totalKB / (1024 * 1024);
      text = usedGB.toFixed(1) + "G/" + totalGB.toFixed(1) + "G " + " ";
      tooltip = "Current memory usage: " + usedGB.toFixed(2) + "G/" + totalGB.toFixed(2) + "G";
      label.text = text;
      tip.text = tooltip;
    }
  }

  Timer {
    interval: 1000; running: true; repeat: true
    onTriggered: update()
  }
  Component.onCompleted: update()

  Text {
    id: label
    text: root.text
    anchors.centerIn: parent
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
