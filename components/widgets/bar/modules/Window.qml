pragma ComponentBehavior: Bound

import Quickshell.Wayland

import qs.config
import qs.components.reusable

IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  // Grows with the title up to preferredSize, and gives way when crowded
  readonly property string sizePolicy: "elastic"
  readonly property int preferredSize: 240
  readonly property int minimumSize: 80

  isVertical: barConfig.vertical
  icon: ""
  text: (ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.title) ? ToplevelManager.activeToplevel.title : "—"
  backgroundColor: Theme.accentAlt
}
