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
  // Language for the shell's text, dates and clock (see I18n): "en" | "ja"
  readonly property string language: _c.language
  readonly property string primaryMonitor: _c.primaryMonitor || (Quickshell.screens[0]?.name ?? "")
}
