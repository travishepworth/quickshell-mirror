import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import qs.components.reusable
import qs.config
import qs.services

PanelWindow {
  id: rootWindow

  required property var screen
  property int buttonSize: 200
  property int iconSize: 60
  property int gridSpacing: 20
  property real backgroundDim: 0.5

  property string iconLock: " "
  property string iconLogout: " "
  property string iconPoweroff: " "
  property string iconSuspend: " "
  property string iconReboot: " "
  property string iconHibernate: " "

  // [action, icon] in grid order
  readonly property var actions: [["lock", iconLock], ["logout", iconLogout], ["poweroff", iconPoweroff], ["suspend", iconSuspend], ["reboot", iconReboot], ["hibernate", iconHibernate]]
  // A destructive action waiting for its confirming second click
  property string armed: ""

  function run(action) {
    if (ShellManager.destructiveActions.includes(action) && armed !== action) {
      armed = action;
      disarm.restart();
      return;
    }
    armed = "";
    shown = false;
    ShellManager.sessionAction(action);
  }

  Timer {
    id: disarm
    interval: 3000
    onTriggered: rootWindow.armed = ""
  }

  Connections {
    target: ShellManager
    function onOpenPowerMenu() {
      if (ShellManager.isTarget(rootWindow.screen))
        rootWindow.toggle();
    }
    // Locking from anywhere closes the menu, so it isn't still up on unlock
    function onLockScreen() {
      rootWindow.shown = false;
    }
  }

  screen: rootWindow.screen
  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }
  color: "transparent"
  focusable: true

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.layer: WlrLayer.Overlay

  property bool shown: false

  function toggle() {
    shown = !shown;
  }
  onShownChanged: armed = ""

  IpcHandler {
    target: "powermenu"
    enabled: ShellManager.isTarget(rootWindow.screen)
    function toggle() {
      rootWindow.toggle();
    }
    // Not "show": `qs ipc call <target> show` is taken by the CLI
    function open() {
      if (!rootWindow.shown)
        rootWindow.toggle();
    }
    function close() {
      if (rootWindow.shown)
        rootWindow.toggle();
    }
  }

  HyprlandFocusGrab {
    id: grab
    active: rootWindow.shown
    windows: [rootWindow]
    onCleared: rootWindow.shown = false
  }

  visible: shown
  onClosed: shown = false

  Rectangle {
    anchors.fill: parent
    // Keys can't attach to the window itself
    focus: true
    Keys.onEscapePressed: rootWindow.toggle()
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, rootWindow.backgroundDim)
    MouseArea {
      anchors.fill: parent
      onClicked: rootWindow.toggle()
    }
  }

  // Main container
  StyledContainer {
    id: menuContainer
    anchors.centerIn: parent
    width: gridLayout.implicitWidth + 40
    height: gridLayout.implicitHeight + 40

    backgroundColor: Theme.background
    borderColor: Theme.border
    borderWidth: Appearance.borderWidth

    GridLayout {
      id: gridLayout
      anchors.centerIn: parent
      columns: 3
      rowSpacing: gridSpacing
      columnSpacing: gridSpacing

      Repeater {
        model: rootWindow.actions

        Rectangle {
          id: iconButton
          required property var modelData
          readonly property string action: modelData[0]
          readonly property bool armed: rootWindow.armed === action

          implicitWidth: rootWindow.buttonSize
          implicitHeight: rootWindow.buttonSize

          color: armed ? Theme.error : buttonMouseArea.containsMouse ? Theme.accent : Theme.backgroundHighlight
          border.color: Theme.border
          border.width: Appearance.borderWidth
          radius: Appearance.borderRadius

          Behavior on color {
            ColorAnimation {
              duration: Appearance.animNormal
              easing.type: Easing.InOutQuad
            }
          }

          StyledText {
            anchors.centerIn: parent
            text: iconButton.modelData[1]
            textColor: iconButton.armed || buttonMouseArea.containsMouse ? Theme.background : Theme.foreground
            textSize: rootWindow.iconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          StyledText {
            visible: iconButton.armed
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Widget.padding * 2
            text: I18n.tr("Confirm?")
            textColor: Theme.background
          }

          MouseArea {
            id: buttonMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rootWindow.run(iconButton.action)
          }
        }
      }
    }
  }
}
