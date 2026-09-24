pragma Singleton
import QtQuick
import qs.services

// Reader for the Appearance section. Values are always present: schema
// defaults are filled in by ConfigManager at load time.
QtObject {
  id: root

  readonly property var _c: ConfigManager.config.Appearance

  // --- Theme (UI-owned, set by the theme selector) ---
  readonly property string theme: _c.theme
  // From the active theme, not config: a theme is dark or light
  readonly property bool darkMode: ThemeManager.currentTheme.variant !== "light"
  readonly property string wallpaper: _c.wallpaper
  readonly property bool autoThemeSwitch: _c.autoThemeSwitch

  // --- Font ---
  readonly property string fontFamily: _c.font.family
  readonly property int fontSize: _c.font.size
  readonly property int fontSizeLarge: fontSize + 4

  // --- Shape ---
  readonly property int borderRadius: _c.shape.radius
  readonly property int borderWidth: _c.shape.borderWidth
  readonly property bool screenBorder: _c.shape.screenBorder
  readonly property int screenMargin: _c.shape.screenMargin

  // --- Motion ---
  // Every animation in the shell uses one of these durations, so the
  // single speed setting (and the on/off switch) applies uniformly.
  // Use `duration: Appearance.animNormal` — never a literal.
  readonly property bool animations: _c.motion.enabled
  readonly property real _motionScale: animations ? 100 / _c.motion.speed : 0
  readonly property int animFast: Math.round(100 * _motionScale)    // hover, colour, small state changes
  readonly property int animNormal: Math.round(150 * _motionScale)  // slides, popouts, expanding sections
  readonly property int animSlow: Math.round(300 * _motionScale)    // large panels, lockscreen, pulses
  readonly property int easing: Easing.OutCubic
}
