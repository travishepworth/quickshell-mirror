import QtQuick
import QtQuick.Shapes
import Quickshell

import qs.config
import qs.components.widgets.workspaceContainer

Scope {
  Variants {
    model: Quickshell.screens
    delegate: RoundedBorders {
      property var modelData: modelData
      id: lockScreen
      screen: modelData
    }
  }
}
