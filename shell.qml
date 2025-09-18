//@ pragma UseQApplication

import "modules/overview" as Overview
import "modules/panels" as Panels
import "modules/notificationPopup" as NotificationPopup
import "modules/media"
import "modules/osd"
import "modules/workspaces"

import "modules/bar"
import "./services"

import Quickshell
import QtQuick

ShellRoot {
  id: shellRoot

  Bar {
    id: mainBar
  }

  MediaPanel {
    id: mediaPanel
  }

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
