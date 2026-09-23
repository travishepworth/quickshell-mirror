pragma ComponentBehavior: Bound
import QtQuick
import Quickshell

import qs.services
import qs.config
import qs.components.reusable
import qs.components.widgets.bar.popouts

// Default output volume. The icon follows mute, level and the device type
// (headphones, headset, Bluetooth, HDMI). Scroll changes the volume, click
// mutes, middle click runs a command; hovering opens the mixer.
IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  readonly property real maxVolume: properties.maxVolume / 100

  isVertical: barConfig.vertical

  icon: Audio.outputIcon(Audio.deviceKind(Audio.defaultSink), Audio.muted, Audio.volume)
  text: `${Math.round(Audio.volume * 100)}%`
  showText: properties.showPercentage

  backgroundColor: Theme.resolveColor(Audio.muted ? properties.mutedColor : properties.backgroundColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)
  opacity: mouseArea.pressed ? 0.8 : 1

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) {
        if (root.properties.middleCommand)
          Quickshell.execDetached(["sh", "-c", root.properties.middleCommand]);
      } else {
        Audio.toggleMute();
      }
    }
    onWheel: wheel => {
      const step = root.properties.scrollStep / 100;
      Audio.stepNodeVolume(Audio.defaultSink, wheel.angleDelta.y > 0 ? step : -step, root.maxVolume);
    }
  }

  PopoutAnchor {
    popouts: root.popouts
    panel: root.panel
    popoutName: "audio-mixer"
    active: root.properties.showPopout
    extraData: ({
        "mode": "output",
        "maxVolume": root.maxVolume
      })
  }
}
