// ===== Memory.qml =====
import QtQuick 2.15
import QtQuick.Controls 2.15
import "root:/" as App

import qs.services

Item {
  id: root
  
  // Orientation support
  property int orientation: Qt.Horizontal
  property bool isVertical: orientation === Qt.Vertical
  
  property string text: ""
  property string tooltip: ""
  property string icon: " "
  property string shortText: ""  // Shorter version for vertical
  
  // Dynamic dimensions
  implicitWidth: isVertical ? App.Settings.widgetHeight : (contentLoader.item ? contentLoader.item.implicitWidth + App.Settings.widgetPadding * 2 : 80)
  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + App.Settings.widgetPadding * 2 : App.Settings.widgetHeight) : App.Settings.widgetHeight
  
  Rectangle {
    anchors.fill: parent
    color: Colors.green
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
      const percent = ((usedGB / totalGB) * 100).toFixed(0);
      
      text = usedGB.toFixed(1) + "G/" + totalGB.toFixed(1) + "G";
      shortText = usedGB.toFixed(1) + "G";
      tooltip = "Memory: " + usedGB.toFixed(2) + "G/" + totalGB.toFixed(2) + "G (" + percent + "%)";
    }
  }
  
  Timer {
    interval: 1000
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
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
          text: root.icon
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
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
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          text: root.shortText
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize * 0.9
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
