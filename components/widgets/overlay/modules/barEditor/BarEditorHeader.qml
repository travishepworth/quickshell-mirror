pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
  id: root
  property string title: "Bar Editor"
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
      visible: BarManager.isDirty

      RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: "" // Checkmark icon
          font.pixelSize: Appearance.fontSize
          color: Theme.background
        }

        Text {
          text: "Save"
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
        onClicked: BarManager.saveChanges()
      }
    }

    // Reset button
    Rectangle {
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

        Text {
          text: "" // Reset icon
          font.pixelSize: Appearance.fontSize
          color: Theme.foreground
          Layout.alignment: Qt.AlignCenter
        }

        Text {
          text: "Reset"
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
        onClicked: BarManager.resetChanges()
      }
    }
  }
}
