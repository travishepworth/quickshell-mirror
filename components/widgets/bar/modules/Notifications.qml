pragma ComponentBehavior: Bound

import QtQuick

import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.bar.popouts

Item {
  id: root

  // -- Public API --
  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  implicitWidth: Widget.height
  implicitHeight: Widget.height

  StyledRectButton {
    id: button
    anchors.fill: parent

    iconText: Notifs.dnd ? "󰂛" : "󰂚"
    iconColor: Notifs.dnd ? Theme.foregroundAlt : Theme.background
    borderHoverColor: Theme.accent
    backgroundColor: Theme.accentAlt

    badgeVisible: Notifs.count > 0
    badgeText: Notifs.count > 99 ? "99+" : String(Notifs.count)
  }

  PopoutAnchor {
    id: anchor
    popouts: root.popouts
    panel: root.panel
    popoutName: "notifications"
    openDelay: 150
  }
}
