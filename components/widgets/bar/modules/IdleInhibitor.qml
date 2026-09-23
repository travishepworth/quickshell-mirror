pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland

import qs.services
import qs.config
import qs.components.reusable

// Caffeine toggle: while on, the compositor (and hypridle) won't treat the
// session as idle. State is shared through IdleInhibit, so every bar's
// widget and the IPC target stay in sync.
IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  isVertical: barConfig.vertical

  icon: IdleInhibit.enabled ? "\u{F0176}" : "\u{F0FAA}"
  text: IdleInhibit.enabled ? "Awake" : "Idle"
  showText: properties.showLabel

  backgroundColor: Theme.resolveColor(IdleInhibit.enabled ? properties.activeColor : properties.inactiveColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)
  opacity: mouseArea.pressed ? 0.8 : 1

  IdleInhibitor {
    window: root.panel
    enabled: IdleInhibit.enabled
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: IdleInhibit.toggle()
  }
}
