import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "root:/services" as Services

PanelWindow {
  id: toastHost
  anchors {
    top: true
    right: true
  }
  margins: Qt.rect(12, 12, 12, 12)
  aboveWindows: true
  focusable: false
  visible: false

  Column {
    id: stack
    anchors {
      top: parent.top
      right: parent.right
    }
    spacing: 8

    Repeater {
      id: list
      model: Services.NotificationService.NotificationServer.trackedNotifications
      // Only show window when we actually have at least one toast:
      onCountChanged: toastHost.visible = (count > 0)

      delegate: Rectangle {
        // Fixed / bounded width avoids circular size calc issues
        width: 360
        radius: 8
        border.width: 1
        border.color: "#00000020"
        color: "#202020F0"
        // Height comes from content
        height: content.implicitHeight + 16

        // Auto-expire if sender asked
        Timer {
          running: modelData.expireTimeout > 0
          interval: Math.max(1, modelData.expireTimeout * 1000)
          repeat: false
          onTriggered: modelData.expire()
        }

        // Content
        Column {
          id: content
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 12
            rightMargin: 36
            topMargin: 8
            bottomMargin: 8
          }
          spacing: 4

          Text {
            text: modelData.summary
            font.pixelSize: 14
            font.bold: true
            color: "white"
            wrapMode: Text.Wrap
            // make sure it wraps within card width:
            width: parent.width
            textFormat: Text.PlainText
          }

          Text {
            text: modelData.body
            font.pixelSize: 12
            color: "#DDDDDD"
            wrapMode: Text.Wrap
            width: parent.width
            textFormat: Text.PlainText   // per docs, avoid markup surprises
          }
        }

        // Close button
        Text {
          text: "✕"
          color: "#CCCCCC"
          font.pixelSize: 14
          anchors {
            right: parent.right
            top: parent.top
            rightMargin: 8
            topMargin: 6
          }
          opacity: 0.9
          z: 10
          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              modelData.dismiss();
              modelData.tracked = false;
              // Let the window hide itself when list.count drops to 0
            }
            onEntered: parent.opacity = 1.0
            onExited: parent.opacity = 0.9
          }
        }
      }
    }
  }
}
