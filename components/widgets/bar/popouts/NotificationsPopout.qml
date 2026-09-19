pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.services
import qs.config
import qs.components.reusable
import qs.components.widgets.notifications

Item {
  id: root

  required property var wrapper
  property bool hovered: hoverHandler.hovered

  readonly property int margins: 20
  readonly property int headerHeight: 28
  readonly property int listHeight: 380

  implicitWidth: 400
  implicitHeight: margins * 2 + headerHeight + Widget.spacing + listHeight
  width: implicitWidth
  height: implicitHeight

  // Rebuilt whenever the tracked-notifications model changes; grouped by
  // appName, newest group first.
  property var groupedNotifications: []

  function rebuildGroups() {
    const byApp = {};
    const order = [];
    for (const notif of Notifs.notifications.values) {
      if (!notif)
        continue;
      const key = notif.appName || "";
      if (!byApp[key]) {
        byApp[key] = {
          appName: notif.appName || "Unknown",
          appIcon: notif.appIcon || "",
          notifications: [],
          newestTime: 0
        };
        order.push(key);
      }
      byApp[key].notifications.push(notif);
      const t = Notifs.receivedAtFor(notif);
      if (t > byApp[key].newestTime)
        byApp[key].newestTime = t;
    }
    const groups = order.map(key => byApp[key]);
    groups.sort((a, b) => b.newestTime - a.newestTime);
    root.groupedNotifications = groups;
  }

  Connections {
    target: Notifs.notifications
    function onValuesChanged() { root.rebuildGroups(); }
  }

  Component.onCompleted: rebuildGroups()

  StyledContainer {
    id: content
    anchors.fill: parent

    backgroundColor: Theme.background
    borderColor: Theme.backgroundAlt
    borderWidth: 0
    borderRadius: Appearance.borderRadius + 2
    clip: true

    HoverHandler {
      id: hoverHandler
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: root.margins
      spacing: Widget.spacing

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.headerHeight
        spacing: Widget.spacing

        StyledText {
          text: "Notifications" + (Notifs.count > 0 ? ` (${Notifs.count})` : "")
          textSize: Appearance.fontSize * 1.05
          font.bold: true
          textColor: Theme.accent
        }

        Item { Layout.fillWidth: true }

        StyledText {
          text: "DND"
          textColor: Theme.foregroundAlt
          textSize: Appearance.fontSize - 1
        }

        StyledSwitch {
          checked: Notifs.dnd
          onToggled: Notifs.dnd = checked
        }

        StyledTextButton {
          text: "Clear All"
          textPadding: 6
          enabled: Notifs.count > 0
          opacity: enabled ? 1.0 : 0.5
          onClicked: Notifs.clearAll()
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
            text: "No notifications"
            textColor: Theme.foregroundAlt
            opacity: 0.6
          }
        }
      }
    }
  }
}
