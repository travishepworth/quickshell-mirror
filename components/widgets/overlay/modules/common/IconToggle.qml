import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

// A toggle tile: icon over a label, filled with the accent while active
Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property bool active: false
  // Hide the label (compact tiles)
  property bool showLabel: true

  signal clicked

  radius: Appearance.borderRadius
  color: root.active ? Theme.accent : area.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
  border.color: root.active ? Theme.accent : Theme.border
  border.width: Appearance.borderWidth

  Behavior on color {
    ColorAnimation {
      duration: Appearance.animFast
    }
  }

  ColumnLayout {
    anchors.centerIn: parent
    width: parent.width - 8
    spacing: 2

    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: root.icon
      textColor: root.active ? Theme.background : Theme.foreground
      textSize: Math.max(Appearance.fontSize, Math.min(root.width, root.height) * 0.28)
    }
    StyledText {
      visible: root.showLabel
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      text: root.label
      textColor: root.active ? Theme.background : Theme.foreground
      textSize: Appearance.fontSize - 2
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
