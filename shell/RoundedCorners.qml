import QtQuick
import QtQuick.Shapes
import Quickshell

import qs.config
import qs.components.surfaces.border

Scope {
  Variants {
    model: Quickshell.screens
    delegate: RoundedBorders {
      id: lockScreen
      property var modelData: modelData
      screen: modelData
    }
  }
}
