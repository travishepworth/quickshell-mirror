pragma ComponentBehavior: Bound

import QtQuick

import qs.services
import qs.config
import qs.components.reusable
import qs.components.methods
import qs.components.widgets.bar.popouts

Item {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  property bool isVertical: barConfig.vertical

  readonly property int crossAxisSize: Widget.height
  readonly property int mainAxisSize: 320

  implicitWidth: isVertical ? crossAxisSize : mainAxisSize
  implicitHeight: isVertical ? mainAxisSize : crossAxisSize
  width: implicitWidth
  height: implicitHeight

  IconTextWidget {
    id: iconText
    anchors.fill: parent

    isVertical: root.isVertical

    icon: MprisController.isPlaying ? "♪" : "⏸"
    text: root.formatTrack()

    maxTextLength: 30
    backgroundColor: MprisController.isPlaying ? Theme.green : Theme.bg2
  }

  function formatTrack() {
    if (!MprisController.activePlayer)
      return "No player";
    const artist = Utils.truncate(MprisController.trackArtist, 10, "");
    const title = Utils.truncate(MprisController.trackTitle, 20, "");
    return "󰠃 " + artist + " - " + title;
  }

  PopoutAnchor {
    id: anchor
    popouts: root.popouts
    panel: root.panel
    popoutName: "media-player"
    openDelay: 150
  }
}
