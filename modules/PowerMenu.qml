pragma ComponentBehavior: Bound
import Quickshell

import qs.config
import qs.components.widgets.powermenu

// A power menu per screen in General.screens; the target screen's opens
Scope {
  Variants {
    model: General.screens
    delegate: PowerMenu {
      required property ShellScreen modelData
      screen: modelData
    }
  }
}
