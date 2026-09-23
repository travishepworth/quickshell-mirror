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

  // Sized to the track, shrinking (the label elides) down to just the icon
  // when the bar is crowded. The popout pins to the widget's edge on its
  // section's side, so a resize doesn't move it. `layout.size` caps it.
  readonly property string sizePolicy: "elastic"
  readonly property real minimumSize: iconText._iconLength + iconText.padding * 2

  implicitWidth: iconText.implicitWidth
  implicitHeight: iconText.implicitHeight

  IconTextWidget {
    id: iconText
    anchors.fill: parent

    isVertical: root.isVertical

    icon: MprisController.isPlaying ? "♪" : "⏸"
    text: root.formatTrack()

    backgroundColor: Theme.resolveColor(MprisController.isPlaying ? root.properties.playingColor : root.properties.pausedColor)
    foregroundColor: Theme.resolveColor(root.properties.foregroundColor)
  }

  function formatTrack() {
    if (!MprisController.activePlayer)
      return root.properties.idleText;
    const artist = Utils.truncate(MprisController.trackArtist, root.properties.artistLength, "");
    if (!root.properties.showArtist || !artist)
      return MprisController.trackTitle;
    return "󰠃 " + artist + " - " + MprisController.trackTitle;
  }

  PopoutAnchor {
    id: anchor
    popouts: root.popouts
    panel: root.panel
    popoutName: "media-player"
    active: root.properties.showPopout
    openDelay: 150
    alignToSection: true
  }
}
