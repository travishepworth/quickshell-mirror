pragma Singleton
import QtQuick

/* SettingsMenu holds the settings form's working copy of the config.
 * Edits are applied live (in memory) as they're made; saveChanges()
 * persists them, resetChanges() reloads from disk. */
QtObject {
  id: root

  property ConfigDraft _draft: ConfigDraft {
    id: draft
  }
  readonly property alias localConfig: draft.local
  readonly property alias isDirty: draft.isDirty

  function loadConfig() {
    draft.load();
  }

  function markDirty() {
    draft.changed();
  }

  // Sets one value by path (e.g. ["Appearance", "shape", "radius"]) and
  // applies the working copy live.
  function setValue(path, value) {
    let cur = draft.local;
    for (let i = 0; i < path.length - 1; i++) {
      if (typeof cur[path[i]] !== "object" || cur[path[i]] === null)
        cur[path[i]] = {};
      cur = cur[path[i]];
    }
    cur[path[path.length - 1]] = value;
    applyChanges();
    draft.changed();
  }

  // Applies the in-progress edits to the running config in memory, without writing to disk.
  function applyChanges() {
    ConfigManager.applyConfig(draft.local);
  }

  // Stays dirty if the save is rejected (invalid, or saves are blocked)
  function saveChanges() {
    draft.save();
  }

  function resetChanges() {
    ConfigManager.hardResetConfig();
    draft.load();
  }
}
