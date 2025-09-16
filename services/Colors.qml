pragma Singleton

import QtQuick
import "root:/" as App

QtObject {
  // ---- Accents (semantic, derived) ----
  readonly property color accent: App.Settings.currentTheme.accent          // = accentPrimary
  readonly property color accent2: App.Settings.currentTheme.accentSecondary
  readonly property color accent3: App.Settings.currentTheme.accentTertiary

  readonly property color red: App.Settings.currentTheme.red
  readonly property color green: App.Settings.currentTheme.green
  readonly property color yellow: App.Settings.currentTheme.yellow
  readonly property color blue: App.Settings.currentTheme.blue
  readonly property color purple: App.Settings.currentTheme.purple
  readonly property color aqua: App.Settings.currentTheme.aqua
  readonly property color orange: App.Settings.currentTheme.orange
  readonly property color redAlt: App.Settings.currentTheme.brightRed
  readonly property color greenAlt: App.Settings.currentTheme.brightGreen
  readonly property color yellowAlt: App.Settings.currentTheme.brightYellow
  readonly property color blueAlt: App.Settings.currentTheme.brightBlue
  readonly property color purpleAlt: App.Settings.currentTheme.brightPurple
  readonly property color aquaAlt: App.Settings.currentTheme.brightAqua
  readonly property color orangeAlt: App.Settings.currentTheme.brightOrange

  // ---- Surfaces (semantic, derived) ----
  readonly property color surface: App.Settings.currentTheme.surface
  readonly property color surfaceAlt: App.Settings.currentTheme.surfaceAlt
  readonly property color surfaceAlt2: App.Settings.currentTheme.surfaceAlt2
  readonly property color surfaceAlt3: App.Settings.currentTheme.surfaceAlt3
  readonly property color overlay: App.Settings.currentTheme.overlay
  readonly property color border: App.Settings.currentTheme.border
  readonly property color outline: App.Settings.currentTheme.outline

  // Convenience aliases commonly used in UI
  readonly property color bg: App.Settings.currentTheme.bg        // = surface
  readonly property color bgAlt: App.Settings.currentTheme.bgAlt     // = surfaceAlt

  // ---- Text (semantic, derived) ----
  readonly property color textPrimary: App.Settings.currentTheme.textPrimary
  readonly property color textSecondary: App.Settings.currentTheme.textSecondary
  readonly property color textMuted: App.Settings.currentTheme.textMuted

  // Common short names mapping to semantics
  readonly property color fg: App.Settings.currentTheme.textPrimary
  readonly property color muted: App.Settings.currentTheme.textMuted
  readonly property color dim: App.Settings.currentTheme.dim

  // ---- Status / UX roles (semantic, derived) ----
  readonly property color success: App.Settings.currentTheme.success
  readonly property color warning: App.Settings.currentTheme.warning
  readonly property color error: App.Settings.currentTheme.error
  readonly property color info: App.Settings.currentTheme.info
  readonly property color link: App.Settings.currentTheme.link
  readonly property color selectionBg: App.Settings.currentTheme.selectionBg
  readonly property color selectionFg: App.Settings.currentTheme.selectionFg

  readonly property bool dark: App.Settings.currentTheme.dark

  function withAlpha(hex, a) {
    if (!hex || hex.length !== 7)
      return hex;
    const aa = Math.round(a * 255).toString(16).padStart(2, "0");
    return hex + aa;
  }
}
