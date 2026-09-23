pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

import qs.components.widgets.overlay.modules.settings

ColumnLayout {
  spacing: OverlayConfig.cardSpacing

  property int requiredVerticalCells: 2
  property int requiredHorizontalCells: 2

  Item {
    id: cell

    readonly property int requiredVerticalCells: 1
    readonly property int requiredHorizontalCells: 2

    // implicitWidth: OverlayConfig.cardUnit * 2 + OverlayConfig.cardSpacing
    implicitHeight: OverlayConfig.cardUnit * 2 + OverlayConfig.cardSpacing
    implicitWidth: OverlayConfig.cardUnit
    // implicitHeight: OverlayConfig.cardUnit

    FullSettings {}
  }
}

