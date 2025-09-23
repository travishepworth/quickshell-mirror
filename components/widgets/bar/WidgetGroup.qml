// components/widgets/WidgetGroup.qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services

Item {
  id: root

  property bool vertical: Settings.verticalBar
  property alias model: repeater.model
  property int spacing: Settings.widgetSpacing
  property int alignment: Qt.AlignHCenter

  implicitWidth: layout.implicitWidth
  implicitHeight: layout.implicitHeight

  GridLayout {
    id: layout

    columns: vertical ? 1 : repeater.count
    rows: vertical ? repeater.count : 1
    columnSpacing: vertical ? 0 : spacing
    rowSpacing: vertical ? spacing : 0

    Repeater {
      id: repeater
      delegate: Loader {
        required property var modelData

        sourceComponent: modelData.component
        Layout.alignment: modelData.alignment || root.alignment

        onLoaded: {
          if (item && modelData.properties) {
            for (let prop in modelData.properties) {
              if (item.hasOwnProperty(prop)) {
                item[prop] = modelData.properties[prop];
              }
            }
          }
        }
      }
    }
  }
}
