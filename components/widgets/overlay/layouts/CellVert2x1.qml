pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config

Item {
  id: cell

  readonly property int requiredVerticalCells: 1
  readonly property int requiredHorizontalCells: 1

  property alias rightCell: rightContainer.data
  property alias topLeftCell: topLeftContainer.data
  property alias bottomLeftCell: bottomLeftContainer.data

  implicitWidth: cellLayout.implicitWidth
  implicitHeight: cellLayout.implicitHeight

  GridLayout {
    id: cellLayout
    Layout.preferredHeight: OverlayConfig.cardUnit
    Layout.preferredWidth: OverlayConfig.cardUnit
    // Layout.margins: OverlayConfig.cardPadding
    columnSpacing: OverlayConfig.cardSpacing
    rowSpacing: OverlayConfig.cardSpacing
    columns: 2
    rows: 2

    Item {
      id: topLeftContainer
      Layout.preferredWidth: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      Layout.preferredHeight: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      clip: true
    }
    Item {
      id: rightContainer
      Layout.rowSpan: 2
      Layout.preferredWidth: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      Layout.preferredHeight: OverlayConfig.cardUnit + 2 //TODO: What is this number
      clip: true
    }
    Item {
      id: bottomLeftContainer
      Layout.preferredWidth: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      Layout.preferredHeight: (OverlayConfig.cardUnit - OverlayConfig.cardSpacing) / 2
      clip: true
    }
  }
}
