pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.widgets.overlay

// Bar editor: bar tabs and the selected bar's own settings
Item {
  implicitWidth: OverlayConfig.cardUnit
  implicitHeight: OverlayConfig.span(4)

  PanelCard {
    title: "Bar Editor"
    dirty: BarManager.isDirty
    onSave: BarManager.saveChanges()
    onReset: BarManager.resetChanges()

    headerExtras: BarTabStrip {
      Layout.fillWidth: true
    }

    BarFieldsForm {
      Layout.fillWidth: true
      bar: BarManager.selectedBar()
    }
  }
}
