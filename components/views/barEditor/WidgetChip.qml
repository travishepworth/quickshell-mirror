pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

// One bar widget in the editor: its type's icon and name, as a pill. With
// a `payload`, pressing and moving it starts a drag on `dragLayer`; a
// click without moving is `clicked`.
Rectangle {
  id: root

  // The DragLayer that carries it and names the types
  required property var dragLayer
  property string type: ""
  // The widget's own `visible: false` (kept in config, not shown on the bar)
  property bool hiddenWidget: false
  property bool selected: false
  // The short type name, for narrow places
  property bool compact: false
  // Left in place, faded, while it's being carried
  property bool faded: false
  // What dragging it carries ({ kind, zone, index, type }); null: it can't be dragged
  property var payload: null

  signal clicked

  implicitWidth: row.implicitWidth + Widget.padding * 2
  implicitHeight: Widget.height + Widget.padding / 2
  radius: Appearance.borderRadius
  color: root.selected ? Theme.accent : (area.containsMouse ? Theme.backgroundHighlight : Theme.background)
  border.color: root.selected ? Theme.accent : Theme.border
  border.width: 1
  opacity: root.faded ? 0.3 : (root.hiddenWidget ? 0.6 : 1)

  Behavior on color {
    ColorAnimation {
      duration: Appearance.animFast
    }
  }

  RowLayout {
    id: row
    anchors.fill: parent
    anchors.leftMargin: root.compact ? Widget.padding / 2 : Widget.padding
    anchors.rightMargin: root.compact ? Widget.padding / 2 : Widget.padding
    spacing: root.compact ? Widget.spacing / 2 : Widget.spacing

    StyledText {
      text: root.dragLayer.icon(root.type)
      textColor: root.selected ? Theme.background : Theme.accent
      Layout.preferredWidth: Appearance.fontSize * 1.3
    }

    StyledText {
      text: root.compact ? root.dragLayer.shortLabel(root.type) : root.dragLayer.label(root.type)
      textColor: root.selected ? Theme.background : Theme.foreground
      font.bold: root.selected
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    // Hidden on the bar
    StyledText {
      visible: root.hiddenWidget
      text: String.fromCodePoint(0xF0209)
      textColor: root.selected ? Theme.background : Theme.foreground
      opacity: 0.7
    }
  }

  MouseArea {
    id: area

    property real pressX: 0
    property real pressY: 0
    property bool dragged: false

    anchors.fill: parent
    hoverEnabled: true
    // Keep the pointer while carrying it over a scrolling lane
    preventStealing: true
    cursorShape: area.dragged ? Qt.ClosedHandCursor : (root.payload ? Qt.OpenHandCursor : Qt.PointingHandCursor)

    onPressed: mouse => {
      area.pressX = mouse.x;
      area.pressY = mouse.y;
      area.dragged = false;
    }
    onPositionChanged: mouse => {
      if (!area.pressed || !root.payload)
        return;
      if (!area.dragged && Math.hypot(mouse.x - area.pressX, mouse.y - area.pressY) > 6) {
        area.dragged = true;
        root.dragLayer.begin(root.payload, root, area.pressX, area.pressY);
      }
      if (area.dragged)
        root.dragLayer.move(root, mouse.x, mouse.y);
    }
    // `dragged` stays set until the next press, so the click that follows
    // a drop is ignored
    onReleased: {
      if (area.dragged)
        root.dragLayer.end();
    }
    onCanceled: {
      if (area.dragged)
        root.dragLayer.cancel();
      area.dragged = false;
    }
    onClicked: {
      if (!area.dragged)
        root.clicked();
    }
  }
}
