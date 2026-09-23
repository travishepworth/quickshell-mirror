pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.common
import qs.components.widgets.bar.popouts.content

// Notification history (the bar's list, with clear and do-not-disturb).
// Compact shows the count only.
OverlayCard {
  id: root

  StatFigure {
    visible: root.compact
    anchors.centerIn: parent
    value: String(NotificationManager.count)
    label: I18n.tr(NotificationManager.dnd ? "muted" : "notifications")
    valueColor: NotificationManager.count > 0 ? Theme.accent : Theme.foreground
  }

  NotificationsPopout {
    visible: !root.compact
    anchors.fill: parent
    wrapper: null
    embedded: true
  }
}
