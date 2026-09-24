pragma ComponentBehavior: Bound
import QtQuick

import qs.config
import qs.components.reusable

// Base for icon + label bar modules: the inputs every module gets from
// BarWidgetHost, orientation from the bar, and the configured colors (modules
// override backgroundColor for their states)
IconTextWidget {
  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  isVertical: barConfig.vertical
  crossSize: barConfig.widgetSize
  backgroundColor: Theme.resolveColor(properties.backgroundColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)
}
