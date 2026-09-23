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

  signal dismissed

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

      NotificationText {
        notification: root.notification
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

    NotificationActions {
      notification: root.notification
    }
  }
}
