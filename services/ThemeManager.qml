pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.config

/* ThemeManager owns the active theme's data (loaded from its file, watched,
 * with defaults for what it leaves out), the theme lists, theme generation
 * from a wallpaper, the wallpaper itself, and re-theming integrated tools.
 * The choice of theme is config (Appearance.theme), persisted through
 * ConfigManager.setTheme. */
QtObject {
  id: root

  //=========================================================================
  // Public Models & State
  //=========================================================================
  readonly property FolderListModel wallpaperModel: FolderListModel {
    folder: "file://" + Appearance.wallpaperPath
    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp"]
    showDirs: false
  }
  readonly property ListModel generatedThemes: _generatedThemesModel
  readonly property ListModel defaultThemes: _defaultThemesModel
  readonly property bool isGenerating: generationProcess.running

  // The active theme's JSON ({ name, variant, paired, colors, semantic }),
  // read through config/Theme
  readonly property var currentTheme: _theme
  // config/json/theme-defaults.json: fallback palette and semantic maps,
  // shared with scripts/generate_theme.py
  readonly property var defaults: _defaults

  signal generationFailed(string errorText)

  //=========================================================================
  // Public Functions
  //=========================================================================

  function applyTheme(themeName, isGenerated) {
    const fullThemeName = isGenerated ? "generated/" + themeName : themeName;
    if (Appearance.theme === fullThemeName)
      return;
    ConfigManager.setTheme(fullThemeName);
  }

  // Sets the wallpaper, then generates themes from it
  function setWallpaperAndGenerate(wallpaperUrl, monitor) {
    setWallpaper(wallpaperUrl.toString(), monitor);
    generateThemesFromWallpaper(wallpaperUrl);
  }

  // Sets `monitor`'s wallpaper (the focused monitor's without one). The
  // primary monitor's is also Appearance.wallpaper, the lockscreen's.
  function setWallpaper(wallpaperUrl, monitor) {
    if (!wallpaperUrl)
      return;
    const target = monitor || (Hyprland.focusedMonitor?.name ?? General.primaryMonitor);
    const primary = target === General.primaryMonitor;
    Quickshell.execDetached([Paths.scriptsPath + "setWallpaper.sh", wallpaperUrl.replace("file://", ""), target, primary ? "1" : "0"]);
    ConfigManager.setWallpaper(wallpaperUrl, target, primary);
  }

  function generateThemesFromWallpaper(wallpaperUrl) {
    if (isGenerating) {
      console.log("[ThemeManager] Generation already in progress.");
      return;
    }
    console.log("[ThemeManager] Starting generation process for:", wallpaperUrl.toString());
    _generationController.start(wallpaperUrl);
  }

  // Switches to the current theme's dark/light pair, if it has one
  function toggleDarkMode() {
    const paired = currentTheme.paired;
    if (!Appearance.autoThemeSwitch || !paired) {
      console.log("[ThemeManager] No dark/light switch:", !Appearance.autoThemeSwitch ? "auto theme switching is off" : "the theme has no pair");
      return;
    }
    applyTheme(paired, Appearance.theme.startsWith("generated/"));
  }

  // Runs the enabled integrations (kitty, cava, k9s) for a theme
  function themeIntegrations(themeName = Appearance.theme) {
    const themePath = Paths.themePath + themeName + ".json";
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
    if (LockscreenConfig.mode === "hyprlock")
      root.generateHyprlockConfig();
    for (const integration of integrations) {
      // A busy integration only skips itself, not the ones after it
      if (!integration.enabled || integration.process.running)
        continue;
      integration.process.command = [Paths.scriptsPath + integration.script, themePath];
      integration.process.running = true;
    }
  }

  // The themed hyprlock config (Lockscreen.mode "hyprlock"): the theme's
  // colors plus the font, wallpaper and a translated greeting. `then` runs
  // once it's written (LockManager locks with it).
  function generateHyprlockConfig(then) {
    if (then)
      root._hyprlockThen.push(then);
    if (root._hyprlockProcess.running) {
      root._hyprlockAgain = true;
      return;
    }
    root._hyprlockProcess.command = [Paths.scriptsPath + "theme_hyprlock.sh", Paths.themePath + Appearance.theme + ".json", LockManager.hyprlockConfigPath, Appearance.fontFamily, Appearance.wallpaper, LockscreenConfig.blurWallpaper ? "1" : "0", I18n.tr("Hey {0}", General.displayName), I18n.tr("Enter password...")];
    root._hyprlockProcess.running = true;
  }

  //=========================================================================
  // Private Implementation
  //=========================================================================
  Component.onCompleted: {
    // What the initializer loaded, so the first change check is a no-op
    root._themeContent = FileManager.read(root._themeUrl(root._themeName)) ?? "";
    _reloadAllThemes();
  }

  // --- Active theme ---
  // Loaded eagerly so config/Theme never sees an empty theme
  property var _defaults: _readDefaults()
  property var _theme: _parseTheme(FileManager.read(_themeUrl(ConfigManager.config.Appearance.theme)), ConfigManager.config.Appearance.theme)
  property string _themeContent: ""
  readonly property string _themeName: ConfigManager.config.Appearance.theme
  on_ThemeNameChanged: _reloadTheme()

  property FileView _themeWatch: FileView {
    path: root._themeUrl(root._themeName)
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload();
      root._reloadTheme();
    }
  }

  function _themeUrl(name) {
    return "file://" + Paths.themePath + name + ".json";
  }

  function _readDefaults() {
    try {
      return JSON.parse(FileManager.read("file://" + Paths.configPath + "json/theme-defaults.json"));
    } catch (e) {
      console.error("[ThemeManager] Could not read theme-defaults.json:", e);
      return {
        "colors": {},
        "semantic": {
          "dark": {},
          "light": {}
        }
      };
    }
  }

  // A theme file's JSON, or the default palette if it's missing or broken
  function _parseTheme(content, name) {
    if (content) {
      try {
        return JSON.parse(content);
      } catch (e) {
        console.error("[ThemeManager] Failed to parse theme:", name, e);
      }
    } else {
      console.error("[ThemeManager] Theme not found:", name);
    }
    const defaults = root._defaults ?? _readDefaults();
    return {
      "name": "Default (fallback)",
      "variant": "dark",
      "colors": defaults.colors,
      "semantic": defaults.semantic.dark
    };
  }

  // Reloads the active theme when its name or its file's contents change,
  // and re-themes the integrated tools (not on startup)
  function _reloadTheme() {
    const content = FileManager.read(_themeUrl(_themeName)) ?? "";
    if (content === _themeContent)
      return;
    _themeContent = content;
    _theme = _parseTheme(content, _themeName);
    themeIntegrations(_themeName);
  }

  // --- Paths and Models ---
  readonly property string _themesPath: "file://" + Paths.themePath
  readonly property string _generatedThemesPath: "file://" + Paths.themePath + "generated"
  readonly property string _pythonScriptPath: Paths.scriptsPath + "generate_theme.py"
  readonly property string _venvPythonPath: Paths.venvPythonPath

  property ListModel _defaultThemesModel: ListModel {}
  property ListModel _generatedThemesModel: ListModel {}

  // --- Integration processes ---
  property Process _k9sProcess: Process {
    stderr: StdioCollector {}
    stdout: StdioCollector {}
  }
  property Process _cavaProcess: Process {
    stderr: StdioCollector {}
    stdout: StdioCollector {}
  }
  // Everything besides the theme that goes into the hyprlock config
  readonly property string _hyprlockInputs: [Appearance.fontFamily, Appearance.wallpaper, LockscreenConfig.blurWallpaper, I18n.language, General.displayName].join("|")
  on_HyprlockInputsChanged: if (LockscreenConfig.mode === "hyprlock")
    root.generateHyprlockConfig()

  property var _hyprlockThen: []
  property bool _hyprlockAgain: false
  property Process _hyprlockProcess: Process {
    stdout: StdioCollector {}
    stderr: StdioCollector {
      onStreamFinished: if (text.trim())
        console.warn("[ThemeManager] theme_hyprlock.sh:", text.trim())
    }
    onExited: exitCode => {
      if (root._hyprlockAgain) {
        root._hyprlockAgain = false;
        root.generateHyprlockConfig();
        return;
      }
      const callbacks = root._hyprlockThen;
      root._hyprlockThen = [];
      if (exitCode === 0)
        callbacks.forEach(then => then());
    }
  }

  property Process _kittyProcess: Process {
    stderr: StdioCollector {}
    stdout: StdioCollector {}
  }

  // --- Generation Logic ---
  property QtObject _generationController: QtObject {
    id: _generationController
    property int index: 0
    property url wallpaperUrl
    readonly property var backends: ["wal", "colorz", "colorthief", "haishoku"]

    function start(url) {
      wallpaperUrl = url;
      index = 0;
      runNext();
    }

    function runNext() {
      const backend = backends[index];
      const themeIndex = index + 1;
      const wallpaperPath = wallpaperUrl.toString().replace("file://", "");
      const scriptPath = root._pythonScriptPath.replace("file://", "");
      const outputDir = root._generatedThemesPath.replace("file://", "");
      const pythonPath = root._venvPythonPath.replace("file://", "");

      console.log("[ThemeManager] Generating theme", themeIndex, "using backend:", backend);
      generationProcess.command = [pythonPath, scriptPath, wallpaperPath, "--output_dir", outputDir, "--backend", backend];
      console.log("[ThemeManager] Executing:", generationProcess.command.join(" "));
      generationProcess.running = true;
    }

    function onProcessFinished(success, errorText) {
      if (success) {
        index++;
        if (index >= backends.length) {
          console.log("[ThemeManager] Theme generation finished successfully.");
          root._reloadAllThemes();
          return;
        }
        runNext();
      } else {
        console.error("[ThemeManager] Script execution failed.", errorText);
        root.generationFailed(errorText);
      }
    }
  }

  property Process _generationProcess: Process {
    id: generationProcess
    stdout: StdioCollector {
      id: stdoutCollector
    }
    stderr: StdioCollector {
      id: stderrCollector
    }
    onExited: (exitCode, exitStatus) => {
      const success = (exitStatus === 0 && exitCode === 0);
      _generationController.onProcessFinished(success, stderrCollector.text);
    }
  }

  // --- Theme List Loading ---

  /**
   * @brief Clears all theme models and re-triggers the FolderListModels to scan their directories.
   * This is the central function for refreshing the UI lists of themes.
   */
  function _reloadAllThemes() {
    console.log("[ThemeManager] Reloading all theme models...");
    _defaultThemesModel.clear();
    _generatedThemesModel.clear();

    _defaultThemeLoader.folder = "";
    _generatedThemeLoader.folder = "";

    _defaultThemeLoader.folder = _themesPath;
    _generatedThemeLoader.folder = _generatedThemesPath;
  }

  property FolderListModel _defaultThemeLoader: FolderListModel {
    nameFilters: ["*.json"]
    showDirs: false
    onStatusChanged: {
      // Ready is reported once before the rows arrive, then again with them
      if (status === FolderListModel.Ready && count > 0) {
        for (let i = 0; i < count; i++) {
          // TODO: should be within the theme's json
          // idk why tf I did it like this
          // Should read filecontent here and parse variant and generated
          const filename = get(i, "fileName");
          if (filename === "generated")
            continue;
          if (filename === "theme.schema.json")
            continue;

          root._defaultThemesModel.append({
            name: get(i, "fileBaseName"),
            filePath: get(i, "filePath"),
            isGenerated: false
          });
        }
        console.log("[ThemeManager] Default themes loaded:", root._defaultThemesModel.count);
      }
    }
  }

  property FolderListModel _generatedThemeLoader: FolderListModel {
    nameFilters: ["*.json"]
    showDirs: false
    onStatusChanged: {
      // Ready is reported once before the rows arrive, then again with them
      if (status === FolderListModel.Ready && count > 0) {
        for (let i = 0; i < count; i++) {
          const fileName = get(i, "fileBaseName");
          if (fileName === "pywal-dark")
            continue;
          root._generatedThemesModel.append({
            name: fileName,
            filePath: get(i, "filePath"),
            isGenerated: true
          });
        }
        console.log("[ThemeManager] Generated themes loaded:", root._generatedThemesModel.count);
      }
    }
  }
}
