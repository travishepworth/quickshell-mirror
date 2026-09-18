pragma ComponentBehavior: Bound
import QtQuick
import qs.config

/**
 * Shared state machine for any "popout wrapper": open/close/reopen
 * queueing, and centralized dismiss-on-hover-loss timing.
 *
 * Concrete wrappers (Popout.qml for bar popouts, TraySubmenuWrapper.qml
 * for submenus) instantiate this as their root type and add their own
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
  readonly property bool contentHovered: currentItem?.hovered ?? false
  readonly property int dismissDelay: currentItem?.dismissDelay ?? 500
  readonly property bool autoDismiss: currentItem?.autoDismiss ?? true

  onContentHoveredChanged: updateDismissTimer()

  function updateDismissTimer() {
    if (!autoDismiss) {
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
    currentAnchor = anchor;
    currentData = data;
    occupied = true;
    // Fresh content is about to load and starts unhovered — don't let a
    // stale countdown from whatever was here before bleed into it.
    dismissTimer.stop();
  }

  function safeOpenPopout(anchor, data) {
    if (occupied && !isClosing) {
      pendingOpenData = data;
      pendingOpenAnchor = anchor;
      hasPendingOpen = true;
      closePopout();
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
    interval: Appearance.animationDuration
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
