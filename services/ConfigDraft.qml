import QtQuick

// A working copy of one config section for an editor (settings menu, bar
// editor, overlay editor). Edits mutate `local` in place, then call
// changed(); nothing reaches the running config or disk until save().
// Not a singleton: each editor service owns one.
QtObject {
  id: draft

  // Key path of the section in the config, e.g. ["Bars"]; [] is all of it
  property var path: []

  // Plain values, filled by load(): a binding here would reset the draft
  // on every config change
  property var local: null
  property var saved: null
  property bool isDirty: false

  Component.onCompleted: load()

  function _clone(value) {
    return JSON.parse(JSON.stringify(value ?? null));
  }

  function _read() {
    let value = ConfigManager.config;
    for (const key of draft.path)
      value = value?.[key];
    return value;
  }

  // Start over from the current config
  function load() {
    draft.local = _clone(_read());
    draft.saved = _clone(draft.local);
    draft.isDirty = false;
  }

  // After mutating `local` in place: update isDirty, and re-assign it (next
  // tick) so bindings on it see the change, since in-place mutation doesn't
  // notify. Deferred so it doesn't re-enter the binding of the control
  // that made the edit.
  function changed() {
    draft.isDirty = JSON.stringify(draft.local) !== JSON.stringify(draft.saved);
    Qt.callLater(() => draft.local = _clone(draft.local));
  }

  // Merges `local` onto the LATEST config (so settings edited elsewhere
  // meanwhile survive) and commits it. Returns false, staying dirty, if
  // ConfigManager rejects it.
  function save() {
    let merged = _clone(draft.local);
    if (draft.path.length > 0) {
      merged = _clone(ConfigManager.config);
      let cur = merged;
      for (let i = 0; i < draft.path.length - 1; i++)
        cur = cur[draft.path[i]];
      cur[draft.path[draft.path.length - 1]] = _clone(draft.local);
    }
    if (!ConfigManager.commit(merged))
      return false;
    draft.saved = _clone(draft.local);
    draft.isDirty = false;
    return true;
  }
}
