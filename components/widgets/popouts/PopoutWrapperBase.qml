pragma ComponentBehavior: Bound
import QtQuick
import qs.config

/**
 * Shared state machine for any "popout wrapper": open/close/reopen
 * queueing, and centralized dismiss-on-hover-loss timing.
 *
 * Concrete wrappers (bar/popouts/Popouts.qml for bar popouts,
 * TraySubmenuWrapper.qml for submenus, EdgePopout.qml for screen-edge
 * popouts) instantiate this as their root type and add their own
 * PopupWindow, positioning, and content Loader as children, binding
 * `currentItem` to their Loader's item.
 *
 * Deliberately generic on (anchor, data) — no fixed signature per
 * subclass. If a subclass needs extra routing info (e.g. Popout.qml's
 * content-type name), it travels as a field inside `data` rather than
 * as an extra positional argument, so this base never needs overriding.
 */
Item {
  id: root

  property var currentData: null
  property var currentAnchor: null
  property bool occupied: false
  property bool isClosing: false

  // Bind this in the subclass to your Loader's item, e.g.:
  //   currentItem: loader.item ?? null
  property Item currentItem: null

  property var pendingOpenData: null
  property var pendingOpenAnchor: null
  property bool hasPendingOpen: false

  // ---- Centralized dismiss logic ----
  // Content just exposes `hovered` (optionally folding in its own extra
  // "keep me alive" conditions, e.g. an active drag or an open submenu).
  // Timing and dismissal live here, once, for every popout type.
  // `keepAlive` lets a wrapper add hover sources of its own (e.g. an edge
  // trigger strip) without the content having to know about them.
  // dismissDelay/autoDismiss default to the content's values but can be
  // overridden by the wrapper.
  // The widget that opened the popout (`anchorItem` in the payload) counts
  // too, so the popout stays up while the pointer is still on it.
  property bool keepAlive: false
  readonly property bool anchorHovered: currentData?.anchorItem?.hovered ?? false
  readonly property bool contentHovered: (currentItem?.hovered ?? false) || anchorHovered || keepAlive
  property int dismissDelay: currentItem?.dismissDelay ?? PopoutConfig.dismissDelay
  property bool autoDismiss: currentItem?.autoDismiss ?? true

  onContentHoveredChanged: updateDismissTimer()

  function updateDismissTimer() {
    // Nothing to dismiss while closed (content can stay loaded and hover
    // sources can change without the popout being open)
    if (!occupied || !autoDismiss) {
      dismissTimer.stop();
      return;
    }
    if (contentHovered) {
      dismissTimer.stop();
    } else {
      dismissTimer.restart();
    }
  }

  // Subclasses that need to do something extra on dismiss (e.g. clearing
  // an anchor widget's popoutOpen flag) should connect via:
  //   onAboutToDismiss: { ... }
  signal aboutToDismiss

  function requestDismiss() {
    aboutToDismiss();
    closePopout();
  }
  // ---- end centralized dismiss logic ----

  function closePopout() {
    if (isClosing)
      return;
    isClosing = true;
    closeDelayTimer.restart();
  }

  function openPopout(anchor, data) {
    if (isClosing)
      return;
    // Drop any stale countdown from whatever was here before. This must
    // come first: setting `occupied` loads the content synchronously, and
    // stopping afterwards cancelled the countdown its onLoaded started,
    // leaving a popout the pointer never entered open forever.
    dismissTimer.stop();
    currentAnchor = anchor;
    currentData = data;
    occupied = true;
    updateDismissTimer();
  }

  function safeOpenPopout(anchor, data) {
    if (occupied && !isClosing) {
      pendingOpenData = data;
      pendingOpenAnchor = anchor;
      hasPendingOpen = true;
      requestDismiss();
    } else if (!occupied && !isClosing) {
      openPopout(anchor, data);
    } else {
      pendingOpenData = data;
      pendingOpenAnchor = anchor;
      hasPendingOpen = true;
    }
  }

  Timer {
    id: dismissTimer
    interval: root.dismissDelay
    repeat: false
    onTriggered: root.requestDismiss()
  }

  Timer {
    id: closeDelayTimer
    interval: Appearance.animNormal
    repeat: false
    onTriggered: {
      root.occupied = false;
      root.isClosing = false;
      root.currentAnchor = null;
      root.currentData = null;

      if (root.hasPendingOpen) {
        root.hasPendingOpen = false;
        const data = root.pendingOpenData;
        const anchor = root.pendingOpenAnchor;
        root.pendingOpenData = null;
        root.pendingOpenAnchor = null;
        root.openPopout(anchor, data);
      }
    }
  }
}
