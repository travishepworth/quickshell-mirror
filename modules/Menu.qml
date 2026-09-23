pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.components.widgets.popouts
import qs.components.widgets.menu
import qs.config as Cfg

Item {
  anchors.fill: parent

  Variants {
    model: Quickshell.screens

    delegate: EdgePopout {
      id: root
      required property ShellScreen modelData

      screen: modelData
      available: Cfg.Menu.enablePanel
      edge: Cfg.Bar.Right
      position: 0.5
      triggerLength: modelData.height
      wantsKeyboardFocus: contentItem?.wantsKeyboardFocus ?? false

      content: Component {
        MainMenu {
          panelId: "mainMenu"
          // The attached surface draws the frame
          borderColor: "transparent"
          customHeight: root.maxBoxLength - Cfg.Widget.spacing * 2
        }
      }
    }
  }
}
