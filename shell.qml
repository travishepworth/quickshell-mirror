//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import qs.shell

ShellRoot {
  id: shellRoot

  Lockscreen {
    id: lockscreen
  }

  Notifications {
    id: notificationPopup
  }

  Overlay {
    id: overlay
  }

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

  AppLauncher {
    id: appLauncher
  }

  PowerMenu {
    id: powerMenu
  }
}
