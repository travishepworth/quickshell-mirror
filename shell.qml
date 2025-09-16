//@ pragma UseQApplication
import Quickshell
import QtQuick
import "modules/bar" as Bar
import "modules/overview" as Overview
import "modules/panels" as Panels
import "modules/notificationPopup" as NotificationPopup
import "services" as Services

ShellRoot {
  id: shellRoot

  // Services.NotificationService {
  //   id: notificationService
  // }
  //
  Bar.Bar {
    id: mainBar
  }

  Panels.RightPanel {
    id: rightPanel
  }

  // NotificationPopup.NotificationPopup {
  //   id: notifications
  // }
}
