pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.services
import qs.components.methods
import qs.components.reusable
import qs.components.widgets.overlay

// Stand-in for a module in the editor preview: its name (plus a hint for
// modules whose look depends on their properties), clickable to edit the
// slot. Positioned by PreviewCell.
Item {
  id: root

  // { type, properties } or null for an empty slot
  property var module
  property bool selected: false
  // False when the module doesn't fit this slot's shape
  property bool fits: true

  signal clicked

  readonly property var typeInfo: OverlayConfig.availableModuleTypes.find(t => t.type === root.module?.type) ?? null
  readonly property bool isSwatch: root.module?.type === "ColorSwatch"
  readonly property color fill: root.isSwatch ? Theme.resolveColor(root.module.properties?.color) : root.module ? Theme.background : "transparent"
  readonly property color ink: root.isSwatch ? Utils.getContrastColor(root.fill) : Theme.foreground
  readonly property string detail: {
    const props = root.module?.properties ?? {};
    switch (root.module?.type) {
    case "ColorSwatch":
      return props.color ?? "";
    case "Volume":
      return props.targetApplication || "system";
    }
    return "";
  }

  OverlayCard {
    color: root.fill
    border.color: !root.fits ? Theme.error : root.selected ? Theme.accent : Theme.border
    border.width: root.selected || !root.fits ? Math.max(Appearance.borderWidth, 2) * 2 : Appearance.borderWidth
    opacity: root.module || root.selected || area.containsMouse ? 1 : 0.5

    Column {
      anchors.centerIn: parent
      width: parent.width - 8
      spacing: 2

      StyledText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.module ? (root.typeInfo?.label ?? root.module.type) : "+"
        textColor: root.ink
        textSize: root.module ? Appearance.fontSize - 2 : Appearance.fontSize + 4
        font.bold: true
      }

      StyledText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        visible: text !== ""
        text: root.fits ? root.detail : "doesn't fit"
        textColor: root.ink
        textSize: Appearance.fontSize - 4
        opacity: 0.7
      }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.clicked()
    }
  }
}
