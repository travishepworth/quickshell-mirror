pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

/* NotificationManager handles system notifications via DBus */
Singleton {
  id: root

  readonly property alias notifications: server.trackedNotifications

  readonly property int count: notifications.values.length

  /**
     * A "Do Not Disturb" flag. When true, new notification popups will be suppressed,
     * except for those marked with 'Critical' urgency. Notifications will still be
     * added to the `notifications` list.
     */
  property bool dnd: false

  /**
     * This signal is emitted when a new notification is received that should be
     * displayed as a popup. The UI layer should connect to this signal.
     */
  signal showPopup(variant notification)

  /**
     * Dismisses all currently tracked notifications.
     */
  function clearAll() {
    // Snapshot first: dismissing mutates the live tracked-notifications
    // model out from under us as we iterate.
    const values = notifications.values;
    for (var i = values.length - 1; i >= 0; i--) {
      const notif = values[i];
      if (notif) {
        notif.dismiss();
      }
    }
  }

  // NotificationServer can't create notifications itself, so send one over
  // DBus; it comes back through our own server like any other (DND applies).
  function sendNotification(appName, summary, body) {
    Quickshell.execDetached(["notify-send", "-a", appName, summary, body]);
  }

  // MARK: - Received-time tracking
  //
  // Notification exposes no timestamp of its own, so we stamp arrival
  // time ourselves, keyed by id, and clean up once the notification closes.
  property var _receivedAt: ({})

  function receivedAtFor(notification) {
    if (!notification)
      return Date.now();
    if (root._receivedAt[notification.id] === undefined) {
      root._receivedAt[notification.id] = Date.now();
    }
    return root._receivedAt[notification.id];
  }

  // MARK: - Internal Implementation

  /**
     * The core NotificationServer that listens for DBus notifications.
     */
  NotificationServer {
    id: server

    // Set all capabilities to true to be a fully-featured server
    actionsSupported: true
    actionIconsSupported: true
    bodySupported: true
    bodyHyperlinksSupported: true
    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true
    // Optional, set to false if you don't want the server to outlive a QML reload
    keepOnReload: false

    Component.onCompleted: {
      // This log is the most important for debugging.
      // It should now print "true".
      console.log("========== Notification Server ==========");
      console.log("  > Registered:", server.registered);
      console.log("  > Capabilities:");
      console.log("    - Actions:", server.actionsSupported);
      console.log("    - Action Icons:", server.actionIconsSupported);
      console.log("    - Body:", server.bodySupported);
      console.log("    - Body Hyperlinks:", server.bodyHyperlinksSupported);
      console.log("    - Body Markup:", server.bodyMarkupSupported);
      console.log("    - Image:", server.imageSupported);
      console.log("    - Persistence:", server.persistenceSupported);
      console.log("  > Tracked Notifications:", server.trackedNotifications.values.length);
      console.log("=========================================");
    }

    /**
     * This signal handler is the entry point for all new notifications.
     */
    onNotification: notification => {
      // The 'tracked' property adds the notification to the `trackedNotifications` model.
      // We don't track 'transient' notifications (e.g., volume changes).
      if (!notification.transient) {
        notification.tracked = true;
      }
      root.receivedAtFor(notification);

      // Suppress popups if Do Not Disturb is on, unless the notification is critical.
      if (!root.dnd || notification.urgency === NotificationUrgency.Critical) {
        root.showPopup(notification);
      }

      // You can connect to the closed signal if you need to know when a
      // notification is dismissed by the client or times out.
      notification.closed.connect(reason => {
        delete root._receivedAt[notification.id];
      });
    }
  }
}
