//@ pragma UseQApplication

import "modules/overview" as Overview
import "modules/panels" as Panels
import "modules/notificationPopup" as NotificationPopup

import "modules/bar"
import "./services"

import Quickshell
import QtQuick

ShellRoot {
  id: shellRoot

  // Services.NotificationService {
  //   id: notificationService
  // }
  //
  Bar {
    id: mainBar
  }

  // Loader { active: true; component: Bar{}}

  // Panels.RightPanel {
  //   id: rightPanel
  // }

  // NotificationPopup.NotificationPopup {
  //   id: notifications
  // }
}
