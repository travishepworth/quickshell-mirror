// components/widgets/BarPanel.qml
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick

import qs.services
import qs.modules.bar.widgets as Widgets
import qs.modules.bar.popouts
import qs.components.widgets.reusable

PanelWindow {
  id: root

  required property var modelData
  property string display: Settings.display
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
        showMedia: modelData.name === "DP-1"
      }
    }

    rightGroup: Component {
      RightGroup {
        screen: root.screen
        showTray: modelData.name === Settings.display
        showBattery: Settings.display === "eDP-1"
      }
    }

    leftCenterGroup: centerGroups.leftCenterGroup

    rightCenterGroup: Component {
      Loader {
        sourceComponent: centerGroups.rightCenterGroup
        onLoaded: {
          if (item) {
            item.showSystemMonitor = modelData.name === "DP-1";
          }
        }
      }
    }
  }

  CenterGroup {
    id: centerGroups
  }
}
