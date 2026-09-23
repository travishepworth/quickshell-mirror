pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay

// Lock, suspend, log out, reboot and power off. The last three ask for a
// second click to confirm.
// properties: { actions: ["lock", "suspend", "logout", "reboot", "poweroff"] }
OverlayCard {
  id: root

  readonly property var defs: ({
      "lock": ["\u{F033E}", I18n.tr("Lock")],
      "suspend": ["\u{F04B2}", I18n.tr("Suspend")],
      "logout": ["\u{F0343}", I18n.tr("Log out")],
      "reboot": ["\u{F0709}", I18n.tr("Reboot")],
      "poweroff": ["\u{F0425}", I18n.tr("Power off")]
    })
  readonly property var actions: (root.properties.actions ?? ["lock", "suspend", "logout", "reboot", "poweroff"]).filter(a => a in root.defs)
  property string armed: ""

  function run(action) {
    if (ShellManager.destructiveActions.includes(action) && root.armed !== action) {
      root.armed = action;
      disarm.restart();
      return;
    }
    root.armed = "";
    ShellManager.sessionAction(action);
  }

  Timer {
    id: disarm
    interval: 3000
    onTriggered: root.armed = ""
  }

  GridLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    columns: root.shape === "vertical" ? 1 : root.shape === "horizontal" ? root.actions.length : Math.ceil(Math.sqrt(root.actions.length))
    columnSpacing: Widget.spacing
    rowSpacing: Widget.spacing

    Repeater {
      model: root.actions

      Rectangle {
        id: button
        required property string modelData
        readonly property bool armed: root.armed === button.modelData
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.borderRadius
        color: button.armed ? Theme.error : buttonArea.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
        border.color: Theme.border
        border.width: Appearance.borderWidth

        ColumnLayout {
          anchors.centerIn: parent
          spacing: 2
          StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.defs[button.modelData][0]
            textColor: button.armed ? Theme.background : Theme.foreground
            textSize: Math.max(Appearance.fontSize, Math.min(button.width, button.height) * 0.3)
          }
          StyledText {
            visible: !root.compact && button.height > Appearance.fontSize * 4
            Layout.alignment: Qt.AlignHCenter
            text: button.armed ? I18n.tr("Confirm?") : root.defs[button.modelData][1]
            textColor: button.armed ? Theme.background : Theme.foreground
            textSize: Appearance.fontSize - 2
          }
        }

        MouseArea {
          id: buttonArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.run(button.modelData)
        }
      }
    }
  }
}
