pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

QtObject {
  id: root

  // The currently selected player based on priority
  property var activePlayer: pickPlayer()
  property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

  // Album art management
  property string artUrl: activePlayer?.trackArtUrl ?? ""
  property string artFileName: artUrl ? Qt.md5(artUrl) + ".jpg" : ""
  property string artFilePath: artFileName ? `/tmp/quickshell-media-art/${artFileName}` : ""
  property bool artDownloaded: false

  // Track info helpers
  property string trackTitle: activePlayer?.trackTitle ?? "No track"
  property string trackArtist: activePlayer?.trackArtist ?? "Unknown artist"
  property real position: activePlayer?.position ?? 0
  property real length: activePlayer?.length ?? 0
  property real progress: length > 0 ? position / length : 0

  // Player selection logic
  function pickPlayer() {
    const vals = Mpris.players.values;
    if (!vals || vals.length === 0)
      return null;

    // Priority 1: Spotify
    for (let i = 0; i < vals.length; ++i) {
      const p = vals[i];
      if (p.busName && p.busName.indexOf("org.mpris.MediaPlayer2.spotify") !== -1)
        return p;
    }

    // Priority 2: Any playing player
    for (let i = 0; i < vals.length; ++i) {
      if (vals[i].playbackState === MprisPlaybackState.Playing)
        return vals[i];
    }

    // Priority 3: Any player that can play
    for (let i = 0; i < vals.length; ++i) {
      if (vals[i].canPlay)
        return vals[i];
    }

    // Fallback: first player
    return vals[0];
  }

  function updateSeekPosition(x) {
    if (activePlayer.canSeek && Mpris.length > 0) {
      dragPosition = Math.max(0, Math.min(1, x / width));
      // Update visual feedback immediately
      progress = dragPosition;
    }
  }
  function commitSeek(ratio) {
    if (activePlayer && activePlayer.canSeek && length > 0) {
      ratio = Math.max(0, Math.min(1, ratio));
      let seekPosition = ratio * length;

      // Try different seek methods for better compatibility
      if (activePlayer.position !== undefined) {
        // Try setting position directly first
        activePlayer.position = seekPosition;
      } else if (activePlayer.seek) {
        // Fall back to seek method (some players use relative seek)
        let currentPos = position || 0;
        let seekOffset = seekPosition - currentPos;
        activePlayer.seek(seekOffset);
      }
    }
  }

  // Player controls
  function playPause() {
    if (!activePlayer)
      return;

    if (activePlayer.playbackState === MprisPlaybackState.Playing && activePlayer.canPause)
      activePlayer.pause();
    else if (activePlayer.playbackState !== MprisPlaybackState.Playing && activePlayer.canPlay)
      activePlayer.play();
    else if (activePlayer.canTogglePlaying)
      activePlayer.togglePlaying();
  }

  function next() {
    activePlayer?.next();
  }

  function previous() {
    activePlayer?.previous();
  }

  // Time formatting helper
  function formatTime(seconds) {
    if (!seconds || seconds < 0)
      return "0:00";
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return mins + ":" + (secs < 10 ? "0" : "") + secs;
  }

  // Update active player when players change
  property var _playersConnection: Connections {
    target: Mpris.players
    function onValuesChanged() {
      root.activePlayer = root.pickPlayer();
    }
  }

  // Handle album art changes
  onArtUrlChanged: {
    console.log("Art URL changed to", artUrl);
    if (artUrl && artUrl.length > 0) {
      artDownloaded = false;
      _artDownloader.running = true;
    } else {
      artDownloaded = false;
    }
  }

  signal artReady

  // TODO: still fails infrequently, some form of race condition
  // Likely the service just needs to be fully rewritten
  // Album art downloader
  property var _artDownloader: Process {
    id: artDownloader
    running: false
    command: ["bash", "-c", `mkdir -p /tmp/quickshell-media-art && [ -f '${root.artFilePath}' ] || curl -sSL '${root.artUrl}' -o '${root.artFilePath}'`]
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        root.artDownloaded = true;
        root.artReady();
      }
    }
  }

  // Timer {
  //   id: artReadyTimer
  //   interval: 100
  //   repeat: false
  //   onTriggered: {
  //     root.artReady();
  //   }
  // }

  // Position update timer for smooth progress
  property var _positionTimer: Timer {
    running: root.isPlaying
    interval: 500
    repeat: true
    onTriggered: {
      if (root.activePlayer) {
        root.activePlayer.positionChanged();
      }
    }
  }
}
