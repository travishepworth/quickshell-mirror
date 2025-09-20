pragma ComponentBehavior: Bound

import QtQuick

import qs.services

BaseWidget {
  id: root

  // Content properties
  property string icon: ""
  property string text: ""
  property bool rotateText: true
  property real textScale: 1.0
  property real iconScale: 1.0
  property real spacing: 6

  content: Component {
    Loader {
      sourceComponent: {
        if (!root.isVertical) {
          return horizontalLayout;
        } else if (root.rotateText) {
          return rotatedLayout;
        } else {
          return verticalLayout;
        }
      }

      // Horizontal layout
      Component {
        id: horizontalLayout
        Row {
          spacing: root.spacing

          Text {
            color: Colors.bg
            text: root.icon
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize * root.iconScale
            visible: root.icon !== ""
          }

          Text {
            color: Colors.bg
            text: root.text || "—"
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize * root.textScale
          }
        }
      }

      // Vertical layout (no rotation)
      Component {
        id: verticalLayout
        Column {
          spacing: root.text !== "" ? 2 : 0

          Text {
            color: Colors.bg
            text: root.icon
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize * root.iconScale
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.icon !== ""
          }

          Text {
            color: Colors.bg
            text: root.text || "—"
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize * 0.8 * root.textScale
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.text !== ""
          }
        }
      }

      // Rotated layout for vertical bars
      Component {
        id: rotatedLayout
        Item {
          implicitWidth: Math.max(root.icon !== "" ? iconText.height : 0, root.text !== "" ? mainText.height : 0) + (root.text !== "" && root.icon !== "" ? root.spacing : 0)

          implicitHeight: (root.icon !== "" ? iconText.width : 0) + (root.text !== "" ? mainText.width : 0) + (root.text !== "" && root.icon !== "" ? root.spacing : 0)

          Text {
            id: iconText
            color: Colors.bg
            text: root.icon
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize * root.iconScale
            visible: root.icon !== ""
            anchors {
              centerIn: parent
              verticalCenterOffset: root.text !== "" && root.icon !== "" ? -(mainText.width / 2) - 3 : 0
            }
          }

          Text {
            id: mainText
            color: Colors.bg
            text: root.text || "—"
            font.family: Settings.fontFamily
            font.pixelSize: Settings.fontSize * root.textScale
            rotation: -90
            visible: root.text !== ""
            anchors {
              centerIn: parent
              verticalCenterOffset: root.icon !== "" ? (iconText.width / 2) + 3 : 0
            }
          }
        }
      }
    }
  }
}
