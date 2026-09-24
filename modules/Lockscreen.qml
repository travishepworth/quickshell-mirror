import Quickshell

import qs.components.surfaces.lockscreen

Scope {
  Variants {
    model: Quickshell.screens
    delegate: Lockscreen {
      id: lockScreen
      property var modelData: modelData
      screen: modelData
    }
  }
}
