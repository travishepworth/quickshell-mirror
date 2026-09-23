pragma Singleton
import QtQuick
import qs.services

// Reader for the Widget section: shared sizing for bar widgets and controls.
QtObject {
  readonly property var _c: ConfigManager.config.Widget

  readonly property int height: _c.height
  readonly property int padding: _c.padding
  readonly property int spacing: _c.spacing
}
