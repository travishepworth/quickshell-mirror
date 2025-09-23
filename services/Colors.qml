pragma Singleton

import QtQuick

import qs.config

QtObject {
  // ---- Accents (semantic, derived) ----
  readonly property color accent: Settings.currentTheme.accent          // = accentPrimary
  readonly property color accent2: Settings.currentTheme.accentSecondary
  readonly property color accent3: Settings.currentTheme.accentTertiary

  readonly property color red: Settings.currentTheme.red
  readonly property color green: Settings.currentTheme.green
  readonly property color yellow: Settings.currentTheme.yellow
  readonly property color blue: Settings.currentTheme.blue
  readonly property color purple: Settings.currentTheme.purple
  readonly property color aqua: Settings.currentTheme.aqua
  readonly property color orange: Settings.currentTheme.orange
  readonly property color redAlt: Settings.currentTheme.brightRed
  readonly property color greenAlt: Settings.currentTheme.brightGreen
  readonly property color yellowAlt: Settings.currentTheme.brightYellow
  readonly property color blueAlt: Settings.currentTheme.brightBlue
  readonly property color purpleAlt: Settings.currentTheme.brightPurple
  readonly property color aquaAlt: Settings.currentTheme.brightAqua
  readonly property color orangeAlt: Settings.currentTheme.brightOrange

  // ---- Surfaces (semantic, derived) ----
  readonly property color surface: Settings.currentTheme.surface
  readonly property color surfaceAlt: Settings.currentTheme.surfaceAlt
  readonly property color surfaceAlt2: Settings.currentTheme.surfaceAlt2
  readonly property color surfaceAlt3: Settings.currentTheme.surfaceAlt3
  readonly property color overlay: Settings.currentTheme.overlay
  readonly property color border: Settings.currentTheme.border
  readonly property color outline: Settings.currentTheme.outline

  // Convenience aliases commonly used in UI
  readonly property color bg: Settings.currentTheme.bg        // = surface
  readonly property color bgAlt: Settings.currentTheme.bgAlt     // = surfaceAlt

  // ---- Text (semantic, derived) ----
  readonly property color textPrimary: Settings.currentTheme.textPrimary
  readonly property color textSecondary: Settings.currentTheme.textSecondary
  readonly property color textMuted: Settings.currentTheme.textMuted

  // Common short names mapping to semantics
  readonly property color fg: Settings.currentTheme.textPrimary
  readonly property color muted: Settings.currentTheme.textMuted
  readonly property color dim: Settings.currentTheme.dim

  // ---- Status / UX roles (semantic, derived) ----
  readonly property color success: Settings.currentTheme.success
  readonly property color warning: Settings.currentTheme.warning
  readonly property color error: Settings.currentTheme.error
  readonly property color info: Settings.currentTheme.info
  readonly property color link: Settings.currentTheme.link
  readonly property color selectionBg: Settings.currentTheme.selectionBg
  readonly property color selectionFg: Settings.currentTheme.selectionFg

  readonly property bool dark: Settings.currentTheme.dark

  function withAlpha(hex, a) {
    if (!hex || hex.length !== 7)
      return hex;
    const aa = Math.round(a * 255).toString(16).padStart(2, "0");
    return hex + aa;
  }
}
