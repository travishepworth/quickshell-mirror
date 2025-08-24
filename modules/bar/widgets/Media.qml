import QtQuick
import Quickshell
import Quickshell.Services.Mpris

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  property var player: Mpris.players.count > 0 ? Mpris.players.get(0) : null
  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  // react to player list changes
  Connections {
    target: Mpris.players
    function onCountChanged() {
      root.player = Mpris.players.count > 0 ? Mpris.players.get(0) : null;
    }
  }

  Rectangle {
    anchors.fill: parent
    color: (root.player && root.player.isPlaying) ? Services.Colors.accent1 : Services.Colors.border
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
      if (!root.player)
        return;
      if (root.player.isPlaying && root.player.canPause) {
        root.player.pause();
      } else if (!root.player.isPlaying && root.player.canPlay) {
        root.player.play();
      } else if (root.player.canTogglePlaying) {
        root.player.togglePlaying();
      }
    }
  }
}
