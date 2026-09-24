pragma Singleton
import QtQuick

/* The settings page's working copy of the config. Edits are applied live
 * (in memory) as they're made; saveChanges() persists them, resetChanges()
 * reloads from disk. Only the settings actually edited are applied and
 * saved, onto the latest config, so changes made elsewhere meanwhile (a
 * theme, a wallpaper, the bar editor) survive.
 *
 * Also keeps the page's own state (category, search), since the page is
 * unloaded whenever the overlay closes. */
QtObject {
  id: root

  property ConfigDraft _draft: ConfigDraft {
    id: draft
  }
  readonly property alias localConfig: draft.local
  readonly property alias savedConfig: draft.saved
  readonly property alias isDirty: draft.isDirty

  // Key paths ("Appearance.font.size") that differ from the saved config;
  // arrays count as one value
  readonly property var changedPaths: _diff(draft.local, draft.saved, [])
  readonly property int changedCount: changedPaths.length

  // The settings page's selected category and search text
  property string category: ""
  property string query: ""

  function _diff(local, saved, path) {
    const isObject = value => value !== null && typeof value === "object" && !Array.isArray(value);
    if (isObject(local) && isObject(saved)) {
      const keys = Object.keys(local).concat(Object.keys(saved).filter(key => !(key in local)));
      return [].concat(...keys.map(key => _diff(local[key], saved[key], path.concat(key))));
    }
    return JSON.stringify(local) === JSON.stringify(saved) ? [] : [path.join(".")];
  }

  function isChanged(path) {
    return root.changedPaths.includes(path.join("."));
  }

  // Whether anything under a path prefix (e.g. a section key) has changed
  function hasChangesUnder(prefix) {
    return root.changedPaths.some(changed => changed === prefix || changed.startsWith(prefix + "."));
  }

  function loadConfig() {
    draft.load();
  }

  // Loads the draft unless it holds unsaved edits (the page is rebuilt
  // whenever the overlay reopens)
  function ensureLoaded() {
    if (!draft.isDirty)
      draft.load();
  }

  function markDirty() {
    draft.changed();
  }

  function _clone(value) {
    return JSON.parse(JSON.stringify(value ?? null));
  }

  function _valueAt(object, path) {
    let cur = object;
    for (const key of path)
      cur = cur?.[key];
    return cur;
  }

  function _setAt(object, path, value) {
    let cur = object;
    for (let i = 0; i < path.length - 1; i++) {
      if (typeof cur[path[i]] !== "object" || cur[path[i]] === null)
        cur[path[i]] = {};
      cur = cur[path[i]];
    }
    cur[path[path.length - 1]] = _clone(value);
  }

  // The latest config with every changed setting from the draft on top
  function _merged() {
    const merged = _clone(ConfigManager.config);
    for (const changed of root.changedPaths) {
      const path = changed.split(".");
      _setAt(merged, path, _valueAt(draft.local, path));
    }
    return merged;
  }

  // Sets one value by path (e.g. ["Appearance", "shape", "radius"]) and
  // applies it live.
  function setValue(path, value) {
    _setAt(draft.local, path, value);
    const live = _clone(ConfigManager.config);
    _setAt(live, path, value);
    ConfigManager.applyConfig(live);
    draft.changed();
  }

  // Stays dirty if the save is rejected (invalid, or saves are blocked)
  function saveChanges() {
    if (!ConfigManager.commit(_merged()))
      return false;
    draft.load();
    return true;
  }

  function resetChanges() {
    ConfigManager.hardResetConfig();
    draft.load();
  }
}
