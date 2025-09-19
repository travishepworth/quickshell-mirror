import QtQuick
import Quickshell

import qs.services
import qs.modules.bar.popouts

Item {
  id: root

  required property var screen

  // Pass through to the actual bar
  property int barHeight: Settings.barHeight
  property int barWidth: Settings.verticalBar ? Settings.barHeight : undefined

  // implicitWidth: Settings.verticalBar ? barWidth : screen.width     // Fix: use screen.width for horizontal
  implicitHeight: Settings.verticalBar ? screen.height : barHeight  // Fix: use screen.height for vertical
  implicitWidth: 1000

  PopoutWrapper {
    id: popoutWrapper
    screen: root.screen
  }

  // Load the actual bar - PASS THE PROPERTIES!
  Loader {
    Bar {
      id: mainBar
      popouts: popoutWrapper    // Pass popouts
    }
  }
}
