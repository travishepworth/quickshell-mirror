pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.components.widgets.common
import qs.components.widgets.overlay.modules.settings

/**
 * Main settings menu component - fits in square grid cell
 */
Rectangle {
  id: root
  color: Theme.background
  radius: Appearance.borderRadius
  anchors.fill: parent
  border.color: Theme.border
  border.width: Appearance.borderWidth

  // Local state management
  property var localConfig: SettingsMenu.localConfig
  property bool isDirty: SettingsMenu.isDirty

  Component.onCompleted: {
    SettingsMenu.loadConfig();
  }

  onIsDirtyChanged: {
    console.log("SettingsMenu dirty changed to", isDirty);
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Widget.padding
    spacing: 0

    SettingsHeader {}

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      Layout.topMargin: Widget.spacing / 2
      Layout.bottomMargin: Widget.spacing / 2
      color: Theme.border
      opacity: 0.3
    }

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

      ColumnLayout {
        width: parent.parent.width - Widget.padding * 2
        spacing: Widget.spacing * 2

        Item {
          height: Widget.spacing
        }

        // Every section and setting comes from the config schema
        SchemaForm {
          Layout.fillWidth: true
          schema: ConfigManager.configSchema
          config: root.localConfig
          onEdited: (path, value) => SettingsMenu.setValue(path, value)
        }
      }
    }
  }
}
