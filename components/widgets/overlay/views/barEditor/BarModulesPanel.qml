pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.widgets.overlay

// Bar editor: the selected bar's widgets, per section
Item {
  implicitWidth: OverlayConfig.cardUnit
  implicitHeight: OverlayConfig.span(4)

  PanelCard {
    title: "Modules"
    showActions: false

    LayoutConfig {
      Layout.fillWidth: true
    }
  }
}
