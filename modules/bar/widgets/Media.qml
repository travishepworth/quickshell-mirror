import QtQuick
import Quickshell
import Quickshell.Services.Mpris

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  // choose a player (prefer spotify; otherwise first playable)
  function pickPlayer() {
    const vals = Mpris.players.values;
    if (!vals || vals.length === 0)
      return null;
    for (let i = 0; i < vals.length; ++i) {
      const p = vals[i];
      if (p.busName && p.busName.indexOf("org.mpris.MediaPlayer2.spotify") !== -1)
        return p;
    }
    // fallback: first one that can actually play
    for (let i = 0; i < vals.length; ++i)
      if (vals[i].canPlay)
        return vals[i];
    return vals[0];
  }

  property var player: pickPlayer()

  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  // react to changes in the players list
  Connections {
    target: Mpris.players
    function onValuesChanged() {
      root.player = root.pickPlayer();
    }
  }

  Rectangle {
    anchors.fill: parent
    color: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? Services.Colors.purple : Services.Colors.border
    radius: App.Settings.borderRadius
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Services.Colors.bg
    text: root.player ? ((root.player.trackArtist || "Unknown") + " - " + (root.player.trackTitle || "Unknown")) : "No player"
    elide: Text.ElideRight
    width: root.width - 16
    horizontalAlignment: Text.AlignHCenter
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      const p = root.player;
      if (!p)
        return;
      if (p.playbackState === MprisPlaybackState.Playing && p.canPause)
        p.pause();
      else if (p.playbackState !== MprisPlaybackState.Playing && p.canPlay)
        p.play();
      else if (p.canTogglePlaying)
        p.togglePlaying();
    }
  }
}
