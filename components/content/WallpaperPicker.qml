pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components.reusable
import qs.components.forms
import qs.components.content.base
import qs.components.content.parts

// Wallpapers from Appearance.wallpaperFolder as a scrolling strip (a grid in
// taller slots); clicking one sets it and regenerates the themes from it.
// A tall vertical slot (the Themes page) adds a header, a monitor picker
// and a preview of that monitor's wallpaper, and sets it on the picked
// monitor instead of this overlay's.
Card {
  id: root

  // This overlay's screen
  readonly property string monitor: root.QsWindow.window?.screen?.name ?? ""

  readonly property bool tall: root.shape === "vertical" && root.rows >= 3
  readonly property bool grid: root.rows >= 3

  // The picked monitor while it's connected, else this overlay's
  property string chosenMonitor: ""
  readonly property var screenNames: Quickshell.screens.map(screen => screen.name)
  readonly property string targetMonitor: root.tall && root.screenNames.includes(root.chosenMonitor) ? root.chosenMonitor : root.monitor
  readonly property string wallpaper: Appearance.wallpaperFor(root.targetMonitor)

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    ModuleHeader {
      visible: root.tall
      icon: "\u{F0E09}"
      title: I18n.tr("Wallpaper")

      StyledText {
        visible: ThemeManager.isGenerating
        text: I18n.tr("Generating themes...")
        textColor: Theme.accent
      }
    }

    SchemaComboBox {
      visible: root.tall
      label: I18n.tr("Monitor")
      options: root.screenNames
      currentValue: root.targetMonitor
      optionLabels: root.screenNames.reduce((labels, name) => {
        labels[name] = name === General.primaryMonitor ? I18n.tr("{0} (primary)", name) : name;
        return labels;
      }, {})
      onSelectionChanged: value => root.chosenMonitor = value
    }

    // The picked monitor's wallpaper
    Rectangle {
      visible: root.tall
      Layout.fillWidth: true
      Layout.preferredHeight: width * 10 / 16
      radius: Appearance.borderRadius
      color: Theme.backgroundHighlight
      border.color: Theme.accent
      border.width: 2
      clip: true

      Image {
        anchors.fill: parent
        anchors.margins: parent.border.width
        source: root.tall ? root.wallpaper : ""
        sourceSize: Qt.size(640, 400)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }

      StyledText {
        anchors.centerIn: parent
        visible: root.wallpaper === ""
        text: I18n.tr("No wallpaper set")
        opacity: 0.6
      }
    }

    StyledText {
      visible: root.tall && root.wallpaper !== ""
      Layout.fillWidth: true
      text: root.wallpaper.split("/").pop()
      elide: Text.ElideMiddle
      opacity: 0.7
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      StyledText {
        anchors.centerIn: parent
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: ThemeManager.wallpaperModel.count === 0
        text: I18n.tr("No wallpapers in {0}", Appearance.wallpaperFolder)
        opacity: 0.6
      }

      GridView {
        id: view
        anchors.fill: parent
        clip: true
        flow: root.grid ? GridView.FlowLeftToRight : GridView.FlowTopToBottom
        readonly property real thumbHeight: root.tall ? cellWidth * 10 / 16 : root.grid ? height / Math.max(1, Math.floor(height / 140)) : height
        cellHeight: thumbHeight
        // Two across in the tall layout
        cellWidth: root.tall ? width / 2 : thumbHeight * 16 / 10
        model: ThemeManager.wallpaperModel

        delegate: Item {
          id: thumb
          required property url fileUrl
          required property string filePath
          readonly property bool current: root.wallpaper !== "" && thumb.filePath.endsWith(root.wallpaper.replace("file://", ""))
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
            onClicked: ThemeManager.setWallpaperAndGenerate(thumb.fileUrl, root.targetMonitor)
          }
        }
      }
    }
  }
}
