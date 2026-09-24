import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import qs.components.surfaces.launcher
import qs.config

Scope {
  Variants {
    model: General.screens
    delegate: Launcher {
      id: appLauncher
      property var modelData: modelData
      screen: modelData
    }
  }
}
