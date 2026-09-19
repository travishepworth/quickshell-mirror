pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.methods
import qs.components.reusable

StyledContainer {
  id: root

  required property var groupData // { appName, appIcon, notifications, newestTime }
  property bool collapsed: true

  Layout.fillWidth: true
  implicitHeight: layout.implicitHeight + Widget.padding * 2
  backgroundColor: Theme.backgroundAlt

  ColumnLayout {
    id: layout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Widget.padding
    spacing: Widget.spacing

    RowLayout {
      Layout.fillWidth: true
      spacing: Widget.spacing

      NotificationAvatar {
        appIcon: root.groupData.appIcon
        baseSize: 26
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
          Layout.fillWidth: true
          text: root.groupData.appName || "Unknown"
          font.bold: true
          elide: Text.ElideRight
        }

        StyledText {
          Layout.fillWidth: true
          text: Utils.formatRelativeTime(root.groupData.newestTime) + (root.groupData.notifications.length > 1 ? ` · ${root.groupData.notifications.length} notifications` : "")
          textColor: Theme.foregroundAlt
          textSize: Appearance.fontSize - 2
          opacity: 0.7
          elide: Text.ElideRight
        }
      }

      StyledIconButton {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22

        iconText: "󰅖"
        iconSize: 12
        borderRadius: 11
        iconColor: Theme.foregroundAlt
        hoverColor: Theme.backgroundHighlight
        tooltipText: "Dismiss all"

        onClicked: root.dismissGroup()
      }

      StyledIconButton {
        visible: root.groupData.notifications.length > 1
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22

        iconText: "󰅂"
        iconSize: 12
        rotation: root.collapsed ? 0 : 90
        borderRadius: 11
        iconColor: Theme.foregroundAlt
        hoverColor: Theme.backgroundHighlight

        Behavior on rotation {
          NumberAnimation { duration: Appearance.animationDuration }
        }

        onClicked: root.collapsed = !root.collapsed
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.leftMargin: 26 + Widget.spacing
      spacing: Widget.spacing
      visible: !root.collapsed || root.groupData.notifications.length === 1

      Repeater {
        model: root.groupData.notifications

        NotificationItemDelegate {
          required property var modelData
          notification: modelData
          onDismissed: modelData.dismiss()
        }
      }
    }
  }

  function dismissGroup() {
    for (const notif of root.groupData.notifications) {
      notif.dismiss();
    }
  }
}
