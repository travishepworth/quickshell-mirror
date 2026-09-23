pragma Singleton
import QtQuick
import qs.services

// Overlay: the configured views, plus the card grid's layout constants.
// (Named OverlayConfig because `Overlay` is the module type.)
QtObject {
  readonly property var views: ConfigManager.config.Overlay.views

  // Card grid layout — internal design constants, not user settings.
  // Card radius/border follow Appearance so the overlay matches the shell.
  readonly property int cardUnit: 500
  readonly property int cardSpacing: 20
  readonly property int cardPadding: 12
}
