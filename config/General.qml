pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Reader for the General section.
QtObject {
  id: root

  readonly property var _c: ConfigManager.config.General

  readonly property string displayName: _c.displayName || Quickshell.env("USER") || "user"
  // Monitor for the lockscreen input, launcher, power menu and overlay
  readonly property string primaryMonitor: _c.primaryMonitor || (Quickshell.screens[0]?.name ?? "")
}
