pragma ComponentBehavior: Bound
import Quickshell

import qs.config
import qs.components.widgets.overlay

// One overlay per screen in General.screens (the primary monitor unless
// surfaces are on every monitor); pages only load while it's open
Scope {
  Variants {
    model: General.screens
    delegate: OverlayPanel {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
