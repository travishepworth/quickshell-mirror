pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.components.methods
import qs.components.reusable

StyledContainer {
  id: root

  required property var notification

  signal dismissed()

  readonly property var visibleActions: (notification.actions ?? []).filter(a => a.identifier !== "default")
  readonly property var defaultAction: (notification.actions ?? []).find(a => a.identifier === "default")

  Layout.fillWidth: true
  implicitHeight: layout.implicitHeight + Widget.padding * 2
  backgroundColor: Theme.backgroundHighlight
  borderRadius: Appearance.borderRadius

  ColumnLayout {
    id: layout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Widget.padding
    spacing: Widget.spacing / 2

    RowLayout {
      Layout.fillWidth: true
      spacing: Widget.spacing

      MouseArea {
        Layout.fillWidth: true
        implicitHeight: textColumn.implicitHeight
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          if (root.defaultAction)
            root.defaultAction.invoke();
        }

        ColumnLayout {
          id: textColumn
          width: parent.width
          spacing: 2

          StyledText {
            Layout.fillWidth: true
            text: root.notification.summary || ""
            textSize: Appearance.fontSize
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          StyledText {
            visible: (root.notification.body ?? "") !== ""
            Layout.fillWidth: true
            text: root.notification.body ?? ""
            textColor: Theme.foregroundAlt
            textSize: Appearance.fontSize - 1
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
          }
        }
      }

      StyledText {
        Layout.alignment: Qt.AlignTop
        text: Utils.formatRelativeTime(Notifs.receivedAtFor(root.notification))
        textColor: Theme.foregroundAlt
        textSize: Appearance.fontSize - 2
        opacity: 0.7
      }

      StyledIconButton {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        Layout.alignment: Qt.AlignTop

        iconText: "󰅖"
        iconSize: 12
        borderRadius: 11
        iconColor: Theme.foregroundAlt
        hoverColor: Theme.background

        onClicked: root.dismissed()
      }
    }

    Flickable {
      Layout.fillWidth: true
      visible: root.visibleActions.length > 0
      implicitHeight: actionRow.implicitHeight
      contentWidth: actionRow.implicitWidth
      interactive: contentWidth > width
      flickableDirection: Flickable.HorizontalFlick
      clip: true

      RowLayout {
        id: actionRow
        spacing: Widget.spacing

        Repeater {
          model: root.visibleActions

          StyledTextButton {
            required property var modelData
            text: modelData.text
            textPadding: 6
            onClicked: modelData.invoke()
          }
        }
      }
    }
  }
}
