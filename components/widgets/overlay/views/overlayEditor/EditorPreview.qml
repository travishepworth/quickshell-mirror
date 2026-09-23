pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common
import qs.components.widgets.overlay

// The selected Custom view, drawn small: each cell as placeholder tiles,
// with a full-size strip above it to pick its layout. Geometry is scaled
// by hand (not Item.scale) so text and controls stay crisp.
OverlayCard {
  id: root

  // Width range; within it the preview is as wide as its content at the
  // scale that fits the height (set by OverlayEditor, as is implicitHeight)
  property real minWidth: OverlayConfig.cardUnit
  property real maxWidth: OverlayConfig.span(8)

  readonly property var view: OverlayManager.selectedView()
  readonly property bool isCustom: root.view?.type === "Custom"
  readonly property var columns: root.isCustom ? (root.view.columns ?? []) : []

  readonly property real stripHeight: Widget.height + Widget.spacing
  readonly property real gap: OverlayConfig.cardSpacing
  readonly property real inset: Widget.padding * 2

  // Unscaled size of each column as it flows its cells (see OverlayColumn);
  // each flow row also gets a layout strip, which doesn't scale
  readonly property var flows: root.columns.map(col => OverlayConfig.columnFlow(col.cells))
  readonly property int maxRows: Math.max(0, ...root.flows.map(flow => flow.rows))

  readonly property real fullWidth: root.flows.reduce((sum, flow) => sum + flow.width, 0) + Math.max(0, root.columns.length - 1) * root.gap
  readonly property real fullHeight: Math.max(0, ...root.flows.map(flow => flow.height))
  readonly property real availWidth: root.maxWidth - root.inset * 2
  readonly property real availHeight: root.implicitHeight - root.inset * 2 - root.maxRows * root.stripHeight
  readonly property real scaleFactor: root.fullWidth > 0 && root.fullHeight > 0 ? Math.min(1, root.availWidth / root.fullWidth, root.availHeight / root.fullHeight) : 1

  anchors.fill: undefined
  implicitWidth: Math.min(root.maxWidth, Math.max(root.minWidth, contentRow.implicitWidth + root.inset * 2))
  border.color: Theme.border

  StyledText {
    anchors.centerIn: parent
    width: parent.width - root.inset * 2
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    visible: !root.isCustom
    text: root.view ? "A fixed page: nothing to lay out." : "No pages yet: add one with + page"
    opacity: 0.6
  }

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: root.gap * root.scaleFactor

    Repeater {
      model: root.columns

      Flow {
        id: column
        required property int index
        required property var modelData
        // Half a pixel of slack so float rounding doesn't wrap a cell early
        width: root.flows[column.index].width * root.scaleFactor + 0.5
        spacing: root.gap * root.scaleFactor

        Repeater {
          model: column.modelData.cells ?? []

          Column {
            id: cellBox
            required property int index
            required property var modelData
            spacing: Widget.spacing

            RowLayout {
              width: previewCell.implicitWidth
              height: Widget.height
              spacing: Widget.spacing / 2

              SchemaComboBox {
                label: ""
                options: Object.keys(OverlayConfig.layouts)
                currentValue: cellBox.modelData.layout
                onSelectionChanged: value => OverlayManager.setCellLayout(column.index, cellBox.index, value)
              }

              EditorButton {
                iconText: "×"
                tooltipText: "Remove cell"
                hoverColor: Theme.error
                onClicked: OverlayManager.removeCell(column.index, cellBox.index)
              }
            }

            PreviewCell {
              id: previewCell
              cellConfig: cellBox.modelData
              columnIndex: column.index
              cellIndex: cellBox.index
              scaleFactor: root.scaleFactor
            }
          }
        }
      }
    }
  }
}
