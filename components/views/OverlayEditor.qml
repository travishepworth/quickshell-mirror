pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.components.views.overlayEditor

// The overlay editor: always the last page (pinned by OverlayPages, after
// the Themes page; not part of config). Edits go through OverlayManager's sandbox.
BaseView {
  id: root

  readonly property real panelWidth: root.grid.unit * 0.9
  readonly property real editorHeight: root.grid.span(3.5)

  StructurePanel {
    implicitWidth: root.panelWidth
    implicitHeight: root.editorHeight
  }
  SlotPanel {
    implicitWidth: root.panelWidth
    implicitHeight: root.editorHeight
  }
  EditorPreview {
    minWidth: root.panelWidth
    // Grows with the view being edited, up to what's left of the page
    maxWidth: Math.max(root.panelWidth, root.grid.availableWidth - root.panelWidth * 2 - OverlayConfig.cardSpacing * 2)
    implicitHeight: root.editorHeight
  }
}
