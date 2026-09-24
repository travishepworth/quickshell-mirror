pragma ComponentBehavior: Bound
import QtQuick
import qs.components.hosts.overlay

// A view assembled from config: its columns laid out side by side
BaseView {
  id: view

  // viewConfig: { type: "Custom", name, columns: [...] }

  Repeater {
    model: view.viewConfig?.columns ?? []

    OverlayColumn {
      required property var modelData
      columnConfig: modelData
    }
  }
}
