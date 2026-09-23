pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.widgets.common
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.settings

// The full settings menu, generated from the config schema
PanelCard {
  id: root

  // Local state management
  property var localConfig: SettingsMenu.localConfig

  title: "Settings"
  dirty: SettingsMenu.isDirty
  onSave: SettingsMenu.saveChanges()
  onReset: SettingsMenu.resetChanges()

  Component.onCompleted: {
    SettingsMenu.loadConfig();
  }

  onDirtyChanged: {
    console.log("SettingsMenu dirty changed to", dirty);
  }

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

  SavedConfigsSection {
    Layout.leftMargin: Widget.padding
    Layout.rightMargin: Widget.padding
  }
}
