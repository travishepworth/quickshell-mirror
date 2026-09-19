pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

ColumnLayout {
  id: root
  required property string label
  required property string currentConfigValue
  property string value: root.currentConfigValue
  property string placeholderText: ""
  property string description: ""
  property var pattern: null
  property int minLength: 0
  property int maxLength: 999

  onCurrentConfigValueChanged: {
    textEntry.text = root.currentConfigValue;
  }

  Layout.fillWidth: true
  spacing: 4

  StyledText {
    text: root.label
    Layout.fillWidth: true
  }

  StyledTextEntry {
    id: textEntry
    Layout.fillWidth: true
    Layout.preferredHeight: Widget.height
    text: root.currentConfigValue
    placeholderText: root.placeholderText

    input.onTextChanged: {
      if (input.text.length >= root.minLength && input.text.length <= root.maxLength) {
        if (root.pattern === null || new RegExp(root.pattern).test(input.text)) {
          root.value = input.text;
        }
      }
    }
  }

  StyledText {
    visible: root.description !== ""
    text: root.description
    opacity: 0.7
    textSize: Appearance.fontSize - 2
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }
}
