import QtQuick
import Quickshell
import Quickshell.Io
import "root:/" as App
import qs.services
import qs.modules.media

Item {
  id: root

  // Orientation support
  property int orientation: App.Settings.orientation
  property bool isVertical: orientation === Qt.Vertical
  property bool rotateText: true

  // Find shellRoot and access mediaPanel through it
  property var mediaPanel: {
    // Look in parent's children (siblings)
    if (parent && parent.parent) {
      for (let i = 0; i < parent.parent.children.length; i++) {
        let child = parent.parent.children[i];
        if (child && child.objectName === "mediaPanel") {
          return child;
        }
      }
    }
    return null;
  }

  // Dynamic dimensions
  height: isVertical ? implicitHeight : App.Settings.widgetHeight
  width: isVertical ? App.Settings.widgetHeight : implicitWidth

  implicitWidth: isVertical ? App.Settings.widgetHeight : (contentLoader.item ? contentLoader.item.implicitWidth + App.Settings.widgetPadding * 2 : 100)
  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + App.Settings.widgetPadding * 2 : App.Settings.widgetHeight) : App.Settings.widgetHeight

  // Background
  Rectangle {
    anchors.fill: parent
    color: Mpris.isPlaying ? Colors.purple : Colors.border
    radius: App.Settings.borderRadius
  }

  // Content loader for orientation
  Loader {
    id: contentLoader
    anchors.centerIn: parent
    sourceComponent: {
      if (!isVertical)
        return horizontalContent;
      if (rotateText)
        return rotatedContent;
      return verticalContent;
    }

    Component {
      id: horizontalContent
      Row {
        spacing: 4

        Text {
          text: Mpris.isPlaying ? "♪" : "⏸"
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          color: Colors.bg
          text: {
            if (!Mpris.activePlayer)
              return "No player";
            const artist = Mpris.trackArtist;
            const title = Mpris.trackTitle;
            return artist.substr(0, 20) + " - " + title.substr(0, 30);
          }
          elide: Text.ElideRight
          width: Math.min(implicitWidth, root.width - 32)
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }

    Component {
      id: verticalContent
      Column {
        spacing: 2

        Text {
          text: Mpris.isPlaying ? "♪" : "⏸"
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize * 1.2
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          color: Colors.bg
          text: {
            if (!Mpris.activePlayer)
              return "No\nplayer";
            const artist = Mpris.trackArtist;
            return artist.substr(0, 10);
          }
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize * 0.8
          anchors.horizontalCenter: parent.horizontalCenter
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          width: root.width - 8
          maximumLineCount: 2
        }

        Text {
          color: Colors.bg
          text: {
            if (!Mpris.activePlayer)
              return "";
            const title = Mpris.trackTitle;
            return title.substr(0, 12);
          }
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize * 0.7
          opacity: 0.8
          anchors.horizontalCenter: parent.horizontalCenter
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
          width: root.width - 8
        }
      }
    }

    Component {
      id: rotatedContent
      Item {
        implicitWidth: Math.max(iconText.height, mediaText.height) + 8
        implicitHeight: iconText.width + mediaText.width + 8

        Text {
          id: iconText
          text: Mpris.isPlaying ? "♪" : "⏸"
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
          rotation: -90
          anchors {
            centerIn: parent
            verticalCenterOffset: -(mediaText.width / 2) - 4
          }
        }

        Text {
          id: mediaText
          color: Colors.bg
          text: {
            if (!Mpris.activePlayer)
              return "No player";
            const artist = Mpris.trackArtist;
            const title = Mpris.trackTitle;
            return artist.substr(0, 15) + " - " + title.substr(0, 20);
          }
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize * 0.9
          rotation: -90
          anchors {
            centerIn: parent
            verticalCenterOffset: (iconText.width / 2) + 4
          }
        }
      }
    }
  }

  // Hover timer to open panel
  Timer {
    id: hoverTimer
    interval: 300
    onTriggered: {
      // Use direct function call if available, fallback to IPC
      MediaController.open();
    }
  }

  // Mouse interaction
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    onEntered: {
      hoverTimer.start();
    }

    onExited: {
      hoverTimer.stop();
    }

    onClicked: {
      // Cancel hover timer and toggle immediately
      hoverTimer.stop();
      MediaController.toggle();
    }
  }
}
