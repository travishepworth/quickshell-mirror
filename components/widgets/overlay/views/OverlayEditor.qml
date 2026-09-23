pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.components.widgets.overlay.views.overlayEditor

// The overlay editor: always the last page (pinned by OverlayTabWrapper,
// not part of config). Edits go through OverlayManager's sandbox.
BaseView {
  id: view

  readonly property real panelWidth: OverlayConfig.cardUnit * 0.9
  readonly property real editorHeight: OverlayConfig.span(3.5)

  StructurePanel {
    implicitWidth: view.panelWidth
    implicitHeight: view.editorHeight
  }
  SlotPanel {
    implicitWidth: view.panelWidth
    implicitHeight: view.editorHeight
  }
  EditorPreview {
    minWidth: view.panelWidth
    // Grows with the view being edited, up to what's left of the screen
    maxWidth: Math.max(view.panelWidth, (view.screen?.width ?? 1920) - view.panelWidth * 2 - OverlayConfig.cardSpacing * 8)
    implicitHeight: view.editorHeight
  }
}
