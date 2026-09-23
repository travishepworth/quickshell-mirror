pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.reusable

// A notification's action buttons (all but the default one), scrolling
// sideways when they don't fit; emits invoked after running one
Flickable {
  id: root

  required property var notification

  signal invoked

  readonly property var actions: (notification.actions ?? []).filter(a => a.identifier !== "default")

  Layout.fillWidth: true
  visible: root.actions.length > 0
  implicitHeight: actionRow.implicitHeight
  contentWidth: actionRow.implicitWidth
  interactive: contentWidth > width
  flickableDirection: Flickable.HorizontalFlick
  clip: true

  RowLayout {
    id: actionRow
    spacing: Widget.spacing

    Repeater {
      model: root.actions

      StyledTextButton {
        required property var modelData
        text: modelData.text
        textPadding: 6
        onClicked: {
          modelData.invoke();
          root.invoked();
        }
      }
    }
  }
}
