pragma Singleton
import QtQuick

/* SettingsMenu holds the settings form's working copy of the config.
 * Edits are applied live (in memory) as they're made; saveChanges()
 * persists them, resetChanges() reloads from disk. */
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

  // Sets one value by path (e.g. ["Appearance", "shape", "radius"]) and
  // applies the working copy live.
  function setValue(path, value) {
    let cur = localConfig;
    for (let i = 0; i < path.length - 1; i++) {
      if (typeof cur[path[i]] !== "object" || cur[path[i]] === null)
        cur[path[i]] = {};
      cur = cur[path[i]];
    }
    cur[path[path.length - 1]] = value;
    markDirty();
    applyChanges();
    // Re-assign (next tick) so bindings on localConfig see the change;
    // in-place mutation doesn't notify. Deferred to avoid re-entering the
    // binding of the control that made the edit.
    Qt.callLater(() => settingsMenu.localConfig = JSON.parse(JSON.stringify(settingsMenu.localConfig)));
  }

  // Applies the in-progress edits to the running config in memory, without writing to disk.
  function applyChanges() {
    ConfigManager.applyConfig(localConfig);
  }

  // Stays dirty if the save is rejected (invalid, or saves are blocked)
  function saveChanges() {
    if (!ConfigManager.commit(localConfig))
      return;
    _savedConfig = JSON.parse(JSON.stringify(localConfig));
    isDirty = false;
  }

  function resetChanges() {
    console.log("Resetting changes");
    ConfigManager.hardResetConfig();
    loadConfig();
  }
}
