pragma Singleton
import QtQml
import "root:/themes" as Themes

QtObject {
    property string theme: "Gruvbox"
    // property bool   animationsEnabled: true
    // property string density: "comfortable"
    property int borderRadius: 4
    property int barHeight: 50

    property int widgetHeight: 32
    property int widgetPadding: 10
    property int widgetSpacing: 6

    property int resolutionWidth: 3440
    property int resolutionHeight: 1440

    property int screenMargin: 6

    property string fontFamily: "JetBrains Mono Nerd Font"
    property int fontSize: 18

    readonly property var currentTheme: Themes.ThemeIndex.get(theme)
}
