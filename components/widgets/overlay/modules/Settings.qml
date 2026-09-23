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
  property var localConfig: SettingsManager.localConfig

  title: I18n.tr("Settings")
  dirty: SettingsManager.isDirty
  onSave: SettingsManager.saveChanges()
  onReset: SettingsManager.resetChanges()

  Component.onCompleted: {
    SettingsManager.loadConfig();
  }

  onDirtyChanged: {
    console.log("SettingsManager dirty changed to", dirty);
  }

  Item {
    height: Widget.spacing
  }

  // Every section and setting comes from the config schema
  SchemaForm {
    Layout.fillWidth: true
    schema: ConfigManager.configSchema
    config: root.localConfig
    onEdited: (path, value) => SettingsManager.setValue(path, value)
  }

  SavedConfigsSection {
    Layout.leftMargin: Widget.padding
    Layout.rightMargin: Widget.padding
  }
}
