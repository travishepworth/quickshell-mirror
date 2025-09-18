// ===== Temperature.qml =====
import QtQuick
import QtQuick.Controls

import qs.services

Item {
  id: root
  
  // Orientation support
  property int orientation: Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
  property bool isVertical: orientation === Qt.Vertical
  
  property string className: "cool"
  property string text: ""
  property string tooltip: ""
  property string icon: ""
  
  // Dynamic dimensions
  implicitWidth: isVertical ? Settings.widgetHeight : (contentLoader.item ? contentLoader.item.implicitWidth + Settings.widgetPadding * 2 : 60)
  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + Settings.widgetPadding * 2 : Settings.widgetHeight) : Settings.widgetHeight
  
  Rectangle {
    anchors.fill: parent
    color: Colors.blue
    radius: Settings.borderRadius
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
      text = "N/A°C";
      icon = "";
      tooltip = "CPU Temperature: N/A";
      className = "cool";
    } else {
      if (t <= 60) className = "cool";
      else if (t <= 75) className = "warm";
      else className = "hot";
      text = t + "°C";
      icon = "";
      tooltip = "CPU Temperature: " + t + "°C";
    }
  }
  
  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: update()
  }
  
  Component.onCompleted: update()
  
  Loader {
    id: contentLoader
    anchors.centerIn: parent
    sourceComponent: isVertical ? verticalContent : horizontalContent
    
    Component {
      id: horizontalContent
      Row {
        spacing: 4
        
        Text {
          text: root.text
          color: Colors.bg
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
          text: root.icon
          color: Colors.bg
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
    
    Component {
      id: verticalContent
      Column {
        spacing: 2
        
        Text {
          text: root.icon
          color: Colors.bg
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          text: root.text
          color: Colors.bg
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize * 0.9
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
  }
  
  ToolTip {
    id: tip
    visible: area.containsMouse
    delay: 200
    timeout: 10000
    text: root.tooltip
  }
  
  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
