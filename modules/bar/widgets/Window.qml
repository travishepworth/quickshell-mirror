import QtQuick
import Quickshell
import Quickshell.Wayland

import "root:/" as App
import "root:/services" as Services

Item {
  id: root
  height: App.Settings.widgetHeight
  implicitWidth: label.implicitWidth + App.Settings.widgetPadding * 2

  Rectangle {
    anchors.fill: parent
    color: Services.Colors.accent2
    radius: App.Settings.borderRadius
  }

  Text {
    id: label
    anchors.centerIn: parent
    color: Services.Colors.bg
    font.family: App.Settings.fontFamily
    font.pixelSize: App.Settings.fontSize
    text: (ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.title) || "—"
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    width: root.width - 16
  }
}

