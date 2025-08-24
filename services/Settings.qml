pragma Singleton
import QtQuick
import "root:/themes" as Themes

QtObject {
    // ---- Add more user settings here over time ----
    property string theme: "Gruxbox"   // only setting for now

    // Resolved theme object (auto-updates when 'theme' changes)
    readonly property var currentTheme: Themes.ThemeIndex.get(theme)
}
