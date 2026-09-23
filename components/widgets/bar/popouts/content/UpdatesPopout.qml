pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.reusable

// Pending updates, repo and AUR listed separately. Filled from the Updates
// widget's PopoutAnchor payload.
Item {
  id: root

  required property var wrapper
  // Inside an overlay module: no background of its own, and lists fill
  // the height it is given instead of their popout cap
  property bool embedded: false
  property bool hovered: hoverHandler.hovered

  // [{ name, from, to }]
  property var repoPackages: []
  property var aurPackages: []

  readonly property int margins: 20
  property int maxRows: 15

  implicitWidth: Math.max(320, column.implicitWidth + margins * 2)
  implicitHeight: column.implicitHeight + margins * 2
  width: implicitWidth
  height: implicitHeight

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
      text: `+${section.packages.length - root.maxRows} more`
      textColor: Theme.foregroundAlt
      textSize: Appearance.fontSize - 2
    }
  }

  StyledContainer {
    anchors.fill: parent
    backgroundColor: root.embedded ? "transparent" : Theme.background
    borderWidth: 0
    borderRadius: Appearance.borderRadius + 2

    HoverHandler {
      id: hoverHandler
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: root.margins
      spacing: Widget.padding

      Section {
        title: "Repositories"
        packages: root.repoPackages
      }

      Section {
        title: "AUR"
        packages: root.aurPackages
      }

      StyledText {
        visible: root.repoPackages.length + root.aurPackages.length === 0
        text: "System is up to date"
        textColor: Theme.foregroundAlt
      }
    }
  }
}
