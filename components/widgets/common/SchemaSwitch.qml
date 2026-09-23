// SchemaSwitch.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

ColumnLayout {
  id: root
  required property string label
  required property bool checked
  property string description: ""

  signal toggled(bool newValue)

  Layout.fillWidth: true
  spacing: Widget.spacing

  StyledText {
    text: I18n.tr(root.label)
    Layout.fillWidth: true
  }

  StyledSwitch {
    checked: root.checked
    onToggled: root.toggled(checked)
  }

  StyledText {
    visible: root.description !== ""
    text: I18n.tr(root.description)
    opacity: 0.7
    textSize: Appearance.fontSize - 2
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.columnSpan: 2
  }
}
