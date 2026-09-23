import QtQuick
import Quickshell

import qs.services
import qs.config
import qs.components.widgets.notifications

// Stacks incoming notifications as toasts near the top-left of the screen
// (offset past the bar), driven by NotificationManager.showPopup. Dismissing a toast
// only hides it — the notification stays tracked and remains visible/
// actionable from the bell popout.
Scope {
  id: root

  property int maxVisibleToasts: 5
  property int stackSpacing: 10
  property int topOffset: Appearance.screenMargin + 20
  property int leftOffset: Bar.extent + 20
  property int toastWidth: 360
  property int toastMaxHeight: 220
  property int dismissDuration: 5000
  property real dragDismissThreshold: 150

  property var activeToasts: []

  // Invisible anchor window the toast PopupWindows position relative to.
  PanelWindow {
    id: anchorPanel
    visible: true

    implicitWidth: 1
    implicitHeight: 1

    anchors {
      top: true
      left: true
    }

    color: "transparent"
    focusable: false
    exclusionMode: ExclusionMode.Ignore
  }

  Component {
    id: toastComponent

    NotificationToast {
      notification: null // set on creation
      anchorWindow: anchorPanel

      toastWidth: root.toastWidth
      toastMaxHeight: root.toastMaxHeight
      dismissDuration: root.dismissDuration
      dragDismissThreshold: root.dragDismissThreshold
      leftOffset: root.leftOffset
    }
  }

  Component.onCompleted: {
    if (typeof NotificationManager !== "undefined") {
      NotificationManager.showPopup.connect(createToast);
    }
  }

  function createToast(notification) {
    if (activeToasts.length >= maxVisibleToasts) {
      const oldest = activeToasts[0];
      if (oldest)
        oldest.dismiss();
    }

    const toast = toastComponent.createObject(root, {
      notification: notification,
      targetY: calculateTargetY(activeToasts.length)
    });

    if (!toast) {
      console.error("Notifications: failed to create toast for", notification.summary);
      return;
    }

    activeToasts.push(toast);

    // If the notification is dismissed elsewhere (e.g. from the bell
    // popout) while its toast is still showing, animate the toast out too.
    // Disconnected once the toast is gone, so a later close doesn't call
    // into a destroyed toast.
    const onClosed = () => {
      if (activeToasts.includes(toast))
        toast.dismiss();
    };
    notification.closed.connect(onClosed);
    toast.dismissed.connect(() => {
      try {
        notification.closed.disconnect(onClosed);
      } catch (e) {
        // The notification itself is already gone
      }
      removeToast(toast);
    });
  }

  function calculateTargetY(index) {
    let y = topOffset;
    for (let i = 0; i < index && i < activeToasts.length; i++) {
      y += activeToasts[i].implicitHeight + stackSpacing;
    }
    return y;
  }

  function removeToast(toast) {
    const index = activeToasts.indexOf(toast);
    if (index === -1)
      return;
    activeToasts.splice(index, 1);
    updateToastPositions();
    Qt.callLater(() => {
      if (!toast.visible)
        toast.destroy();
    });
  }

  function updateToastPositions() {
    for (let i = 0; i < activeToasts.length; i++) {
      activeToasts[i].updatePosition(calculateTargetY(i));
    }
  }
}
