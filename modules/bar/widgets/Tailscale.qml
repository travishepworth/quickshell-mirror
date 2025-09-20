import QtQuick
import Quickshell
import Quickshell.Io

import qs.services
import qs.components.widgets

StatusIconWidget {
  command: ["sh", "-c", "tailscale status &>/dev/null"]
  useExitCode: true
  pollInterval: 250
  showLoadingIcon: false

  iconMap: {
    0: "󰳌",
    1: "󰌙"
  }

  colorMap: {
    0: Colors.yellow,
    1: Colors.surfaceAlt3
  }

  defaultIcon: "󰌙"
  iconScale: 1
}
