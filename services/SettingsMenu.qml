pragma Singleton
import QtQuick

// TODO: move this to the configManager
QtObject {
  id: settingsMenu

  property var localConfig: ({})
  property var _savedConfig: ({})
  property bool isDirty: false

  Component.onCompleted: {
    loadConfig();
  }

  function loadConfig() {
    localConfig = JSON.parse(JSON.stringify(ConfigManager.config));
    _savedConfig = JSON.parse(JSON.stringify(ConfigManager.config));
    isDirty = false;
  }

  function checkDirty() {
    return JSON.stringify(localConfig) !== JSON.stringify(_savedConfig);
  }

  function markDirty() {
    settingsMenu.isDirty = checkDirty();
  }

  // Applies the in-progress edits to the running config in memory, without writing to disk.
  function applyChanges() {
    ConfigManager.applyConfig(localConfig);
  }

  function saveChanges() {
    ConfigManager.applyConfig(localConfig);
    ConfigManager.saveConfig();
    _savedConfig = JSON.parse(JSON.stringify(localConfig));
    isDirty = false;
  }

  function resetChanges() {
    console.log("Resetting changes");
    ConfigManager.hardResetConfig();
    loadConfig();
  }
}
