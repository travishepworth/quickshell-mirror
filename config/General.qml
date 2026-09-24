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
  // "primary" | "all": the screens the overlay, launcher, power menu,
  // workspace overlay and OSD are built on
  readonly property string monitors: _c.monitors
  readonly property var screens: {
    const all = Array.from(Quickshell.screens);
    if (root.monitors === "all")
      return all;
    const primary = all.filter(s => s.name === root.primaryMonitor);
    return primary.length > 0 ? primary : all.slice(0, 1);
  }

  // The screens a surface with its own `monitors` setting is built on:
  // "general" (the above) | "primaryBar" (the primary bar's monitor) |
  // "focused" (every screen, opening on the focused one)
  function screensFor(mode) {
    const all = Array.from(Quickshell.screens);
    if (mode === "focused")
      return all;
    if (mode === "primaryBar") {
      const primary = all.filter(s => s.name === Bar.primaryMonitor);
      return primary.length > 0 ? primary : all.slice(0, 1);
    }
    return root.screens;
  }
}
