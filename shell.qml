//@ pragma UseQApplication
import Quickshell
import QtQuick
import "modules/bar" as Bar
import "services" as Services

ShellRoot {
  Component.onCompleted: {
    Qt.application.font.family = "JetBrains Mono Nerd Font"
    Qt.application.font.pixelSize = 20
  }
  Bar.Bar {
    id: mainBar
  }
}
