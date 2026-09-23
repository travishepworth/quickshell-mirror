import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.config
import qs.components.widgets.overlay
import qs.services
import qs.components.widgets.common

OverlayCard {
  id: root

  color: Theme.blue

  property real gpuUsage: SystemManager.gpuUsage
  property real gpuTemp: SystemManager.gpuTemp

  Component.onCompleted: SystemManager.acquire(root, {
    "metrics": ["gpu"]
  })
  Component.onDestruction: SystemManager.release(root)

  Timer {
    id: timer
    function setTimeout(callback, delay) {
      timer.interval = delay;
      timer.repeat = false;
      timer.triggered.connect(callback);
      timer.start();
    }
  }

  SystemMonitor {
    anchors.fill: parent
    anchors.margins: OverlayConfig.cardPadding

    label: "GPU"
    iconText: "◆"
    percentage: root.gpuUsage
    temperature: root.gpuTemp
  }
}
