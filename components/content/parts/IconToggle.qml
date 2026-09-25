import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components.reusable

// A toggle (or action) tile: icon over a label, filled with activeColor
// while active. The label shows only where it fits whole; otherwise the
// tile is icon-only with the label as a tooltip.
Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool active: false
  property color activeColor: Theme.accent
  // Allow the label at all (off: always icon-only)
  property bool showLabel: true

  signal clicked

  readonly property real _iconSize: Math.max(Appearance.fontSize, Math.min(root.width, root.height) * (root._labelShown ? 0.26 : 0.34))
  readonly property bool _labelShown: root.showLabel && root.label !== "" && labelMetrics.advanceWidth <= root.width - Widget.spacing * 2 && root.height >= Appearance.fontSize * 4.5

  radius: Appearance.borderRadius
  color: root.active ? root.activeColor : area.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
  border.color: root.active ? root.activeColor : Theme.border
  border.width: Appearance.borderWidth

  Behavior on color {
    ColorAnimation {
      duration: Appearance.animFast
    }
  }

  TextMetrics {
    id: labelMetrics
    text: root.label
    font.family: Appearance.fontFamily
    font.pixelSize: Appearance.fontSize - 1
  }

  ColumnLayout {
    anchors.centerIn: parent
    width: parent.width - Widget.spacing * 2
    spacing: Widget.spacing / 2

    StyledIcon {
      Layout.alignment: Qt.AlignHCenter
      text: root.icon
      textColor: root.active ? Theme.background : Theme.foreground
      textSize: root._iconSize
    }
    StyledText {
      visible: root._labelShown
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      text: root.label
      textColor: root.active ? Theme.background : Theme.foreground
      textSize: Appearance.fontSize - 1
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  LazyLoader {
    active: area.containsMouse && !root._labelShown && root.label !== ""
    StyledToolTip {
      target: root
      text: root.label
    }
  }
}
