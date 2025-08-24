import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Quickshell
import Quickshell.Services.SystemTray

import "root:/services" as Services
import "root:/" as App

Item {
  id: tray
  property int iconSize: 18

  property int leftPadding: 8
  property int rightPadding: 8
  property int topPadding: 4
  property int bottomPadding: 4
  property int spacing: 6
  property bool showPassive: true

  property color backgroundColor: Services.Colors.bgAlt
  property int backgroundRadius: 6
  property color backgroundBorderColor: "transparent"
  property real backgroundBorderWidth: 0

  height: App.Settings.widgetHeight
  implicitWidth: row.implicitWidth + App.Settings.widgetPadding * 2

  Layout.preferredWidth: implicitWidth
  Layout.preferredHeight: App.Settings.widgetHeight

  Rectangle {
    anchors.fill: parent
    radius: tray.backgroundRadius
    color: tray.backgroundColor
    // border.color: tray.backgroundBorderColor
    // border.width: tray.backgroundBorderWidth
    height: App.Settings.widgetHeight
  }

  Row {
    id: row
    anchors.centerIn: parent
    rightPadding: tray.rightPadding
    spacing: tray.spacing

    Repeater {
      model: SystemTray.items

      delegate: Item {
        readonly property var ti: modelData
        visible: ti && (tray.showPassive || ti.status !== Status.Passive)
        width: visible ? tray.iconSize : 0
        height: tray.iconSize

        Image {
          anchors.centerIn: parent
          source: ti ? ti.icon : ""
          sourceSize.width: tray.iconSize
          sourceSize.height: tray.iconSize
          fillMode: Image.PreserveAspectFit
          smooth: true
        }

        QsMenuAnchor {
          id: menuAnchor
          anchor.window: QSWindow.window
          menu: ti ? ti.menu : null
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

          onClicked: ev => {
            if (!ti)
              return;
            if (ev.button === Qt.RightButton) {
              if (ti.hasMenu)
                menuAnchor.open();
              return;
            }
            if (ev.button === Qt.LeftButton) {
              if (ti.onlyMenu && ti.hasMenu) {
                menuAnchor.open();
              } else if (ti.activate) {
                ti.activate();
              }
              return;
            }
            if (ev.button === Qt.MiddleButton && ti.secondaryActivate) {
              ti.secondaryActivate();
            }
          }

          onWheel: w => {
            if (ti && ti.scroll)
              ti.scroll(w.angleDelta.y, false);
          }
        }
      }
    }
  }
}
