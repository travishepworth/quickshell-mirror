import QtQuick

import qs.services
import qs.config

Rectangle {
  id: btn

  property string glyph: ""
  property bool emphasized: false
  property int size: 36
  signal clicked

  width: size
  height: size
  radius: size / 2
  opacity: enabled ? 1.0 : 0.4
  color: !enabled ? Theme.backgroundAlt
         : emphasized ? Theme.accent
         : (btnMouseArea.containsMouse ? Theme.accentAlt : Theme.backgroundAlt)
  scale: btnMouseArea.pressed ? 0.92 : 1.0

  Behavior on color { ColorAnimation { duration: 100 } }
  Behavior on scale { NumberAnimation { duration: 80 } }

  Text {
    anchors.centerIn: parent
    text: btn.glyph
    color: btn.emphasized ? Theme.background : Theme.foregroundAlt
    font.family: Appearance.fontFamily
    font.pixelSize: btn.size * 0.42
  }

  MouseArea {
    id: btnMouseArea
    anchors.fill: parent
    enabled: btn.enabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: btn.clicked()
  }
}
