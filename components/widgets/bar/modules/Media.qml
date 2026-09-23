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

  // Always the same size, so the widget (and the popout hanging off it)
  // doesn't move when the track changes; the label elides to fit
  readonly property string sizePolicy: "fixed"
  readonly property int preferredSize: 320

  implicitWidth: iconText.implicitWidth
  implicitHeight: iconText.implicitHeight

  IconTextWidget {
    id: iconText
    anchors.fill: parent

    isVertical: root.isVertical

    icon: MprisController.isPlaying ? "♪" : "⏸"
    text: root.formatTrack()

    backgroundColor: MprisController.isPlaying ? Theme.green : Theme.bg2
  }

  function formatTrack() {
    if (!MprisController.activePlayer)
      return "No player";
    const artist = Utils.truncate(MprisController.trackArtist, 10, "");
    return "󰠃 " + artist + " - " + MprisController.trackTitle;
  }

  PopoutAnchor {
    id: anchor
    popouts: root.popouts
    panel: root.panel
    popoutName: "media-player"
    openDelay: 150
  }
}
