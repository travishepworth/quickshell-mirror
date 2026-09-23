pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.config
import qs.components.widgets.bar

Scope {
  id: root

  property int barHeight: Bar.extent
  property int barWidth: Bar.vertical ? Bar.extent : 0
  property color backgroundColor: Theme.background
  property color foregroundColor: Theme.foreground

  Variants {
    // Keyed on the stable bar id so a config reload rebinds the existing
    // PanelWindow instead of recreating it. Recreating appends the layer
    // surface after the borders, which then claim the edge exclusive zone first.
    model: Bar.bars.map(b => b.id)
    delegate: BarPanel {
      required property string modelData
      barConfig: Bar.bars.find(b => b.id === modelData) ?? barConfig
    }
  }
}
