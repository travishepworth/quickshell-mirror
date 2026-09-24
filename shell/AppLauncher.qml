import QtQuick
import Quickshell

import qs.components.surfaces.launcher
import qs.config

Scope {
  Variants {
    model: General.screensFor(LauncherConfig.monitors)
    delegate: Launcher {
      required property var modelData
      screen: modelData
    }
  }
}
