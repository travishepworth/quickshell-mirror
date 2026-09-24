pragma Singleton
import QtQuick
import qs.services

// Reader for the Lockscreen section: which locker locks the session.
// Named LockscreenConfig because `Lockscreen` is the shell entry type.
QtObject {
  id: root

  readonly property var _c: ConfigManager.config.Lockscreen

  // "quickshell" (built-in) | "hyprlock" (themed by axiom) | "none"
  readonly property string mode: _c.mode
  // What lock buttons run in "none" mode
  readonly property string lockCommand: _c.lockCommand
  readonly property bool showMedia: _c.showMedia
  readonly property bool blurWallpaper: _c.blurWallpaper
}
