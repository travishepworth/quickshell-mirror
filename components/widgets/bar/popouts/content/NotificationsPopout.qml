pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.services
import qs.config
import qs.components.reusable
import qs.components.widgets.notifications

PopoutContent {
  id: root

  margins: 20
  clip: true
  readonly property int headerHeight: 28
  readonly property int listHeight: 380

  implicitWidth: 400
  implicitHeight: margins * 2 + headerHeight + Widget.spacing + listHeight

  // Rebuilt whenever the tracked-notifications model changes; grouped by
  // appName, newest group first.
  property var groupedNotifications: []

  function rebuildGroups() {
    const byApp = {};
    const order = [];
    for (const notif of NotificationManager.notifications.values) {
      if (!notif)
        continue;
      const key = notif.appName || "";
      if (!byApp[key]) {
        byApp[key] = {
          appName: notif.appName || I18n.tr("Unknown"),
          appIcon: notif.appIcon || "",
          notifications: [],
          newestTime: 0
        };
        order.push(key);
      }
      byApp[key].notifications.push(notif);
      const t = NotificationManager.receivedAtFor(notif);
      if (t > byApp[key].newestTime)
        byApp[key].newestTime = t;
    }
    const groups = order.map(key => byApp[key]);
    groups.sort((a, b) => b.newestTime - a.newestTime);
    root.groupedNotifications = groups;
  }

  Connections {
    target: NotificationManager.notifications
    function onValuesChanged() {
      root.rebuildGroups();
    }
  }

  Component.onCompleted: rebuildGroups()

  RowLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: root.headerHeight
    spacing: Widget.spacing

    StyledText {
      text: NotificationManager.count > 0 ? I18n.tr("Notifications ({0})", NotificationManager.count) : I18n.tr("Notifications")
      textSize: Appearance.fontSize * 1.05
      font.bold: true
      textColor: Theme.accent
    }

    Item {
      Layout.fillWidth: true
    }

    StyledText {
      text: I18n.tr("DND")
      textColor: Theme.foregroundAlt
      textSize: Appearance.fontSize - 1
    }

    StyledSwitch {
      checked: NotificationManager.dnd
      onToggled: NotificationManager.dnd = checked
    }

    StyledTextButton {
      text: I18n.tr("Clear All")
      textPadding: 6
      enabled: NotificationManager.count > 0
      opacity: enabled ? 1.0 : 0.5
      onClicked: NotificationManager.clearAll()
    }
  }

  StyledSeparator {
    Layout.fillWidth: true
  }

  StyledScrollView {
    id: scrollView
    Layout.fillWidth: true
    Layout.fillHeight: true
    showScrollBar: true
    contentPadding: 0

    ColumnLayout {
      width: scrollView.availableWidth
      spacing: Widget.spacing

      Repeater {
        model: root.groupedNotifications

        NotificationGroupDelegate {
          required property var modelData
          groupData: modelData
        }
      }

      StyledText {
        visible: root.groupedNotifications.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Widget.padding * 2
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("No notifications")
        textColor: Theme.foregroundAlt
        opacity: 0.6
      }
    }
  }
}
