pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
  id: root

  function gotoWorkspace(index) {
    gotoWorkspaceProcess.command = ["/home/travmonkey/.config/hypr/scripts/gotoWorkspace.sh", String(index)]
    gotoWorkspaceProcess.running = true
  }

  Process {
    id: gotoWorkspaceProcess
    command: ["/home/travmonkey/.config/hypr/scripts/gotoWorkspace.sh", ""]
  }
}
