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
    useImplicitSize: true
    triggerLength: 1500
    edgeMargin: 0

      Rectangle {
        color: "transparent"
        implicitWidth: 800
        implicitHeight: 1440 - 100
        Rectangle {
          anchors.centerIn: parent
          implicitWidth: 700
          implicitHeight: 1200
          color: "darkblue"
        }
    }
  }
}
