pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell

import qs.config
import qs.components.reusable

Rectangle {
  id: root

  property string appIcon: ""
  property string image: ""
  property int baseSize: 32

  implicitWidth: baseSize
  implicitHeight: baseSize
  radius: width / 2
  color: Theme.accentAlt
  clip: true

  Loader {
    active: root.image === ""
    anchors.centerIn: parent
    sourceComponent: root.appIcon !== "" ? appIconComponent : fallbackGlyphComponent
  }

  Component {
    id: appIconComponent
    Image {
      width: root.baseSize * 0.8
      height: root.baseSize * 0.8
      asynchronous: true
      source: Quickshell.iconPath(root.appIcon, "image-missing")
    }
  }

  Component {
    id: fallbackGlyphComponent
    StyledText {
      text: "󰂚"
      textColor: Theme.base00
      textSize: root.baseSize * 0.5
    }
  }

  Loader {
    active: root.image !== ""
    anchors.fill: parent
    sourceComponent: Item {
      anchors.fill: parent
      Image {
        id: notifImage
        anchors.fill: parent
        source: root.image
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        layer.enabled: true
        layer.effect: OpacityMask {
          maskSource: Rectangle {
            width: notifImage.width
            height: notifImage.height
            radius: notifImage.width / 2
          }
        }
      }

      Image {
        visible: root.appIcon !== ""
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.baseSize * 0.5
        height: root.baseSize * 0.5
        asynchronous: true
        source: root.appIcon !== "" ? Quickshell.iconPath(root.appIcon, "image-missing") : ""
      }
    }
  }
}
