import QtQuick
import QtQuick.Layouts
import qs.config
Item {
  id: cell

  readonly property int requiredVerticalCells: 1
  readonly property int requiredHorizontalCells: 1

  default property alias cell: container.data

  implicitWidth: cellLayout.implicitWidth
  implicitHeight: cellLayout.implicitHeight

  GridLayout {
    id: cellLayout
    Layout.preferredHeight: OverlayConfig.cardUnit
    Layout.preferredWidth: OverlayConfig.cardUnit
    columns: 1
    rows: 1
    Item {
      id: container
      Layout.preferredWidth: OverlayConfig.cardUnit
      Layout.preferredHeight: OverlayConfig.cardUnit
      clip: true
    }
  }
}
