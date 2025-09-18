// ===== CPU.qml =====
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
  property string icon: ""
  
  // Dynamic dimensions
  implicitWidth: isVertical ? App.Settings.widgetHeight : (contentLoader.item ? contentLoader.item.implicitWidth + App.Settings.widgetPadding * 2 : 60)
  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + App.Settings.widgetPadding * 2 : App.Settings.widgetHeight) : App.Settings.widgetHeight
  
  // Previous counters
  property double _prevIdle: -1
  property double _prevTotal: -1
  
  function readFile(url) {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open("GET", url, false);
      xhr.send();
      return xhr.status === 0 || xhr.status === 200 ? xhr.responseText : "";
    } catch (e) {
      return "";
    }
  }
  
  function update() {
    const stat = readFile("file:///proc/stat");
    if (!stat) return;
    
    const line = stat.split("\n")[0];
    const nums = line.trim().split(/\s+/).slice(1).map(Number);
    if (nums.length < 4) return;
    
    const user = nums[0], nice = nums[1], system = nums[2], idle = nums[3];
    const iowait = nums[4] || 0, irq = nums[5] || 0, softirq = nums[6] || 0, steal = nums[7] || 0;
    const idleAll = idle + iowait;
    const nonIdle = user + nice + system + irq + softirq + steal;
    const total = idleAll + nonIdle;
    
    if (_prevTotal >= 0 && _prevIdle >= 0) {
      const totald = total - _prevTotal;
      const idled = idleAll - _prevIdle;
      const usage = totald > 0 ? Math.max(0, Math.min(100, ((totald - idled) / totald) * 100)) : 0;
      text = usage.toFixed(0) + "%";
      icon = "";
      tooltip = "CPU usage: " + usage.toFixed(1) + "%";
    }
    
    _prevTotal = total;
    _prevIdle = idleAll;
  }
  
  Rectangle {
    anchors.fill: parent
    color: Colors.orange
    radius: App.Settings.borderRadius
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
          text: root.text
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
