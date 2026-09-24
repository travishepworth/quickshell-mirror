pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.views.barEditor

// Arranges the Bar Editor's 3 columns (settings, modules, preview) so the
// preview sits where the real bar would sit relative to the other two:
// to the left/right of them for a Left/Right bar, above/below them for a
// Top/Bottom bar.
BaseView {
  id: root

  readonly property string location: BarManager.selectedBar()?.location || "Top"

  Loader {
    sourceComponent: {
      switch (root.location) {
      case "Left":
        return leftLayout;
      case "Right":
        return rightLayout;
      case "Bottom":
        return bottomLayout;
      default:
        return topLayout;
      }
    }
  }

  Component {
    id: leftLayout
    RowLayout {
      spacing: OverlayConfig.cardSpacing
      BarPreview {
        Layout.fillHeight: true
      }
      BarFieldsPanel {
        implicitWidth: root.grid.unit
        implicitHeight: root.grid.span(4)
      }
      BarWidgetsPanel {
        implicitWidth: root.grid.unit
        implicitHeight: root.grid.span(4)
      }
    }
  }

  Component {
    id: rightLayout
    RowLayout {
      spacing: OverlayConfig.cardSpacing
      BarFieldsPanel {
        implicitWidth: root.grid.unit
        implicitHeight: root.grid.span(4)
      }
      BarWidgetsPanel {
        implicitWidth: root.grid.unit
        implicitHeight: root.grid.span(4)
      }
      BarPreview {
        Layout.fillHeight: true
      }
    }
  }

  Component {
    id: topLayout
    ColumnLayout {
      spacing: OverlayConfig.cardSpacing
      BarPreview {
        Layout.fillWidth: true
      }
      RowLayout {
        spacing: OverlayConfig.cardSpacing
        BarFieldsPanel {
          implicitWidth: root.grid.unit
          implicitHeight: root.grid.span(4)
        }
        BarWidgetsPanel {
          implicitWidth: root.grid.unit
          implicitHeight: root.grid.span(4)
        }
      }
    }
  }

  Component {
    id: bottomLayout
    ColumnLayout {
      spacing: OverlayConfig.cardSpacing
      RowLayout {
        spacing: OverlayConfig.cardSpacing
        BarFieldsPanel {
          implicitWidth: root.grid.unit
          implicitHeight: root.grid.span(4)
        }
        BarWidgetsPanel {
          implicitWidth: root.grid.unit
          implicitHeight: root.grid.span(4)
        }
      }
      BarPreview {
        Layout.fillWidth: true
      }
    }
  }
}
