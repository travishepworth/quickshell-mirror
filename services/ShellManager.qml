pragma Singleton
import QtQuick

/* Shell manager manages global options and signals */
QtObject {
  signal toggleDarkMode()

  signal lockScreen()
  signal openPowerMenu()
  signal toggleAppLauncher()
  signal toggleOverlay()
  signal toggleWorkspaceOverlay()
}
