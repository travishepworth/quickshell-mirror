pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

// i18n: keys from the schema (titles, descriptions)
// One group of settings (a section's own fields, or one nested object) as
// a card: title, help text, then its rows
StyledContainer {
  id: root

  // A SchemaLayout.groups() entry, rows possibly filtered by a search
  required property var group
  // Provides valueAt(path) and edited(path, value) (SettingsContent)
  required property var form
  // Searching: name the section too, since cards come from all over
  property bool showSection: false

  Layout.fillWidth: true
  implicitHeight: column.implicitHeight + Widget.padding * 2
  backgroundColor: Theme.backgroundAlt

  ColumnLayout {
    id: column
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Widget.padding
    spacing: Widget.spacing * 1.5

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      StyledText {
        visible: root.showSection && root.group.section !== root.group.title
        text: I18n.tr(root.group.section)
        opacity: 0.6
        textSize: Appearance.fontSize - 2
        Layout.fillWidth: true
      }

      StyledText {
        text: I18n.tr(root.group.title)
        textColor: Theme.accent
        textSize: Appearance.fontSize + 1
        font.bold: true
        Layout.fillWidth: true
      }

      StyledText {
        visible: root.group.description !== ""
        text: I18n.tr(root.group.description)
        opacity: 0.7
        textSize: Appearance.fontSize - 2
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    Repeater {
      model: root.group.rows

      delegate: SettingsField {
        required property var modelData
        row: modelData
        form: root.form
      }
    }
  }
}
