pragma Singleton
import QtQuick

import Quickshell.Io

import qs.components.methods
import qs.config

/* ConfigManager handles loading, saving, and monitoring the configuration file */
QtObject {
  id: configManager

  // --- Public ---
  readonly property var config: _config
  readonly property var theme: _theme
  readonly property var configSchema: _configSchema
  readonly property string configDir: "../config/user/"
  readonly property string configFile: "config.json"

  // True while config.json on disk is unusable (invalid, or present but
  // unreadable). The shell keeps running on the last good config (or schema
  // defaults at startup) and refuses to save, so the file can't be
  // overwritten before it is fixed. Restoring a saved config clears it.
  readonly property bool savesBlocked: _savesBlocked

  /**
     * @brief Requests a change to the current theme.
     * This is the official way to change the theme. It updates the internal
     * config object and triggers a save and reload cycle.
     * @param themeName The full name of the theme (e.g., "catppuccin-mocha" or "generated/pywal-1").
     */
  function setTheme(themeName) {
    if (_config.Appearance.theme === themeName) {
      console.log("[ConfigManager] Theme '" + themeName + "' is already set. No change needed.");
      return;
    }
    console.log("[ConfigManager] Setting theme to '" + themeName + "'");
    _config.Appearance.theme = themeName;
    saveConfig();
  }

  /**
     * @brief Requests a change to the wallpaper path in the config.
     * @param wallpaperUrl The full file URL of the wallpaper.
     */
  function setWallpaper(wallpaperUrl) {
    if (_config.Appearance.wallpaper === wallpaperUrl)
      return;
    console.log("[ConfigManager] Setting wallpaper to", wallpaperUrl);
    _config.Appearance.wallpaper = wallpaperUrl;
    Utils.executeWallpaperScript(wallpaperUrl);
    saveConfig();
  }

  /**
     * @brief Saves the current configuration state to config.json and triggers a reload.
     * @return true if it was written.
     */
  function saveConfig() {
    if (_savesBlocked) {
      console.warn("[ConfigManager] config.json is unusable; not saving until it is fixed (or a saved config is restored).");
      return false;
    }
    try {
      if (!_validateConfig(configManager._config)) {
        console.error("[ConfigManager] Failed to validate config against schema. Aborting save.");
        return false;
      }
      _write(configManager._config);
      console.log("[ConfigManager] Saved config.json.");
      forceReload();
      return true;
    } catch (e) {
      console.error("[ConfigManager] An error occurred while saving the configuration:", e);
      return false;
    }
  }

  /**
   * @brief Replaces the running config with `object` and saves it, running
   * it through the load pipeline (prune/defaults/validate) first.
   * @return true if it was valid and written; on false nothing changed.
   */
  function commit(object) {
    if (_savesBlocked) {
      console.warn("[ConfigManager] config.json is unusable; not saving until it is fixed (or a saved config is restored).");
      return false;
    }
    const prepared = _prepareConfig(object);
    if (!prepared) {
      console.error("[ConfigManager] Rejected config: it does not validate against the schema.");
      return false;
    }
    configManager._config = prepared.config;
    return saveConfig();
  }

  /**
   * @brief Applies a full configuration object to memory without saving to disk.
   */
  function applyConfig(object) {
    _loadObjectToConfig(object);
  }

  /**
   * @brief Applies a theme to enabled integrated tools
   */
  function themeIntegrations(themeName = Appearance.theme) {
    var scriptPath = Config.scriptsPath;
    var themePath = Config.themePath + themeName + ".json";
    const integrations = [
      {
        enabled: ThemeIntegrations.kitty,
        process: _kittyProcess,
        script: "theme_kitty.sh"
      },
      {
        enabled: ThemeIntegrations.cava,
        process: _cavaProcess,
        script: "theme_cava.sh"
      },
      {
        enabled: ThemeIntegrations.k9s,
        process: _k9sProcess,
        script: "theme_k9s.sh"
      }
    ];
    for (const integration of integrations) {
      // A busy integration only skips itself, not the ones after it
      if (!integration.enabled || integration.process.running)
        continue;
      integration.process.command = [scriptPath + integration.script, themePath];
      integration.process.running = true;
    }
  }

  /**
   * @brief Replaces the whole config with a parsed config object (e.g. a
   * saved configuration), running it through the same migrate/prune/
   * defaults/validate pipeline as config.json, then saves it. This is an
   * explicit replacement, so it also lifts savesBlocked.
   * @return true if the config was valid and saved.
   */
  function restoreConfig(object) {
    const prepared = _prepareConfig(object);
    if (!prepared) {
      console.error("[ConfigManager] Restored config is invalid, keeping the current one.");
      return false;
    }
    configManager._savesBlocked = false;
    configManager._config = prepared.config;
    return saveConfig();
  }

  /**
     * @brief Manually triggers the file checker, simulating a file-system change.
     */
  function forceReload() {
    _fileHashes = {};
    _checkForChanges();
  }

  /**
     * @brief Discards in-memory edits by reloading config.json from disk.
     * Keeps the current config if the file is unusable.
     */
  function hardResetConfig() {
    const result = _readConfig();
    if (result.status === "ok")
      configManager._config = result.config;
  }

  // --- Private Implementation ---
  Component.onCompleted: {
    console.log("[ConfigManager] ♻ ConfigManager service started.");
    _checkForChanges();
  }

  // Loaded eagerly (synchronous reads) so the config readers never see a
  // partially-filled config: every key has its schema default from the
  // very first evaluation.
  property var _configSchema: _loadSchema()
  property var _config: _initialConfig(_loadSchema())
  property var _theme: ({})
  property bool _savesBlocked: false
  // Whether the running config came from config.json (vs schema defaults)
  property bool _haveFileConfig: false

  property string _configSchemaPath: "../config/json/config.schema.json"
  property string _configPath: configManager.configDir + configManager.configFile

  // FileView only for writing the config
  property FileView _configFileView: FileView {
    path: Qt.resolvedUrl(configManager.configDir + configManager.configFile)
    blockWrites: true
    atomicWrites: true
    onSaveFailed: error => {
      console.error("[ConfigManager] Failed to save config.json. Error: " + FileViewError.toString(error));
    }
  }

  // Change notification for the config and active theme files. The slow
  // poll is only a safety net in case a watch is lost (e.g. to an editor's
  // atomic rename).
  property FileView _configWatch: FileView {
    path: Qt.resolvedUrl(configManager._configPath)
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload();
      configManager._checkForChanges();
    }
  }

  property FileView _themeWatch: FileView {
    path: Qt.resolvedUrl("../config/themes/" + configManager._config.Appearance.theme + ".json")
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload();
      configManager._checkForChanges();
    }
  }

  property var _fileHashes: ({})
  // "name:hash" of the theme the integrations were last run for
  property string _integratedTheme: ""

  property Timer _pollTimer: Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: configManager._checkForChanges()
  }

  function _hashString(str) {
    var hash = 0;
    if (!str || str.length === 0)
      return hash;
    for (var i = 0; i < str.length; i++) {
      var chars = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + chars;
      hash = hash & hash;
    }
    return hash.toString();
  }

  function _getFileContent(filepath) {
    return Utils.getFileContent(Qt.resolvedUrl(filepath));
  }

  function _loadSchema() {
    var content = _getFileContent(_configSchemaPath);
    console.log("[ConfigManager] Loading config schema from", _configSchemaPath);
    if (content) {
      try {
        return JSON.parse(content);
      } catch (e) {
        console.error("[ConfigManager] Failed to parse config.schema.json:", e);
      }
    }
    return {};
  }

  function _validateConfig(config, schema = _configSchema) {
    if (SchemaValidation.validateAgainstSchema(config, schema)) {
      console.log("[ConfigManager] Schema validation passed.");
      return true;
    } else {
      console.error("[ConfigManager] Schema validation failed.");
      return false;
    }
  }

  /**
   * Load pipeline: parse → migrate old layouts → drop unknown keys → fill
   * schema defaults → validate.
   * @return { status, content, config, migrated }; status is "ok",
   *   "empty" (missing, unreadable or mid-write) or "invalid".
   */
  function _readConfig(schema = _configSchema) {
    const content = _getFileContent(configDir + configFile);
    if (!content)
      return {
        status: "empty",
        content: ""
      };

    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch (e) {
      console.error("[ConfigManager] Failed to parse config.json:", e);
      return {
        status: "invalid",
        content: content
      };
    }

    const prepared = _prepareConfig(parsed, schema);
    if (!prepared)
      return {
        status: "invalid",
        content: content
      };
    return {
      status: "ok",
      content: content,
      config: prepared.config,
      migrated: prepared.migrated
    };
  }

  // The config for the very first evaluation. Anything but a good file
  // gives schema defaults; the first _checkForChanges() then decides
  // whether that means first run (write defaults) or blocking saves.
  function _initialConfig(schema) {
    console.log("[ConfigManager] Loading configuration from", configDir + configFile);
    const result = _readConfig(schema);
    if (result.status !== "ok")
      return SchemaValidation.applyDefaults({}, schema);
    // Remember what was loaded, so the first check doesn't load it again
    if (_fileHashes)
      _fileHashes.config = _hashString(result.content);
    if (result.migrated)
      Qt.callLater(() => _write(result.config));
    console.log("[ConfigManager] Configuration loaded and validated successfully.");
    return result.config;
  }

  // Migrate → prune unknown keys → fill defaults → validate a parsed config.
  // Returns { config, migrated }, or null if the result is invalid.
  function _prepareConfig(parsed, schema = _configSchema) {
    const migration = ConfigMigration.migrate(parsed);
    if (migration.migrated) {
      console.log("[ConfigManager] Migrated config to version", ConfigMigration.currentVersion + ":");
      migration.changes.forEach(change => console.log("  - " + change));
    }
    if (Object.keys(migration.secrets).length > 0)
      SecretsManager.store(migration.secrets);

    const config = migration.config;
    const removed = SchemaValidation.pruneUnknown(config, schema);
    removed.forEach(path => console.warn("[ConfigManager] Ignoring unknown config key:", path));

    const filled = SchemaValidation.applyDefaults(config, schema);
    if (!_validateConfig(filled, schema))
      return null;
    return {
      config: filled,
      migrated: migration.migrated
    };
  }

  // Writes a config object to disk as-is (no reload); used after migration
  function _write(config) {
    _configFileView.setText(JSON.stringify(config, null, 2));
  }

  function _loadObjectToConfig(object) {
    if (_validateConfig(object)) {
      // Deep clone so this is always a new object reference, otherwise QML
      // won't emit a change signal when the same localConfig object (mutated
      // in place across edits) is re-applied, and live updates after the
      // first change silently stop working.
      configManager._config = JSON.parse(JSON.stringify(object));
    }
  }

  function _blockSaves(reason) {
    if (_savesBlocked)
      return;
    _savesBlocked = true;
    console.error("[ConfigManager] config.json is " + reason + "; keeping the current config and blocking saves until it is fixed.");
  }

  // An empty read is either a missing file (first run: write defaults) or a
  // file caught mid-write / unreadable. Only a real "missing" writes.
  property Process _existsCheck: Process {
    command: ["test", "-e", decodeURIComponent(Qt.resolvedUrl(configManager._configPath).toString().replace("file://", ""))]
    onExited: exitCode => {
      if (exitCode !== 0) {
        console.log("[ConfigManager] No config.json found, writing defaults.");
        configManager._savesBlocked = false;
        configManager._write(SchemaValidation.applyDefaults({}, configManager._configSchema));
      } else if (!configManager._haveFileConfig) {
        // Never loaded a good file: running on defaults, so don't save them over it
        configManager._blockSaves("empty or unreadable");
      }
    }
  }

  function _checkConfigFile() {
    const content = _getFileContent(_configPath);
    if (!content) {
      // Keep whatever is running; _existsCheck decides whether this is a
      // first run (write defaults) or a file we must not overwrite
      if (!_haveFileConfig && !_existsCheck.running)
        _existsCheck.running = true;
      return false;
    }
    const hash = _hashString(content);
    if (_fileHashes.config === hash) {
      // Same content as the last good load (e.g. a broken edit reverted)
      _haveFileConfig = true;
      _savesBlocked = false;
      delete _fileHashes.invalid;
      return false;
    }
    // Already reported this exact broken content
    if (_fileHashes.invalid === hash)
      return false;

    const result = _readConfig();
    if (result.status !== "ok") {
      _fileHashes.invalid = hash;
      _blockSaves("invalid");
      return false;
    }
    if (_fileHashes.config !== undefined)
      console.log("[ConfigManager] Config file changed, reloading...");
    _fileHashes.config = hash;
    delete _fileHashes.invalid;
    _haveFileConfig = true;
    _savesBlocked = false;
    configManager._config = result.config;
    if (result.migrated)
      Qt.callLater(() => _write(result.config));
    return true;
  }

  function _loadTheme(themeName) {
    var path = "../config/themes/" + themeName + ".json";
    var content = _getFileContent(path);
    if (content) {
      try {
        content = JSON.parse(content);
        _config.Appearance.darkMode = content.variant === "dark";
        if (_config.Appearance.darkMode !== Appearance.darkMode) {
          saveConfig();
        }
        return content;
      } catch (e) {
        console.error("[ConfigManager] Failed to load theme:", themeName, e);
      }
    }
    console.error("[ConfigManager] Theme not found, Falling back to default theme.");
    return {
      name: "Default (fallback)",
      variant: "dark",
      colors: Utils.getDefaultColors(),
      semantic: Utils.getDefaultSemanticColors()
    };
  }

  function _checkForChanges() {
    const currentThemeName = configManager._config.Appearance.theme;
    const hasConfigChanged = _checkConfigFile();

    const newThemeName = configManager._config.Appearance.theme;
    const themeContent = _getFileContent("../config/themes/" + newThemeName + ".json");
    if (themeContent) {
      const themeHash = _hashString(themeContent);
      const themeKey = "theme_" + newThemeName;

      // Reload theme if its content changed OR if the config itself changed (which might mean the theme *name* changed)
      if (_fileHashes[themeKey] !== themeHash || hasConfigChanged) {
        if (_fileHashes[themeKey] !== undefined && !hasConfigChanged)
          console.log("[ConfigManager] Theme file '" + newThemeName + "' changed, reloading...");
        _fileHashes[themeKey] = themeHash;
        configManager._theme = _loadTheme(newThemeName);
      }

      // Re-theme integrated tools only when the theme itself changed (not
      // on every save), and not for the theme already active at startup
      const integrated = newThemeName + ":" + themeHash;
      if (_integratedTheme !== "" && _integratedTheme !== integrated)
        themeIntegrations(newThemeName);
      _integratedTheme = integrated;
    }

    // Clear old theme hashes if theme name changed in config
    if (currentThemeName !== newThemeName) {
      for (var key in _fileHashes) {
        if (key.startsWith("theme_") && key !== "theme_" + newThemeName) {
          delete _fileHashes[key];
        }
      }
    }
  }

  // --- Process Launchers for Integrated Tools ---
  property Process _k9sProcess: Process {
    id: k9sProcess
    stderr: StdioCollector {
      id: k9sStderr
    }
    stdout: StdioCollector {
      id: k9sStdout
    }
  }

  property Process _cavaProcess: Process {
    id: cavaProcess
    stderr: StdioCollector {
      id: cavaStderr
    }
    stdout: StdioCollector {
      id: cavaStdout
    }
  }

  property Process _kittyProcess: Process {
    id: kittyProcess
    stderr: StdioCollector {
      id: kittyStderr
    }
    stdout: StdioCollector {
      id: kittyStdout
    }
  }
}
