pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config

Item {
  id: cell

  readonly property int requiredVerticalCells: 1
  readonly property int requiredHorizontalCells: 1

  property alias topCell: topContainer.data
  property alias bottomleftCell: bottomLeftContainer.data
  property alias bottomRightCell: bottomRightContainer.data

  implicitWidth: cellLayout.implicitWidth
  implicitHeight: cellLayout.implicitHeight

  GridLayout {
    id: cellLayout
    Layout.preferredHeight: OverlayConfig.cardUnit
    Layout.preferredWidth: OverlayConfig.cardUnit
    columnSpacing: OverlayConfig.cardSpacing
    rowSpacing: OverlayConfig.cardSpacing
    columns: 2
    rows: 2

    Item {
      id: topContainer
      Layout.columnSpan: 2
      Layout.preferredWidth: OverlayConfig.cardUnit
      Layout.preferredHeight: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
    }
    Item {
      id: bottomLeftContainer
      Layout.preferredWidth: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      Layout.preferredHeight: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
    }
    Item {
      id: bottomRightContainer
      Layout.preferredWidth: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      Layout.preferredHeight: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
    }
  }
}
