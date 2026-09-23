pragma ComponentBehavior: Bound
import Quickshell

import qs.config
import qs.components.widgets.powermenu

// One power menu, on the primary monitor (one per screen all opened at once)
Scope {
  Variants {
    model: Array.from(Quickshell.screens).filter(s => s.name === General.primaryMonitor)
    delegate: PowerMenu {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
