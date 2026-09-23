import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.config
import qs.components.widgets.overlay
import qs.components.widgets.common
import qs.services

OverlayCard {
  id: root

  color: Theme.magenta

  property real cpuUsage: SystemManager.cpuUsage
  property real cpuTemp: SystemManager.cpuTemp

  Component.onCompleted: SystemManager.acquire(root, {
    "metrics": ["cpu", "cpuTemp"]
  })
  Component.onDestruction: SystemManager.release(root)

  SystemMonitor {
    anchors.fill: parent
    anchors.margins: OverlayConfig.cardPadding

    label: "CPU"
    iconText: ""
    iconColor: Theme.background
    percentage: root.cpuUsage
    temperature: root.cpuTemp
  }
}
