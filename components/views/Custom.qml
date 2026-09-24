pragma ComponentBehavior: Bound
import QtQuick
import qs.components.hosts.overlay

// A view assembled from config: its columns laid out side by side
BaseView {
  id: root

  // viewConfig: { type: "Custom", name, columns: [...] }

  Repeater {
    model: root.viewConfig?.columns ?? []

    OverlayColumn {
      required property var modelData
      columnConfig: modelData
      grid: root.grid
    }
  }
}
