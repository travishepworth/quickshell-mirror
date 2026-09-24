pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services

// A cell of the selected view drawn at `scaleFactor`, its slots placed
// from the same OverlayConfig.layouts data OverlayCell uses
Item {
  id: root

  required property var cellConfig
  required property int columnIndex
  required property int cellIndex
  required property real scaleFactor

  readonly property var layout: OverlayConfig.layouts[root.cellConfig.layout] ?? {
    "cols": 2,
    "rows": 2,
    "slots": {}
  }
  readonly property real step: (OverlayConfig.halfUnit + OverlayConfig.cardSpacing) * root.scaleFactor

  implicitWidth: OverlayConfig.span(root.layout.cols) * root.scaleFactor
  implicitHeight: OverlayConfig.span(root.layout.rows) * root.scaleFactor

  Repeater {
    model: Object.keys(root.layout.slots)

    PlaceholderTile {
      id: tile
      required property string modelData
      readonly property var rect: root.layout.slots[tile.modelData]
      readonly property var sel: OverlayManager.selectedSlot

      x: tile.rect[0] * root.step
      y: tile.rect[1] * root.step
      width: OverlayConfig.span(tile.rect[2]) * root.scaleFactor
      height: OverlayConfig.span(tile.rect[3]) * root.scaleFactor

      module: root.cellConfig.slots?.[tile.modelData] ?? null
      fits: !tile.module || OverlayConfig.fits(tile.module.type, tile.rect)
      selected: tile.sel !== null && tile.sel.column === root.columnIndex && tile.sel.cell === root.cellIndex && tile.sel.slot === tile.modelData
      onClicked: OverlayManager.selectSlot(root.columnIndex, root.cellIndex, tile.modelData)
    }
  }
}
