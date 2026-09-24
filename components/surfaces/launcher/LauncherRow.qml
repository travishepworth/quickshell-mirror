pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.components.reusable
import qs.config

// One launcher result (a LauncherManager row): an icon or glyph, the title
// (with a command's usage after it), a description line and a hint chip.
// Its height is set by the launcher, which sizes the list by rows.
Item {
  id: root

  required property var modelData
  required property int index
  property bool current: false

  signal hovered
  signal clicked

  readonly property bool _image: !!modelData.image
  readonly property color _titleColor: current ? Theme.accent : Theme.foreground

  // Selection pill with an accent bar
  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: 6
    anchors.rightMargin: 6
    radius: Appearance.borderRadius
    color: root.current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : area.containsMouse ? Theme.backgroundHighlight : "transparent"
    Behavior on color {
      ColorAnimation {
        duration: Appearance.animFast
      }
    }

    Rectangle {
      width: 3
      height: parent.height * 0.5
      radius: 2
      anchors.left: parent.left
      anchors.leftMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      color: Theme.accent
      opacity: root.current ? 1 : 0
      Behavior on opacity {
        NumberAnimation {
          duration: Appearance.animFast
        }
      }
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPositionChanged: root.hovered()
    onClicked: root.clicked()
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 20
    anchors.rightMargin: 18
    spacing: 12

    Item {
      Layout.preferredWidth: LauncherConfig.iconSize
      Layout.preferredHeight: LauncherConfig.iconSize
      Layout.alignment: Qt.AlignVCenter

      Image {
        anchors.fill: parent
        visible: root._image
        source: root._image ? root.modelData.image : ""
        sourceSize: Qt.size(width * 2, height * 2)
        asynchronous: true
        // Pictures (wallpapers) fill their tile; icons keep their shape
        fillMode: root.modelData.kind === "option" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
      }

      Rectangle {
        anchors.fill: parent
        visible: !root._image
        radius: Appearance.borderRadius
        color: root.current ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.backgroundAlt
        Behavior on color {
          ColorAnimation {
            duration: Appearance.animFast
          }
        }

        StyledText {
          anchors.centerIn: parent
          text: root.modelData.glyph ?? ""
          textSize: Math.round(LauncherConfig.iconSize * 0.55)
          textColor: root.modelData.armed ? Theme.error : root._titleColor
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 1

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
          Layout.fillWidth: usage.text === ""
          text: root.modelData.title
          textColor: root._titleColor
          font.weight: Font.Medium
          elide: Text.ElideRight
          Behavior on color {
            ColorAnimation {
              duration: Appearance.animFast
            }
          }
        }

        StyledText {
          id: usage
          Layout.fillWidth: true
          visible: text !== ""
          text: root.modelData.usage ?? ""
          textColor: Theme.foregroundInactive
          textSize: Appearance.fontSize - 2
          elide: Text.ElideRight
        }
      }

      StyledText {
        Layout.fillWidth: true
        visible: LauncherConfig.showDescriptions && text !== ""
        text: root.modelData.subtitle ?? ""
        textColor: Theme.foregroundAlt
        textSize: Appearance.fontSize - 2
        elide: Text.ElideRight
      }
    }

    Rectangle {
      Layout.alignment: Qt.AlignVCenter
      Layout.maximumWidth: root.width * 0.4
      visible: hint.text !== ""
      implicitWidth: hint.implicitWidth + 14
      implicitHeight: hint.implicitHeight + 6
      radius: Appearance.borderRadius
      color: root.modelData.armed ? Theme.error : Theme.backgroundAlt

      StyledText {
        id: hint
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 7
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.modelData.hint ?? ""
        textColor: root.modelData.armed ? Theme.background : Theme.foregroundAlt
        textSize: Appearance.fontSize - 3
        elide: Text.ElideRight
      }
    }
  }
}
