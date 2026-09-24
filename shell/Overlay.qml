pragma ComponentBehavior: Bound
import Quickshell

import qs.config
import qs.components.hosts.overlay

// One overlay per screen Overlay.monitors puts it on (see
// General.screensFor); pages only load while it's open
Scope {
  Variants {
    model: General.screensFor(OverlayConfig.monitors)
    delegate: OverlayPanel {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
