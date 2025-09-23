import QtQuick
import Quickshell
import Quickshell.Io

import qs.services
import qs.components.widgets.reusable

IconTextWidget {
  id: root

  icon: Mpris.isPlaying ? "♪" : "⏸"
  text: formatTrack()

  maxTextLength: 30
  backgroundColor: Mpris.isPlaying ? Colors.purple : Colors.border

  function formatTrack() {
    if (!Mpris.activePlayer)
      return "No player";
    const artist = Mpris.trackArtist;
    const title = Mpris.trackTitle;
    return artist + " - " + title;
  }

}
