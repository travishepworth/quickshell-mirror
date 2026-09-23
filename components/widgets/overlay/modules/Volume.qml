import QtQuick

import qs.config
import qs.components.widgets.overlay
import qs.components.widgets.common

// Volume slider for one app's stream (or the system volume when no app is set)
// properties: { targetApplication, orientation: "Vertical" | "Horizontal" }
OverlayCard {
  id: root

  border.width: 3

  PipewireVolumeBar {
    anchors.centerIn: parent
    targetApplication: root.properties.targetApplication ?? ""
    useSystemVolume: !root.properties.targetApplication
    orientation: root.properties.orientation === "Horizontal" ? Qt.Horizontal : Qt.Vertical
    iconSource: ""
  }
}
