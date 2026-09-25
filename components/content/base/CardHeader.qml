pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.components.reusable
import qs.config

// Title row of a TitledCard, with Save (shown while `dirty`) and Reset
// buttons for whichever service owns the panel's pending edits
Rectangle {
  id: root
  property string title
  property bool dirty: false
  // Hide both buttons for panels with nothing to save
  property bool showActions: true
  // Save stays visible while dirty but is disabled when false
  property bool canSave: true

  signal save
  signal reset

  Layout.fillWidth: true
  Layout.preferredHeight: Widget.height + Widget.padding
  color: "transparent"

  RowLayout {
    anchors.fill: parent
    spacing: Widget.spacing

    Text {
      text: root.title
      color: Theme.foreground
      font.family: Appearance.fontFamily
      font.pixelSize: Appearance.fontSize + 4
      font.bold: true
    }

    Item {
      Layout.fillWidth: true
    }

    // Save button
    Rectangle {
      Layout.preferredWidth: 80
      Layout.preferredHeight: Widget.height - 4
      color: saveArea.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
      radius: Appearance.borderRadius
      visible: root.showActions && root.dirty
      opacity: root.canSave ? 1 : 0.4

      RowLayout {
        anchors.centerIn: parent
        spacing: 6

        StyledIcon {
          text: "check"
          font.pixelSize: Appearance.fontSize
          color: Theme.background
        }

        Text {
          text: I18n.tr("Save")
          color: Theme.background
          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSize - 1
          font.bold: true
        }
      }

      MouseArea {
        id: saveArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.canSave
        onClicked: root.save()
      }
    }

    // Reset button
    Rectangle {
      visible: root.showActions
      Layout.preferredWidth: 80
      Layout.preferredHeight: Widget.height - 4
      color: Theme.backgroundHighlight
      radius: Appearance.borderRadius
      border.color: resetArea.containsMouse ? Theme.accent : Theme.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        StyledIcon {
          text: "undo"
          font.pixelSize: Appearance.fontSize
          color: Theme.foreground
          Layout.alignment: Qt.AlignCenter
        }

        Text {
          text: I18n.tr("Reset")
          color: Theme.foreground
          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSize - 1
          Layout.alignment: Qt.AlignCenter
        }
      }

      MouseArea {
        id: resetArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.reset()
      }
    }
  }
}
