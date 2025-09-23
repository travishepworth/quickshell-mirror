//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/overview" as Overview
import "modules/panels" as Panels
import "modules/notificationPopup" as NotificationPopup
import "modules/media"
import "modules/osd"
import "modules/common"
import "modules/workspaces"

import "modules/bar/popouts"

import "modules/bar"
import "./services"

import Quickshell
import QtQuick

ShellRoot {
  id: shellRoot

  // BarWrapper {
  //   id: mainBar
  //   // popouts: popoutWrapper
  //   screen: shellRoot.currentScreen
  // }
  Bar {
    id: mainBar
  }

  // Bar2 {
  //   id: uhh
  // }

  RoundedCorners {
    id: roundedCorners
  }

  // MediaPanel {
  //   id: mediaPanel
  // }

  OSD {
    id: osd
  }

  WorkspaceOverlay {
    id: workspaceOverlay
  }

  // Loader { active: true; component: Bar{}}

  // Panels.RightPanel {
  //   id: rightPanel
  // }

  // NotificationPopup.NotificationPopup {
  //   id: notifications
  // }
}
