pragma ComponentBehavior: Bound

import QtQuick

import qs.config

// An icon followed by a label, laid along the bar's main axis (the label is
// rotated on a vertical bar). Reports the size it needs to show everything
// as its implicit size; given less, the label elides to fit, so its length
// is decided by the bar layout rather than by character counts.
BaseWidget {
  id: root

  property string icon: ""
  property string text: ""
  property real textScale: 1.0
  property real iconScale: 1.0
  property bool showText: true
  property bool showIcon: true
  property real spacing: 6

  readonly property bool _hasIcon: showIcon && icon !== ""
  readonly property string displayText: showText ? (text || "—") : ""
  readonly property bool _hasText: displayText !== ""
  readonly property real _gap: _hasIcon && _hasText ? spacing : 0

  // Icon footprint along the main axis; the label's is its (unrotated) width
  readonly property real _iconLength: _hasIcon ? (isVertical ? iconLabel.implicitHeight : iconLabel.implicitWidth) : 0
  readonly property real _naturalLength: _iconLength + _gap + (_hasText ? textLabel.implicitWidth : 0)

  implicitWidth: isVertical ? Widget.height : _naturalLength + padding * 2
  implicitHeight: isVertical ? _naturalLength + padding * 2 : Widget.height

  // Centered run of icon + label, at most the space inside the padding
  Item {
    id: run
    anchors.centerIn: parent
    readonly property real available: (root.isVertical ? root.height : root.width) - root.padding * 2
    readonly property real length: Math.max(0, Math.min(root._naturalLength, available))
    width: root.isVertical ? root.width : length
    height: root.isVertical ? length : root.height

    Text {
      id: iconLabel
      visible: root._hasIcon
      x: root.isVertical ? Math.round((run.width - width) / 2) : 0
      y: root.isVertical ? 0 : Math.round((run.height - height) / 2)
      color: Theme.background
      text: root.icon
      font.family: Appearance.fontFamily
      font.pixelSize: Appearance.fontSize * root.iconScale
    }

    // Space left for the label along the main axis
    Item {
      id: textSlot
      visible: root._hasText
      readonly property real start: root._iconLength + root._gap
      x: root.isVertical ? 0 : start
      y: root.isVertical ? start : 0
      width: root.isVertical ? run.width : Math.max(0, run.length - start)
      height: root.isVertical ? Math.max(0, run.length - start) : run.height

      Text {
        id: textLabel
        anchors.centerIn: parent
        width: root.isVertical ? textSlot.height : textSlot.width
        rotation: root.isVertical ? -90 : 0
        color: Theme.background
        text: root.displayText
        elide: Text.ElideRight
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize * root.textScale
      }
    }
  }
}
