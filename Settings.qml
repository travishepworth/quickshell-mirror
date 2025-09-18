pragma Singleton
import QtQml

import qs.themes

QtObject {
    property string theme: "Gruvbox"
    // property bool   animationsEnabled: true
    // property string density: "comfortable"
    property int borderRadius: 4
    property int barHeight: 50

    property int widgetHeight: 32
    property int widgetPadding: 10
    property int widgetSpacing: 6
    property int workspaceCount: 5 // DO NOT CHANGE

    property int resolutionWidth: 3440
    property int resolutionHeight: 1440

    property int screenMargin: 6

    property string fontFamily: "JetBrains Mono Nerd Font"
    property int fontSize: 18

    property bool verticalBar: true
    property bool rightVerticalBar: false
    property int orientation: verticalBar ? Qt.Vertical : Qt.Horizontal

    readonly property var currentTheme: ThemeIndex.get(theme)
}
