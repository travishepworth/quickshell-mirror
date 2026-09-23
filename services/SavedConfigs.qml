pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Io

import qs.components.methods
import qs.config
import qs.services

/**
 * Named snapshots of the whole config, one JSON file each in
 * config/user/saved/. A saved file is a plain config.json, so it can also
 * be copied into place by hand. Restoring runs it through ConfigManager's
 * load pipeline, so snapshots from older config versions are migrated.
 */
QtObject {
  id: root

  readonly property string savedDir: Config.configPath + "user/saved/"
  // Newest first; roles: fileBaseName, filePath, fileModified
  readonly property FolderListModel model: _model
  // Last save/restore/delete outcome, for the settings UI
  property string status: ""

  function sanitize(name) {
    return name.trim().replace(/[^A-Za-z0-9 _.-]/g, "_").replace(/^\.+/, "");
  }

  function exists(name) {
    const fileName = sanitize(name) + ".json";
    for (let i = 0; i < _model.count; i++) {
      if (_model.get(i, "fileName") === fileName)
        return true;
    }
    return false;
  }

  // Saves the running config (including unsaved settings edits) under `name`,
  // replacing any existing snapshot of that name.
  function save(name) {
    const fileName = sanitize(name);
    if (fileName === "") {
      root.status = "Enter a name to save as";
      return;
    }
    _run(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", savedDir + fileName + ".json", JSON.stringify(ConfigManager.config, null, 2)], "Saved \"" + fileName + "\"", "Failed to save \"" + fileName + "\"");
  }

  function restore(name) {
    const path = savedDir + name + ".json";
    const content = Utils.getFileContent("file://" + path);
    // JSON.parse(null) is null, which would restore pure defaults
    if (!content) {
      console.error("[SavedConfigs] Could not read", path);
      root.status = "\"" + name + "\" could not be read";
      return;
    }
    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch (e) {
      console.error("[SavedConfigs] Could not parse", path, e);
      root.status = "\"" + name + "\" is not valid JSON";
      return;
    }
    if (!ConfigManager.restoreConfig(parsed)) {
      root.status = "\"" + name + "\" is not a valid config";
      return;
    }
    SettingsMenu.loadConfig();
    root.status = "Restored \"" + name + "\"";
    console.log("[SavedConfigs] Restored", path);
  }

  function remove(name) {
    _run(["rm", "-f", "--", savedDir + name + ".json"], "Deleted \"" + name + "\"", "Failed to delete \"" + name + "\"");
  }

  function _run(command, okText, failText) {
    if (_process.running) {
      root.status = "Busy, try again";
      return;
    }
    _process.okText = okText;
    _process.failText = failText;
    _process.command = command;
    _process.running = true;
  }

  property Process _process: Process {
    property string okText
    property string failText
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "")
          console.error("[SavedConfigs]", text.trim());
      }
    }
    onExited: code => {
      root.status = code === 0 ? okText : failText;
      console.log("[SavedConfigs]", root.status);
    }
  }

  // The folder must exist before FolderListModel watches it, or it never
  // picks up files saved later.
  property Process _mkdir: Process {
    running: true
    command: ["mkdir", "-p", root.savedDir]
    onExited: root._model.folder = "file://" + root.savedDir
  }

  property FolderListModel _model: FolderListModel {
    nameFilters: ["*.json"]
    showDirs: false
    sortField: FolderListModel.Time
  }
}
