pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.content.base

// Bar editor: the selected bar's widgets, per section
Item {
  // Sized by BarEditor from the overlay's card grid

  TitledCard {
    title: I18n.tr("Modules")
    showActions: false

    LayoutConfig {
      Layout.fillWidth: true
    }
  }
}
