import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

// Square icon button used throughout the overlay editor
StyledRectButton {
  Layout.preferredWidth: Widget.height
  Layout.preferredHeight: Widget.height
  Layout.fillWidth: false
  Layout.fillHeight: false
  opacity: enabled ? 1 : 0.4
  hoverColor: Theme.accent
}
