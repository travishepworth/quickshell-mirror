import QtQuick
import qs.config

// Base for overlay modules (what BaseWidget is for bar modules): the card
// box filling its cell slot. Modules set only what differs, e.g. `color`.
Rectangle {
  // This module's `properties` from config (schema defaults filled in)
  property var properties: ({})

  anchors.fill: parent
  color: Theme.background
  border.color: Theme.foreground
  border.width: Appearance.borderWidth
  radius: Appearance.borderRadius
}
