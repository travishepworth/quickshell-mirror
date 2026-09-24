pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.config

/* Shell manager manages global options and signals */
QtObject {
  signal toggleDarkMode

  signal openPowerMenu
  signal toggleAppLauncher
  signal toggleOverlay
  signal toggleWorkspaceOverlay

  // The screen whose instance of a surface answers a shortcut or IPC call:
  // the focused monitor when surfaces are on every monitor, else the one
  // they're built on
  readonly property string targetScreen: General.monitors === "all" ? (Hyprland.focusedMonitor?.name ?? General.primaryMonitor) : (General.screens[0]?.name ?? "")

  function isTarget(screen) {
    return !!screen && screen.name === targetScreen;
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
