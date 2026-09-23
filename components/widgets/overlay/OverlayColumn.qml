pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

// One column of a Custom view: its cells stacked top to bottom
ColumnLayout {
  id: root

  // { cells: [...] }
  required property var columnConfig

  spacing: OverlayConfig.cardSpacing

  Repeater {
    model: root.columnConfig.cells ?? []

    OverlayCell {
      required property var modelData
      cellConfig: modelData
    }
  }
}
