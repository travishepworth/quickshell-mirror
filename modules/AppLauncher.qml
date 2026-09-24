import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import qs.components.reusable
import qs.components.widgets.applauncher
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
