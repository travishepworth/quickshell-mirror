pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.config

/* Shell manager manages global options and signals */
QtObject {
  signal openPowerMenu
  signal toggleAppLauncher
  signal toggleOverlay
  signal toggleWorkspaceOverlay
  // Switch the overlay to a page by view type or a view's name ("Themes" and
  // "OverlayEditor" for the pinned pages), e.g. from a settings link
  signal showOverlayPage(string type)
  // Opens the target overlay on a page (a view type, or a view's name)
  signal openOverlayPage(string type)

  // The screen whose instance of a surface answers a shortcut or IPC call:
  // the focused monitor when surfaces are on every monitor, else the one
  // they're built on
  readonly property string targetScreen: General.monitors === "all" ? (Hyprland.focusedMonitor?.name ?? General.primaryMonitor) : (General.screens[0]?.name ?? "")

  // The target for a surface with its own `monitors` setting (see
  // General.screensFor); "general" is targetScreen
  function targetFor(mode) {
    if (mode === "primaryBar")
      return Bar.primaryMonitor;
    if (mode === "focused")
      return Hyprland.focusedMonitor?.name ?? General.primaryMonitor;
    return targetScreen;
  }

  function isTarget(screen, mode) {
    return !!screen && screen.name === (mode ? targetFor(mode) : targetScreen);
  }

  // Windows a full-screen surface's focus grab lets input through to on
  // their screen: the bars and their popouts, so they stay usable while the
  // overlay is open. `{ window, screen }` (a screen name)
  property var grabPartners: []

  function registerGrabPartner(window, screenName) {
    grabPartners = grabPartners.filter(p => p.window !== window).concat([
      {
        window,
        screen: screenName ?? ""
      }
    ]);
  }

  function unregisterGrabPartner(window) {
    grabPartners = grabPartners.filter(p => p.window !== window);
  }

  function grabPartnersFor(screen) {
    return grabPartners.filter(p => !!screen && p.screen === screen.name).map(p => p.window);
  }

  // Session actions, shared by the power menu and the overlay's Session
  // module. The destructive ones ask for a second click first.
  readonly property var destructiveActions: ["logout", "reboot", "poweroff"]

  function sessionAction(action) {
    switch (action) {
    case "lock":
      LockManager.lock();
      break;
    case "suspend":
      Quickshell.execDetached(["systemctl", "suspend"]);
      break;
    case "hibernate":
      Quickshell.execDetached(["systemctl", "hibernate"]);
      break;
    case "logout":
      Hyprland.dispatch("exit");
      break;
    case "reboot":
      Quickshell.execDetached(["systemctl", "reboot"]);
      break;
    case "poweroff":
      Quickshell.execDetached(["systemctl", "poweroff"]);
      break;
    default:
      console.warn("[ShellManager] Unknown session action:", action);
    }
  }
}
