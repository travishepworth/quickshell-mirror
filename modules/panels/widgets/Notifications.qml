import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland


import QtQuick
import Quickshell
import "root:/services" as Services
import "root:/" as App
import Quickshell.Services.Notifications

Item {
  id: root
  width: 360
  implicitHeight: listView.implicitHeight

  // Pass in the service instance from shell.qml
  property QtObject service

  Rectangle {
    anchors.fill: parent
    radius: 10
    color: "#0f111a"
    border.color: "#313244"
    border.width: 1
  }

  Column {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 8

    // Header: DND + Close All + Test
    Row {
      spacing: 8
      Text { text: "Notifications"; color: "white"; font.bold: true }
      Item { width: 1; height: 1; Layout.fillWidth: true } // spacer (works fine without Layouts)
      Button {
        text: service && service.doNotDisturb ? "DND: On" : "DND: Off"
        onClicked: if (service) service.doNotDisturb = !service.doNotDisturb
      }
      Button {
        text: "Close All"
        enabled: service && service.notifications && service.notifications.count > 0
        onClicked: if (service) service.closeAll()
      }
      Button {
        text: "Test"
        onClicked: if (service) service.sendTest()
        // lets you verify end-to-end quickly
      }
    }

    // Scrollable notifications list
    Flickable {
      id: scroller
      clip: true
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: 4
      anchors.bottom: parent.bottom
      contentHeight: listView.contentHeight
      boundsBehavior: Flickable.StopAtBounds

      ListView {
        id: listView
        width: parent.width
        interactive: false   // Flickable handles scrolling
        model: service ? service.notifications : null
        spacing: 6

        delegate: Rectangle {
          width: listView.width
          radius: 8
          color: "#1E1E2A"
          border.color: "#313244"
          border.width: 1
          anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
          implicitHeight: bodyTxt.implicitHeight + titleTxt.implicitHeight + 24

          Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Row {
              spacing: 8
              Text { id: titleTxt; text: summary; color: "white"; font.bold: true; wrapMode: Text.Wrap }
              Item { width: 1; height: 1 } // spacer
              Button { text: "Close"; onClicked: service.close(model) }
            }

            Text {
              id: bodyTxt
              text: body || ""
              color: "#cdd6f4"
              wrapMode: Text.Wrap
            }
          }
        }

        // Empty state so "something loads at first"
        Rectangle {
          id: emptyState
          visible: !model || model.count === 0
          width: listView.width
          height: 120
          radius: 8
          color: "transparent"
          border.width: 0

          Column {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "No notifications"; color: "#cdd6f4" }
            Button { text: "Send Test"; onClicked: if (service) service.sendTest() }
          }
        }
      }
    }
  }
}
