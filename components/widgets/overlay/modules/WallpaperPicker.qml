pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay

// Wallpapers from ~/Pictures/wallpapers as a scrolling strip (a grid in
// taller slots); clicking one sets it and regenerates the theme from it.
OverlayCard {
  id: root

  readonly property bool grid: root.rows >= 3

  StyledText {
    anchors.centerIn: parent
    visible: ThemeManager.wallpaperModel.count === 0
    text: "No wallpapers in ~/Pictures/wallpapers"
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
      readonly property bool current: Appearance.wallpaper !== "" && thumb.filePath.endsWith(Appearance.wallpaper.replace("file://", ""))
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
        onClicked: ThemeManager.setWallpaperAndGenerate(thumb.fileUrl)
      }
    }
  }
}
