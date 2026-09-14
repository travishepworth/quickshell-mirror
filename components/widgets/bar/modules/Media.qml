pragma ComponentBehavior: Bound

import QtQuick

import qs.services
import qs.config
import qs.components.reusable
import qs.components.methods

Item {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  property bool isVertical: barConfig.vertical

  // Fixed footprint for this widget, expressed as two axes rather than a
  // literal width/height:
  //  - crossAxisSize: the thickness of the widget along the bar's thin
  //    dimension (matches the bar's own thickness either way).
  //  - mainAxisSize: the length of the widget along the bar's long
  //    dimension (holds the icon + track text).
  // Previously bound to iconText.implicitWidth/Height, which shifts every
  // time the track title/artist length changes, nudging neighboring bar
  // widgets. Pinning these to constants keeps the bar layout stable
  // regardless of what's playing — but the two axes still need to swap
  // depending on orientation, same as WorkspaceGrid.qml does.
  readonly property int crossAxisSize: Widget.height
  readonly property int mainAxisSize: 320

  // Tracks whether a popout we opened is still open, mirroring
  // WorkspaceGrid's flicker fix: without this, re-hovering while the
  // popout is already up would tear it down and recreate it.
  property bool popoutOpen: false

  // Exposed so the popout can bind to our hover state directly (passed
  // through as `anchorItem`) instead of relying purely on its own
  // independent dismiss timer.
  property alias hovered: hoverHandler.hovered

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

  // Hover detection only — a HoverHandler (rather than a MouseArea) so it
  // never eats mouse-press events, matching WorkspaceGrid.qml.
  HoverHandler {
    id: hoverHandler
    onHoveredChanged: {
      if (hovered) {
        if (root.popouts) showTimer.restart();
      } else {
        showTimer.stop();
      }
    }
  }

  Timer {
    id: showTimer
    interval: 150
    onTriggered: {
      // Guard against a stale fire and against re-opening a popout
      // that's already open for this widget.
      if (root.popouts && root.panel && hoverHandler.hovered && !root.popoutOpen) {
        let parentPosition = root.mapToItem(null, 0, 0);
        root.popoutOpen = true;
        root.popouts.safeOpenPopout(root.panel, "media-player", {
          anchorX: parentPosition.x,
          anchorY: parentPosition.y,
          anchorWidth: root.width,
          anchorHeight: root.height,
          // Live reference back to this widget so the popout can check
          // whether the anchor is still hovered, and can clear
          // popoutOpen when it actually closes.
          anchorItem: root
        });
      }
    }
  }
}
