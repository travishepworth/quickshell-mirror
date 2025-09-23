pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.config
import qs.components.widgets.bar.declarations as Widgets
import qs.components.widgets.popouts
import qs.components.widgets.reusable

PanelWindow {
  id: root

  required property var modelData
  property string display: Settings.display.primary
  property int barHeight: Settings.barHeight
  property int barWidth: Settings.verticalBar ? Settings.barHeight : 0

  screen: modelData
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusiveZone: Settings.verticalBar ? barWidth : barHeight
  WlrLayershell.namespace: "qs-bar"

  anchors {
    top: Settings.verticalBar ? true : (modelData.name === display)
    bottom: Settings.verticalBar ? true : (modelData.name === "DP-2")
    left: Settings.verticalBar ? !Settings.rightVerticalBar : true
    right: Settings.verticalBar ? Settings.rightVerticalBar : true
  }

  visible: if (modelData.name === display)
    true
  else if (modelData.name === "DP-2" && !Settings.singleMonitor)
    true
  else
    false

  implicitHeight: Settings.verticalBar ? 0 : barHeight
  implicitWidth: Settings.verticalBar ? barWidth : 0

  PopoutWrapper {
    id: popouts
    screen: root.screen
  }

  FloatingTrigger {
    id: menuTrigger
    popouts: popouts
    screen: root.screen
    panel: root
  }

  BarContainer {
    anchors.fill: parent
    screen: root.screen
    popouts: popouts

    workspaces: Component {
      Widgets.Workspaces {
        screen: root.screen
        popouts: popouts
        orientation: Settings.verticalBar ? Qt.Vertical : Qt.Horizontal
        panel: root
      }
    }

    leftGroup: Component {
      LeftGroup {
        screen: root.screen
        showMedia: Settings.display.primary === "DP-1"
      }
    }

    rightGroup: Component {
      RightGroup {
        screen: root.screen
        showTray: root.screen.name === Settings.display.primary
        showBattery: Settings.display.primary === "eDP-1"
      }
    }

    leftCenterGroup: centerGroups.leftCenterGroup

    rightCenterGroup: Component {
      Loader {
        sourceComponent: centerGroups.rightCenterGroup
        onLoaded: {
          if (item) {
            item.showSystemMonitor = root.screen.name === "DP-1";
          }
        }
      }
    }
  }

  CenterGroup {
    id: centerGroups
  }
}
