//pragma Singleton
import Quickshell
import Quickshell.io

Singleton {
  id: root

  function gotoWorkspace(index) {
    gotoWorkspaceProcess.arguments[1] = index
    gotoWorkspaceProcess.start()
  }

  Process {
    id: gotoWorkspaceProcess
    command: ["/home/travmonkey/.config/hypr/scripts/gotoWorkspace.sh", ""]
  }
}
