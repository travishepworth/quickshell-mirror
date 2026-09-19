pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.widgets.overlay.columns

// Arranges the Bar Editor's 3 columns (settings, modules, preview) so the
// preview sits where the real bar would sit relative to the other two:
// to the left/right of them for a Left/Right bar, above/below them for a
// Top/Bottom bar.
BaseView {
  id: view

  readonly property string location: BarManager.selectedBar()?.location || "Top"

  Loader {
    sourceComponent: {
      switch (view.location) {
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
      spacing: Menu.cardSpacing
      BarEditorPreview {
        Layout.fillHeight: true
      }
      BarEditor {}
      BarEditorLayout {}
    }
  }

  Component {
    id: rightLayout
    RowLayout {
      spacing: Menu.cardSpacing
      BarEditor {}
      BarEditorLayout {}
      BarEditorPreview {
        Layout.fillHeight: true
      }
    }
  }

  Component {
    id: topLayout
    ColumnLayout {
      spacing: Menu.cardSpacing
      BarEditorPreview {
        Layout.fillWidth: true
      }
      RowLayout {
        spacing: Menu.cardSpacing
        BarEditor {}
        BarEditorLayout {}
      }
    }
  }

  Component {
    id: bottomLayout
    ColumnLayout {
      spacing: Menu.cardSpacing
      RowLayout {
        spacing: Menu.cardSpacing
        BarEditor {}
        BarEditorLayout {}
      }
      BarEditorPreview {
        Layout.fillWidth: true
      }
    }
  }
}
