pragma ComponentBehavior: Bound
import QtQuick

/**
 * Drop this into any bar widget that wants to open a bar popout on hover.
 * Handles hover detection, open-delay timing, position/size computation,
 * and the popoutOpen guard flag — all in one place instead of being
 * reimplemented per-widget.
 *
 * Usage:
 *   PopoutAnchor {
 *     id: anchor
 *     popouts: root.popouts
 *     panel: root.panel
 *     popoutName: "workspace-grid"
 *     extraData: ({ monitor: root.monitor, workspaceBase: root.workspaceBase })
 *   }
 *
 * The wrapper (Popout.qml) receives `anchorItem: anchor` as part of the
 * payload automatically, and uses it to check `hovered` (for keepAlive)
 * and to clear `popoutOpen` when it dismisses.
 */
Item {
  id: root

  required property var popouts
  required property var panel
  required property string popoutName

  // Extra fields merged into the payload passed to safeOpenPopout,
  // e.g. { monitor: ..., workspaceBase: ... }
  property var extraData: ({})

  // Debounce before opening on hover. Kept short by default — this isn't
  // meant to prevent accidental opens, just to avoid firing mid-flicker.
  property int openDelay: 10

  // Gate for whether this anchor should respond to hover at all. Lets a
  // parent (e.g. a tray icon with no menu) suppress opening entirely
  // without having to avoid instantiating the anchor at all.
  property bool active: true

  property alias hovered: hoverHandler.hovered
  property bool popoutOpen: false

  anchors.fill: parent

  function open() {
    if (!root.active || !root.popouts || !root.panel || root.popoutOpen)
      return;

    let parentPosition = root.mapToItem(null, 0, 0);
    root.popoutOpen = true;

    let payload = {
      anchorX: parentPosition.x,
      anchorY: parentPosition.y,
      anchorWidth: root.width,
      anchorHeight: root.height,
      // Live reference back to this anchor so the popout wrapper can
      // check whether it's still hovered, and clear popoutOpen on close.
      anchorItem: root
    };

    for (let key in root.extraData) {
      payload[key] = root.extraData[key];
    }

    root.popouts.safeOpenPopout(root.panel, root.popoutName, payload);
  }

  HoverHandler {
    id: hoverHandler
    onHoveredChanged: {
      if (hovered && root.active) {
        if (root.popouts)
          openTimer.restart();
      } else {
        openTimer.stop();
      }
    }
  }

  Timer {
    id: openTimer
    interval: root.openDelay
    repeat: false
    onTriggered: {
      // Guard against a stale fire (mouse already left again), against
      // reopening a popout that's already open for this anchor, and
      // against opening at all if active was toggled off mid-timer.
      if (hoverHandler.hovered && root.active)
        root.open();
    }
  }
}
