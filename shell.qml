//@ pragma UseQApplication

import "modules/overview" as Overview
import "modules/panels" as Panels
import "modules/notificationPopup" as NotificationPopup
import "modules/media"

import "modules/bar"
import "./services"

import Quickshell
import QtQuick

ShellRoot {
  id: shellRoot
  property alias mediaPanel: mediaPanel

  Bar {
    id: mainBar
  }

  MediaPanel {
    id: mediaPanel
  }

  // Loader { active: true; component: Bar{}}

  // Panels.RightPanel {
  //   id: rightPanel
  // }

  // NotificationPopup.NotificationPopup {
  //   id: notifications
  // }
}
