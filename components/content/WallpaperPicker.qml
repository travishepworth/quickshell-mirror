pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components.reusable
import qs.components.content.base

// Wallpapers from Appearance.wallpaperFolder as a scrolling strip (a grid in
// taller slots); clicking one sets it on this overlay's screen and
// regenerates the theme from it.
Card {
  id: root

  readonly property string monitor: root.QsWindow.window?.screen?.name ?? ""

  readonly property bool grid: root.rows >= 3

  StyledText {
    anchors.centerIn: parent
    visible: ThemeManager.wallpaperModel.count === 0
    text: I18n.tr("No wallpapers in {0}", Appearance.wallpaperFolder)
    opacity: 0.6
  }

  GridView {
    id: view
    anchors.fill: parent
    anchors.margins: root.pad
    clip: true
    flow: root.grid ? GridView.FlowLeftToRight : GridView.FlowTopToBottom
    readonly property real thumbHeight: root.grid ? height / Math.max(1, Math.floor(height / 140)) : height
    cellHeight: thumbHeight
    cellWidth: thumbHeight * 16 / 10
    model: ThemeManager.wallpaperModel

    delegate: Item {
      id: thumb
      required property url fileUrl
      required property string filePath
      readonly property string wallpaper: Appearance.wallpaperFor(root.monitor)
      readonly property bool current: thumb.wallpaper !== "" && thumb.filePath.endsWith(thumb.wallpaper.replace("file://", ""))
      width: view.cellWidth
      height: view.cellHeight

      Rectangle {
        anchors.fill: parent
        anchors.margins: Widget.spacing / 2
        radius: Appearance.borderRadius
        color: Theme.backgroundAlt
        border.color: thumb.current ? Theme.accent : thumbArea.containsMouse ? Theme.foreground : "transparent"
        border.width: thumb.current ? 3 : 2
        clip: true

        Image {
          anchors.fill: parent
          anchors.margins: parent.border.width
          source: thumb.fileUrl
          sourceSize: Qt.size(320, 200)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
        }
      }

      MouseArea {
        id: thumbArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ThemeManager.setWallpaperAndGenerate(thumb.fileUrl, root.monitor)
      }
    }
  }
}
