import QtQuick
import Quickshell
import Quickshell.Io

import qs.services
import qs.components.widgets

IconTextWidget {
  id: root
  icon: ""
  backgroundColor: Colors.accent

  // Open swaync panel; run detached so Quickshell isn’t tied to its lifecycle.
  Process {
    id: openPanel
    command: ["swaync-client","-op","-sw"]
    // we only want a one-shot detached spawn:
    onStarted: { openPanel.startDetached(); openPanel.running = false }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: openPanel.running = true
  }
}

