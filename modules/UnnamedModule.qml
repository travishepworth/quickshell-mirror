pragma ComponentBehavior: Bound
import QtQuick

import qs.components.widgets.popouts
import qs.components.widgets.reusable
import qs.config
import qs.services

Item {
  anchors.fill: parent

  EdgePopup {
    edge: EdgePopup.Edge.Right
    position: 0.5
    enableTrigger: true
    useImplicitSize: false
    triggerLength: 300

    Rectangle {
      implicitWidth: 400
      implicitHeight: 200
      color: "darkblue"
    }
  }
}
