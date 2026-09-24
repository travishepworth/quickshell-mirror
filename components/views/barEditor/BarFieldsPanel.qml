pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.content.base

// Bar editor: bar tabs and the selected bar's own settings
Item {
  // Sized by BarEditor from the overlay's card grid

  TitledCard {
    title: I18n.tr("Bar Editor")
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
