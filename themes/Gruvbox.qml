pragma Singleton
import QtQuick

QtObject {
    // Background ladder
    readonly property color bg0Hard: "#1d2021"
    readonly property color bg0:     "#282828"
    readonly property color bg0Soft: "#32302f"
    readonly property color bg1:     "#3c3836"
    readonly property color bg2:     "#504945"
    readonly property color bg3:     "#665c54"
    readonly property color bg4:     "#7c6f64"

    // Foreground ladder
    readonly property color fg:   "#ebdbb2"
    readonly property color fg1:  "#d5c4a1"
    readonly property color fg2:  "#bdae93"
    readonly property color fg3:  "#a89984"
    readonly property color gray: "#928374"

    // Accents (original Gruvbox hues)
    readonly property color red:     "#fb4934"
    readonly property color green:   "#b8bb26"
    readonly property color yellow:  "#fabd2f"
    readonly property color blue:    "#83a598"
    readonly property color purple:  "#d3869b"
    readonly property color aqua:    "#8ec07c"
    readonly property color orange:  "#fe8019"
    readonly property color brightRed:    "#cc241d"
    readonly property color brightGreen:  "#98971a"
    readonly property color brightYellow: "#d79921"
    readonly property color brightBlue:   "#458588"
    readonly property color brightPurple: "#b16286"
    readonly property color brightAqua:   "#689d6a"
    readonly property color brightOrange: "#d65d0e"

    readonly property color surface:        bg0
    readonly property color surfaceAlt:     bg1
    readonly property color surfaceAlt2:    bg2
    readonly property color surfaceAlt3:    bg3
    readonly property color overlay:        bg0Soft
    readonly property color border:         bg4
    readonly property color outline:        bg4
    readonly property color shadow:         "#00000080"  // 50% black

    readonly property color textPrimary:    fg
    readonly property color textSecondary:  fg2
    readonly property color textMuted:      gray
    readonly property color textOnAccent:   "#1d2021"

    readonly property color accentPrimary:   brightPurple
    readonly property color accentSecondary: brightAqua
    readonly property color accentTertiary:  brightOrange

    readonly property color success: green
    readonly property color warning: yellow
    readonly property color error:   red
    readonly property color info:    blue
    readonly property color link:    blue
    readonly property color selectionBg: bg2
    readonly property color selectionFg: fg

    readonly property color accent:  accentPrimary
    readonly property color fgColor: fg
    readonly property color bg:      surface
    readonly property color bgAlt:   surfaceAlt
    readonly property color muted:   textMuted
    readonly property color dim:     bg1
    readonly property color magenta: purple
    readonly property color cyan:    aqua

    // --- Utilities ---
    readonly property bool dark: true
    function withAlpha(hex, a) {
        if (!hex || (hex.length !== 7 && hex.length !== 9)) return hex;
        const aa = Math.round(Math.max(0, Math.min(1, a)) * 255).toString(16).padStart(2, "0");
        return hex.length === 7 ? (hex + aa) : (hex.slice(0, 7) + aa);
    }
}
