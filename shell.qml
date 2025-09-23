//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import "modules/bar"
import "modules/osd"
import "modules/common"
import "modules/roundedCorners"
import "modules/overlays"

ShellRoot {
  id: shellRoot

  Bar {
    id: mainBar
  }

  WorkspaceOverlay {
    id: workspaceOverlay
  }

  RoundedCorners {
    id: roundedCorners
  }

  OSD {
    id: osd
  }


  // Panels.RightPanel {
  //   id: rightPanel
  // }

  // NotificationPopup.NotificationPopup {
  //   id: notifications
  // }
}
