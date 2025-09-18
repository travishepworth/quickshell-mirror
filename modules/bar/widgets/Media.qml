import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/" as App

import qs.services

Item {
  id: root
  
  // Orientation support
  property int orientation: App.Settings.orientation  // Accept orientation from parent
  property bool isVertical: orientation === Qt.Vertical
  property bool rotateText: true  // Option to rotate text in vertical mode
  
  // Dynamic dimensions
  height: isVertical ? implicitHeight : App.Settings.widgetHeight
  width: isVertical ? App.Settings.widgetHeight : implicitWidth
  
  implicitWidth: isVertical ? App.Settings.widgetHeight : (contentLoader.item ? contentLoader.item.implicitWidth + App.Settings.widgetPadding * 2 : 100)
  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + App.Settings.widgetPadding * 2 : App.Settings.widgetHeight) : App.Settings.widgetHeight
  
  // Choose a player (prefer spotify; otherwise first playable)
  function pickPlayer() {
    const vals = Mpris.players.values;
    if (!vals || vals.length === 0)
      return null;
    
    // Prefer Spotify
    for (let i = 0; i < vals.length; ++i) {
      const p = vals[i];
      if (p.busName && p.busName.indexOf("org.mpris.MediaPlayer2.spotify") !== -1)
        return p;
    }
    
    // Fallback: first one that can actually play
    for (let i = 0; i < vals.length; ++i)
      if (vals[i].canPlay)
        return vals[i];
    
    return vals[0];
  }
  
  property var player: pickPlayer()
  property bool isPlaying: player && player.playbackState === MprisPlaybackState.Playing
  
  // React to changes in the players list
  Connections {
    target: Mpris.players
    function onValuesChanged() {
      root.player = root.pickPlayer();
    }
  }
  
  Rectangle {
    anchors.fill: parent
    color: isPlaying ? Colors.purple : Colors.border
    radius: App.Settings.borderRadius
  }
  
  Loader {
    id: contentLoader
    anchors.centerIn: parent
    sourceComponent: {
      if (!isVertical) return horizontalContent;
      if (rotateText) return rotatedContent;
      return verticalContent;
    }
    
    Component {
      id: horizontalContent
      Row {
        spacing: 4
        
        Text {
          text: root.isPlaying ? "♪" : "⏸"
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize
          anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
          color: Colors.bg
          text: {
            if (!root.player) return "No player";
            const artist = root.player.trackArtist || "Unknown";
            const title = root.player.trackTitle || "Unknown";
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
          text: root.isPlaying ? "♪" : "⏸"
          color: Colors.bg
          font.family: App.Settings.fontFamily
          font.pixelSize: App.Settings.fontSize * 1.2
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          color: Colors.bg
          text: {
            if (!root.player) return "No\nplayer";
            const artist = root.player.trackArtist || "Unknown";
            const title = root.player.trackTitle || "Unknown";
            
            // Shorter format for vertical
            const shortArtist = artist.substr(0, 10);
            const shortTitle = title.substr(0, 12);
            return shortArtist;  // Just show artist in vertical
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
            if (!root.player) return "";
            const title = root.player.trackTitle || "Unknown";
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
          text: root.isPlaying ? "♪" : "⏸"
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
            if (!root.player) return "No player";
            const artist = root.player.trackArtist || "Unknown";
            const title = root.player.trackTitle || "Unknown";
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
  
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      const p = root.player;
      if (!p) return;
      
      if (p.playbackState === MprisPlaybackState.Playing && p.canPause)
        p.pause();
      else if (p.playbackState !== MprisPlaybackState.Playing && p.canPlay)
        p.play();
      else if (p.canTogglePlaying)
        p.togglePlaying();
    }
  }
}
