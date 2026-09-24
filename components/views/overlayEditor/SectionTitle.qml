import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

// Bold section heading inside an overlay editor panel
StyledText {
  Layout.fillWidth: true
  elide: Text.ElideRight
  textSize: Appearance.fontSize + 2
  font.bold: true
}
