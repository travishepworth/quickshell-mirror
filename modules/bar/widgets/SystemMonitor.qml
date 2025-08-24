import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "root:/" as App
import "root:/services" as Services

import "./systemMonitor" as SystemMonitor

Item {
  id: root
  height: App.Settings.widgetHeight

  Rectangle {
      anchors.fill: parent

    RowLayout {
      spacing: App.Settings.widgetSpacing
      anchors.margins: App.Settings.screenMargin

      SystemMonitor.Cpu {
        id: cpu
      }
      SystemMonitor.Memory {
        id: memory
      }
      SystemMonitor.Temperature {
        id: temperature
      }
    }
  }
}
