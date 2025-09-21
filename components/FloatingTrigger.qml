import QtQuick
import Quickshell
import qs.services

PanelWindow {
  id: root

  property var popouts: null

  anchors {
    top: true
    left: !Settings.rightVerticalBar
    right: Settings.rightVerticalBar
  }

  width: Settings.resolutionWidth / 3
  height: 40
  color: "transparent"

  // PanelWindow.exclusionMode: PanelWindow.ExclusionMode.Ignore

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true

    onEntered: {
      hoverTimer.restart();
    }

    onExited: {
      hoverTimer.stop();
    }
  }

  Timer {
    id: hoverTimer
    interval: 300

    onTriggered: {
      if (root.popouts && panel) {
        console.log("anchor", root.x, root.y, root.width, root.height);
        root.popouts.openPopout(panel, "media-player", {
          monitor: root.monitor,
          activeId: root.monitor?.activeWorkspace?.id ?? 1,
          anchorX: 0 + Settings.barHeight,
          anchorY: 0 + Settings.barHeight,
          anchorWidth: root.width,
          anchorHeight: root.height
        });
      }
      // if (popouts) {
      // popouts.openPopout("full-menu", {})
      // }
    }
  }
}
