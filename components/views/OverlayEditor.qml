pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.components.views.overlayEditor

// The overlay editor: always the last page (pinned by OverlayPages, after
// the Themes page; not part of config). The pages on the left; the
// selected page drawn on a canvas (drag modules, cells and columns
// around) above what's selected there, or the library to drag from.
// Edits go through OverlayManager's draft until saved.
BaseView {
  id: root

  readonly property real pageHeight: root.grid.span(4)
  readonly property real sideWidth: root.grid.unit * 0.8
  // As wide as the page allows, within reason
  readonly property real mainWidth: Math.max(root.grid.unit * 1.8, Math.min(root.grid.unit * 2.8, root.grid.availableWidth - root.sideWidth - OverlayConfig.cardSpacing * 3))
  readonly property real canvasHeight: Math.round((root.pageHeight - OverlayConfig.cardSpacing) * 0.6)

  Component.onCompleted: OverlayManager.ensureLoaded()

  EditorDragLayer {
    id: dragLayer
    implicitWidth: root.sideWidth + OverlayConfig.cardSpacing + root.mainWidth
    implicitHeight: root.pageHeight

    PagesPanel {
      x: 0
      y: 0
      width: root.sideWidth
      height: root.pageHeight
      dragLayer: dragLayer
    }

    Item {
      x: root.sideWidth + OverlayConfig.cardSpacing
      y: 0
      width: root.mainWidth
      height: root.canvasHeight

      PageCanvas {
        dragLayer: dragLayer
      }
    }

    EditorInspector {
      x: root.sideWidth + OverlayConfig.cardSpacing
      y: root.canvasHeight + OverlayConfig.cardSpacing
      width: root.mainWidth
      height: root.pageHeight - root.canvasHeight - OverlayConfig.cardSpacing
      dragLayer: dragLayer
    }
  }
}
