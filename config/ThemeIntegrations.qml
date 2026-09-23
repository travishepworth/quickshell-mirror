pragma Singleton
import QtQuick
import qs.services

// Reader for the ThemeIntegrations section (only implemented integrations).
QtObject {
  readonly property var _c: ConfigManager.config.ThemeIntegrations

  readonly property bool kitty: _c.kitty
  readonly property bool k9s: _c.k9s
  readonly property bool cava: _c.cava
}
