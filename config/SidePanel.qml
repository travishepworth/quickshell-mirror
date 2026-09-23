pragma Singleton
import QtQuick
import qs.services

// Reader for the SidePanel section (the right-edge MainMenu popout).
QtObject {
  readonly property bool enabled: ConfigManager.config.SidePanel.enabled
}
