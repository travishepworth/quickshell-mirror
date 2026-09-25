pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland

import qs.services
import qs.config

// Caffeine toggle: while on, the compositor (and hypridle) won't treat the
// session as idle. State is shared through IdleInhibit, so every bar's
// widget and the IPC target stay in sync.
BarIconWidget {
  id: root

  icon: IdleInhibitManager.enabled ? "coffee" : "bedtime"
  text: I18n.tr(IdleInhibitManager.enabled ? "Awake" : "Idle")
  showText: properties.showLabel

  backgroundColor: Theme.resolveColor(IdleInhibitManager.enabled ? properties.activeColor : properties.inactiveColor)
  opacity: mouseArea.pressed ? 0.8 : 1

  IdleInhibitor {
    window: root.panel
    enabled: IdleInhibitManager.enabled
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: IdleInhibitManager.toggle()
  }
}
