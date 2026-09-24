import QtQuick
import QtQuick.Shapes
import Quickshell

import qs.config
import qs.components.surfaces.border

Scope {
  Variants {
    model: Quickshell.screens
    delegate: RoundedBorders {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
