import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.config
import qs.services
import qs.components.widgets.common

Rectangle {
  id: root
  color: Theme.blue
  anchors.fill: parent
  radius: Appearance.borderRadius
  border.color: Theme.foreground
  border.width: Appearance.borderWidth
  
  property real gpuUsage: SystemManager.gpuUsage
  property real gpuTemp: SystemManager.gpuTemp
  
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
