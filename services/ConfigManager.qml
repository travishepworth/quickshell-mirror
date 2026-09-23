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
  readonly property string configFile: "config.json" // TODO: load all config files from dir (if necessary)

  /**
     * @brief Requests a change to the current theme.
     * This is the official way to change the theme. It updates the internal
     * config object and triggers a save and reload cycle.
     * @param themeName The full name of the theme (e.g., "catppuccin-mocha" or "generated/pywal-1").
     */
  function setTheme(themeName) {
    if (_config.Appearance) {
      if (_config.Appearance.theme === themeName) {
        console.log("[ConfigManager] Theme '" + themeName + "' is already set. No change needed.");
        return;
      }
      console.log("[ConfigManager] Setting theme to '" + themeName + "'");
      _config.Appearance.theme = themeName;
      console.log("[ConfigManager] New theme: ", Appearance.theme);
      console.log("[ConfigManager] Saving configuration and triggering reload...");
      saveConfig();
    } else {
      console.error("[ConfigManager] Cannot set theme, _config.Appearance is not defined.");
    }
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
     */
  function saveConfig() {
    console.log("[ConfigManager] Writing current configuration to config.json...");
    try {
      var configString = JSON.stringify(configManager._config, null, 2);
      if (!_validateConfig(configManager._config)) {
        console.error("[ConfigManager] Failed to validate config against schema. Aborting save.");
        return;
      }
      _configFileView.setText(configString);
      console.log("[ConfigManager] Save successful.");
      forceReload();
      themeIntegrations();
    } catch (e) {
      console.error("[ConfigManager] An error occurred while saving the configuration:", e);
    }
  }

  /**
   * @brief Applies a full configuration object to memory without saving to disk.
   */
  function applyConfig(object) {
    _loadObjectToConfig(object);
    console.log("[ConfigManager] Applied configuration object to memory.");
  }

  /**
   * @brief Applies the currrent theme to enabled integrated tools
   */
  function themeIntegrations() {
    var scriptPath = Config.scriptsPath;
    var themePath = Config.themePath + Appearance.theme + ".json";
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
   * defaults/validate pipeline as config.json, then saves it.
   * @return true if the config was valid and saved.
   */
  function restoreConfig(object) {
    const prepared = _prepareConfig(object);
    if (!prepared) {
      console.error("[ConfigManager] Restored config is invalid, keeping the current one.");
      return false;
    }
    configManager._config = prepared.config;
    saveConfig();
    return true;
  }

  /**
     * @brief Manually triggers the file checker, simulating a file-system change.
     */
  function forceReload() {
    console.log("⟳ Manual reload triggered");
    _fileHashes = {};
    _checkForChanges();
  }

  /**
     * @brief Resets the configuration to default values by reloading from disk.
     * This does not modify the config file on disk, but reloads the in-memory
     * configuration from the existing config.json file.
     */
  function hardResetConfig() {
    console.log("[ConfigManager] Performing hard reset of configuration to defaults.");
    configManager._config = _loadConfig();
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
  property var _config: _loadConfig(_loadSchema())
  property var _theme: ({})

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

  property int _pollInterval: 1000
  property var _fileHashes: ({})

  property Timer _pollTimer: Timer {
    interval: configManager._pollInterval
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
        console.error("Failed to parse config_schema.json:", e);
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
   * schema defaults → validate. A migrated config is written back once
   * (and any API keys found in it go to the secrets file instead). A
   * missing or unusable file falls back to pure schema defaults.
   */
  function _loadConfig(schema = _configSchema) {
    console.log("[ConfigManager] Loading configuration from", _configPath);
    const defaults = SchemaValidation.applyDefaults({}, schema);
    var content = _getFileContent(configManager.configDir + configManager.configFile);
    if (!content) {
      console.warn("[ConfigManager] No config.json found, writing defaults.");
      Qt.callLater(() => _write(defaults));
      return defaults;
    }

    // Remember what was loaded, so the first poll doesn't load it again
    if (_fileHashes)
      _fileHashes.config = _hashString(content);

    let parsed;
    try {
      parsed = JSON.parse(content);
    } catch (e) {
      console.error("[ConfigManager] Failed to parse config.json, using defaults:", e);
      return defaults;
    }

    const prepared = _prepareConfig(parsed, schema);
    if (!prepared) {
      console.error("[ConfigManager] config.json is invalid, using defaults until it is fixed.");
      return defaults;
    }

    if (prepared.migrated)
      Qt.callLater(() => _write(prepared.config));
    console.log("[ConfigManager] Configuration loaded and validated successfully.");
    return prepared.config;
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
      Secrets.store(migration.secrets);

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
        console.error("Failed to load theme:", themeName, e);
      }
    }
    console.error("[ThemeManager] Theme not found, Falling back to default theme.");
    return {
      name: "Default (fallback)",
      variant: "dark",
      colors: Utils.getDefaultColors(),
      semantic: Utils.getDefaultSemanticColors()
    };
  }

  function _checkForChanges() {
    var hasConfigChanged = false;
    var hasThemeChanged = false;
    var currentThemeName = configManager._config.Appearance ? configManager._config.Appearance.theme : "default";

    var configContent = _getFileContent(configManager.configDir + configManager.configFile);
    if (configContent !== null) {
      var configHash = _hashString(configContent);
      if (_fileHashes.config !== configHash) {
        if (_fileHashes.config !== undefined)
          console.log("✓ Config file changed, reloading...");
        _fileHashes.config = configHash;
        configManager._config = _loadConfig();
        hasConfigChanged = true;
      }
    }

    var newThemeName = configManager._config.Appearance ? configManager._config.Appearance.theme : "default";
    var themeContent = _getFileContent("../config/themes/" + newThemeName + ".json");
    if (themeContent !== null) {
      var themeHash = _hashString(themeContent);
      var themeKey = "theme_" + newThemeName;

      // Reload theme if its content changed OR if the config itself changed (which might mean the theme *name* changed)
      if (_fileHashes[themeKey] !== themeHash || hasConfigChanged) {
        if (_fileHashes[themeKey] !== undefined && !hasConfigChanged)
          console.log("✓ Theme file '" + newThemeName + "' changed, reloading...");
        _fileHashes[themeKey] = themeHash;
        configManager._theme = _loadTheme(newThemeName); // Update internal property
        hasThemeChanged = true;
      }
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
  // universal component proessess
  property Component processComponent: Component {
    Process {
      id: genericProcess
      running: false

      stdout: StdioCollector {
        id: genericStdout
        onStreamFinished: {
          genericProcess.running = false;
        }
      }

      stderr: StdioCollector {
        id: genericStderr
        onStreamFinished: {
          console.log("Process error:", text);
          genericProcess.running = false;
        }
      }
    }
  }
  // TODO: common process component
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
