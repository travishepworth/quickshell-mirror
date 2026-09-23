pragma Singleton
import QtQuick
import qs.services

// Reader for the Icons section. (Named IconConfig: `Icons` is shadowed in
// files importing Quickshell service modules.)
QtObject {
  // App name → icon path/URL for apps whose icon doesn't resolve
  readonly property var overrides: ConfigManager.config.Icons.overrides
}
