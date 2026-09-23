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
    iconColor: Theme.resolveColor(Notifs.dnd ? root.properties.dndColor : root.properties.foregroundColor)
    borderHoverColor: Theme.accent
    backgroundColor: Theme.resolveColor(root.properties.backgroundColor)

    badgeVisible: root.properties.showCount && Notifs.count > 0
    badgeBackgroundColor: Theme.resolveColor(root.properties.badgeColor)
    badgeText: Notifs.count > 99 ? "99+" : String(Notifs.count)
  }

  PopoutAnchor {
    id: anchor
    popouts: root.popouts
    panel: root.panel
    popoutName: "notifications"
    active: root.properties.showPopout
    openDelay: 150
  }
}
