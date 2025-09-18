// SystemMonitor.qml - Main Container
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "root:/" as App
import "./systemMonitor" as SystemMonitor

import qs.services

Item {
  id: root
  
  // Orientation support
  property int orientation: App.Settings.orientation  // Accept orientation from parent
  property bool isVertical: orientation === Qt.Vertical
  
  // Dynamic dimensions
  height: isVertical ? implicitHeight : App.Settings.widgetHeight
  width: isVertical ? App.Settings.widgetHeight : implicitWidth
  
  implicitWidth: isVertical ? App.Settings.widgetHeight : (layout.implicitWidth + App.Settings.screenMargin * 2)
  implicitHeight: isVertical ? (layout.implicitHeight + App.Settings.screenMargin * 2) : App.Settings.widgetHeight
  
  Rectangle {
    anchors.fill: parent
    color: "transparent"  // Or your preferred background
    
    Loader {
      id: layout
      anchors.centerIn: parent
      sourceComponent: isVertical ? columnComponent : rowComponent
      
      Component {
        id: rowComponent
        RowLayout {
          spacing: App.Settings.widgetSpacing
          
          SystemMonitor.Cpu {
            id: cpuH
            orientation: root.orientation
          }
          SystemMonitor.Memory {
            id: memoryH
            orientation: root.orientation
          }
          SystemMonitor.Temperature {
            id: temperatureH
            orientation: root.orientation
          }
        }
      }
      
      Component {
        id: columnComponent
        ColumnLayout {
          spacing: App.Settings.widgetSpacing
          
          SystemMonitor.Cpu {
            id: cpuV
            orientation: root.orientation
            Layout.alignment: Qt.AlignHCenter
          }
          SystemMonitor.Memory {
            id: memoryV
            orientation: root.orientation
            Layout.alignment: Qt.AlignHCenter
          }
          SystemMonitor.Temperature {
            id: temperatureV
            orientation: root.orientation
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }
    }
  }
}
