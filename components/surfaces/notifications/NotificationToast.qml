pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.services
import qs.components.reusable
import qs.components.content.parts.notifications

PopupWindow {
  id: root

  required property var notification
  property var anchorWindow: null

  property int toastWidth: 360
  property int toastMaxHeight: 220
  property int dismissDuration: 5000
  property real dragDismissThreshold: 150
  property int leftOffset: 20
  property int targetY: 20

  signal dismissed

  implicitWidth: toastWidth
  implicitHeight: Math.min(mainColumn.implicitHeight + Widget.padding * 2, toastMaxHeight)

  visible: false
  color: "transparent"

  anchor.window: anchorWindow

  Component.onCompleted: {
    anchor.rect.x = leftOffset;
    anchor.rect.y = targetY;
    anchor.rect.width = implicitWidth;
    anchor.rect.height = implicitHeight;
    visible = true;
    slideIn.start();
  }

  // Reposition instantly (used for stack reflow); the visual "movement"
  // reads fine since it's accompanied by other toasts sliding at once.
  function updatePosition(newTargetY) {
    targetY = newTargetY;
    anchor.rect.y = targetY;
  }

  // Only hides the toast — the notification stays tracked so it's still
  // visible/actionable from the bell popout afterwards.
  function dismiss() {
    if (slideOut.running)
      return;
    slideOut.start();
  }

  ParallelAnimation {
    id: slideIn
    NumberAnimation {
      target: card
      property: "y"
      from: -16
      to: 0
      duration: Appearance.animNormal
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: card
      property: "opacity"
      from: 0
      to: 1
      duration: Appearance.animNormal
      easing.type: Easing.OutCubic
    }
  }

  NumberAnimation {
    id: slideOut
    target: card
    property: "opacity"
    to: 0
    duration: Appearance.animFast
    easing.type: Easing.InQuad
    onFinished: {
      root.visible = false;
      root.dismissed();
    }
  }

  // A drag short of the threshold: slide back and undo the fade
  ParallelAnimation {
    id: snapBack
    NumberAnimation {
      target: dragShift
      property: "x"
      to: 0
      duration: Appearance.animFast
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: card
      property: "opacity"
      to: 1
      duration: Appearance.animFast
      easing.type: Easing.OutCubic
    }
  }

  // expireTimeout === 0 is the freedesktop-spec signal for "never expire".
  readonly property bool neverExpires: notification.expireTimeout === 0

  Timer {
    id: dismissTimer
    interval: root.dismissDuration
    running: !root.neverExpires && root.visible && !dragArea.containsMouse
    onTriggered: root.dismiss()
  }

  Item {
    id: card
    anchors.fill: parent
    opacity: 0
    // Anchored, so the drag moves it with a transform rather than x
    transform: Translate {
      id: dragShift
    }

    StyledContainer {
      id: content
      anchors.fill: parent
      backgroundColor: Theme.background
      borderColor: Theme.backgroundAlt
      borderWidth: Appearance.borderWidth
      borderRadius: Appearance.borderRadius + 2
      clip: true

      MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true

        property real pressX: 0
        property real dragDelta: 0

        // In scene coordinates: local ones move with the card being dragged
        function sceneX(mouse) {
          return dragArea.mapToItem(null, mouse.x, mouse.y).x;
        }

        onPressed: mouse => {
          snapBack.stop();
          pressX = sceneX(mouse);
          dragDelta = 0;
        }

        onPositionChanged: mouse => {
          if (!pressed)
            return;
          dragDelta = sceneX(mouse) - pressX;
          dragShift.x = dragDelta * 0.5;
          card.opacity = 1 - Math.abs(dragDelta) / (root.dragDismissThreshold * 2);
          if (Math.abs(dragDelta) > root.dragDismissThreshold)
            root.dismiss();
        }

        onReleased: {
          if (Math.abs(dragDelta) < root.dragDismissThreshold)
            snapBack.start();
        }

        ColumnLayout {
          id: mainColumn
          anchors.fill: parent
          anchors.margins: Widget.padding
          spacing: Widget.spacing / 2

          RowLayout {
            Layout.fillWidth: true
            spacing: Widget.spacing

            NotificationAvatar {
              appIcon: root.notification.appIcon ?? ""
              image: root.notification.image ?? ""
              baseSize: 30
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              StyledText {
                Layout.fillWidth: true
                text: root.notification.appName || ""
                textColor: Theme.foregroundAlt
                textSize: Appearance.fontSize - 2
                elide: Text.ElideRight
              }

              NotificationText {
                notification: root.notification
                summaryLines: 2
                bodyLines: 3
                onActivated: root.dismiss()
              }
            }

            StyledIconButton {
              Layout.fillWidth: false
              Layout.fillHeight: false
              Layout.preferredWidth: 22
              Layout.preferredHeight: 22
              Layout.alignment: Qt.AlignTop

              iconText: "󰅖"
              iconSize: 12
              borderRadius: 11
              iconColor: Theme.foregroundAlt
              hoverColor: Theme.backgroundHighlight

              onClicked: root.dismiss()
            }
          }

          NotificationActions {
            notification: root.notification
            onInvoked: root.dismiss()
          }
        }
      }
    }
  }
}
