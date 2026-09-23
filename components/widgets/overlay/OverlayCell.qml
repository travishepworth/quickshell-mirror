pragma ComponentBehavior: Bound
import QtQuick
import qs.config

// One cell of a column: the layout named by `layout` (OverlayConfig.layouts)
// split into slots, each hosting the module configured for it.
Item {
  id: root

  // { layout, slots: { <slotName>: { type, properties } } }
  required property var cellConfig

  readonly property var layout: {
    const layout = OverlayConfig.layouts[root.cellConfig.layout];
    if (!layout)
      console.warn("Unknown overlay cell layout:", root.cellConfig.layout);
    return layout ?? {
      "cols": 0,
      "rows": 0,
      "slots": {}
    };
  }
  readonly property var slots: root.cellConfig.slots || {}

  onSlotsChanged: {
    const unknown = Object.keys(root.slots).filter(name => !(name in root.layout.slots));
    if (unknown.length > 0)
      console.warn(`Overlay cell layout ${root.cellConfig.layout} has no slot(s): ${unknown.join(", ")}`);
  }

  implicitWidth: OverlayConfig.span(root.layout.cols)
  implicitHeight: OverlayConfig.span(root.layout.rows)

  Repeater {
    model: Object.keys(root.layout.slots)

    Item {
      id: slot
      required property string modelData
      readonly property var rect: root.layout.slots[slot.modelData]

      x: slot.rect[0] * (OverlayConfig.halfUnit + OverlayConfig.cardSpacing)
      y: slot.rect[1] * (OverlayConfig.halfUnit + OverlayConfig.cardSpacing)
      width: OverlayConfig.span(slot.rect[2])
      height: OverlayConfig.span(slot.rect[3])
      clip: true

      OverlayModule {
        config: root.slots[slot.modelData]
      }
    }
  }
}
