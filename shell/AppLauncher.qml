import QtQuick
import Quickshell

import qs.components.surfaces.launcher
import qs.config

Scope {
  Variants {
    model: General.screens
    delegate: Launcher {
      required property var modelData
      screen: modelData
    }
  }
}
