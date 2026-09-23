pragma ComponentBehavior: Bound
import Quickshell

import qs.config
import qs.components.widgets.overlay

// One overlay, on the primary monitor: every page's pollers and graphs run
// per instance, so a disabled copy per extra screen is pure cost
Scope {
  Variants {
    model: Array.from(Quickshell.screens).filter(s => s.name === General.primaryMonitor)
    delegate: OverlayPanel {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
