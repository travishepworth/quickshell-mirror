pragma ComponentBehavior: Bound

import QtQuick

import qs.components.widgets.bar.declarations
import qs.config

QtObject {
  property Component leftCenterGroup: WidgetGroup {
    model: [
      {
        component: mediaComponent,
        visible: true
      }
    ]
    Component {
      id: mediaComponent
      Media {}
    }
  }

  property Component rightCenterGroup: WidgetGroup {

    model: [
      {
        component: timeComponent,
        visible: true
      }
    ]

    Component {
      id: timeComponent
      Time {}
    }
  }
}
