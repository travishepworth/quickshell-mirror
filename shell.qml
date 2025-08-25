//@ pragma UseQApplication
import Quickshell
import QtQuick
import "modules/bar" as Bar
import "modules/overview" as Overview
import "services" as Services

ShellRoot {
  Bar.Bar {
    id: mainBar
  }
}
