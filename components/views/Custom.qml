pragma ComponentBehavior: Bound
import QtQuick
import qs.components.hosts.overlay

// A view assembled from config: its columns laid out side by side
BaseView {
  id: root

  // viewConfig: { type: "Custom", name, columns: [...] }
  property var columns: root.viewConfig?.columns ?? []

  Repeater {
    model: root.columns

    OverlayColumn {
      required property var modelData
      columnConfig: modelData
      grid: root.grid
    }
  }
}
