pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.reusable

// Pending updates, repo and AUR listed separately. Filled from the Updates
// widget's PopoutAnchor payload.
PopoutContent {
  id: root

  // [{ name, from, to }]
  property var repoPackages: []
  property var aurPackages: []

  margins: 20
  spacing: Widget.padding
  property int maxRows: 15

  implicitWidth: Math.max(320, body.implicitWidth + margins * 2)

  component Section: ColumnLayout {
    id: section
    required property string title
    required property var packages

    visible: packages.length > 0
    spacing: 2
    Layout.fillWidth: true

    StyledText {
      text: `${section.title} (${section.packages.length})`
      font.bold: true
      textColor: Theme.accent
    }

    Repeater {
      model: section.packages.slice(0, root.maxRows)

      RowLayout {
        id: row
        required property var modelData
        Layout.fillWidth: true
        spacing: Widget.padding

        StyledText {
          text: row.modelData.name
          Layout.fillWidth: true
        }
        StyledText {
          text: `${row.modelData.from} → ${row.modelData.to}`
          textColor: Theme.foregroundAlt
          textSize: Appearance.fontSize - 2
        }
      }
    }

    StyledText {
      visible: section.packages.length > root.maxRows
      text: I18n.tr("+{0} more", section.packages.length - root.maxRows)
      textColor: Theme.foregroundAlt
      textSize: Appearance.fontSize - 2
    }
  }

  Section {
    title: I18n.tr("Repositories")
    packages: root.repoPackages
  }

  Section {
    title: I18n.tr("AUR")
    packages: root.aurPackages
  }

  StyledText {
    visible: root.repoPackages.length + root.aurPackages.length === 0
    text: I18n.tr("System is up to date")
    textColor: Theme.foregroundAlt
  }
}
