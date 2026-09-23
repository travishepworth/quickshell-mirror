pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.reusable

// The shell every popout's content shares: its box, hover tracking for the
// wrapper's dismiss logic, and a margin-inset column its children go into.
// Content sets `margins`/`spacing`, and implicitWidth (plus implicitHeight
// if it isn't just the column's).
Item {
  id: root

  required property var wrapper
  // Inside an overlay module: no background of its own, and lists fill
  // the height it is given instead of their popout cap
  property bool embedded: false
  // Pointer over the content; `hovered` (what the wrapper reads) can add
  // more reasons to stay open, e.g. a drag in progress
  readonly property bool pointerInside: hoverHandler.hovered
  property bool hovered: pointerInside

  property int margins: 16
  property alias spacing: column.spacing
  readonly property alias body: column
  default property alias content: column.data

  implicitHeight: column.implicitHeight + margins * 2
  width: implicitWidth
  height: implicitHeight

  StyledContainer {
    anchors.fill: parent
    backgroundColor: root.embedded ? "transparent" : Theme.background
    borderWidth: 0
    borderRadius: Appearance.borderRadius + 2

    HoverHandler {
      id: hoverHandler
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: root.margins
      spacing: Widget.spacing
    }
  }
}
