pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.services
import qs.config
import qs.components.widgets.bar as Components

Scope {
  id: root

  property int barHeight: Settings.barHeight
  property int barWidth: Settings.verticalBar ? Settings.barHeight : 0
  property color backgroundColor: Colors.bg
  property color foregroundColor: Colors.fg

  Variants {
    model: Quickshell.screens
    delegate: Component {
      Components.BarPanel {
        barHeight: root.barHeight
        barWidth: root.barWidth
      }
    }
  }
}
