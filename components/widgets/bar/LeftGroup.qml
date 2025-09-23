// components/widgets/LeftGroup.qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.services
import qs.modules.bar.widgets as Widgets

WidgetGroup {
  id: root

  property var screen
  property bool showMedia: false

  model: [
    {
      component: windowComponent,
      properties: {
        orientation: Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
      }
    },
    {
      component: mediaComponent,
      properties: {
        visible: showMedia
      }
    }
  ]

  Component {
    id: windowComponent
    Widgets.Window {
      property int orientation: Qt.Horizontal
    }
  }

  Component {
    id: mediaComponent
    Widgets.Media {}
  }
}
