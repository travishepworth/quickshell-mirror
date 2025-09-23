// components/widgets/CenterGroups.qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.modules.bar.widgets

QtObject {
  property Component leftCenterGroup: WidgetGroup {
    model: [
      {
        component: timeComponent
      }
    ]

    Component {
      id: timeComponent
      Time {}
    }
  }

  property Component rightCenterGroup: WidgetGroup {
    property bool showSystemMonitor: false

    model: {
      let widgets = [];
      if (showSystemMonitor) {
        widgets.push({
          component: systemMonitorComponent
        });
      }
      return widgets;
    }

    // Component {
    //   id: systemMonitorComponent
    //   SystemMonitor {}
    // }
  }
}
