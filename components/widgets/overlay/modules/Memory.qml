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

  color: Theme.green

  property real memUsage: SystemManager.memUsage
  property real memTemp: -1  // No memory temperature sensor

  Component.onCompleted: SystemManager.acquire(root, {
    "metrics": ["mem"]
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

    label: "Memory"
    iconText: "▦"
    percentage: root.memUsage
    temperature: root.memTemp
  }
}
