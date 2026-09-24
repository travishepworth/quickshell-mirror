pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.components.views.overlayEditor

// The overlay editor: always the last page (pinned by OverlayPages,
// not part of config). Edits go through OverlayManager's sandbox.
BaseView {
  id: root

  readonly property real panelWidth: OverlayConfig.cardUnit * 0.9
  readonly property real editorHeight: OverlayConfig.span(3.5)

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
    // Grows with the view being edited, up to what's left of the screen
    maxWidth: Math.max(root.panelWidth, (root.screen?.width ?? 1920) - root.panelWidth * 2 - OverlayConfig.cardSpacing * 8)
    implicitHeight: root.editorHeight
  }
}
