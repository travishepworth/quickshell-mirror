pragma Singleton
import QtQuick
import Quickshell

import qs.config

// Derived, non-configurable values: filesystem paths and layout helpers.
QtObject {
  id: root

  readonly property int orientation: Bar.vertical ? Qt.Vertical : Qt.Horizontal

  // --- Paths (from the environment, not from any config value) ---
  readonly property string homeDirectory: Quickshell.env("HOME") + "/"
  // Shell root (this repo), always with a trailing slash
  readonly property string axiomPath: Quickshell.shellDir.toString().replace("file://", "").replace(/\/?$/, "/")
  readonly property string themePath: root.axiomPath + "config/themes/"
  readonly property string scriptsPath: root.axiomPath + "scripts/"
  readonly property string venvPythonPath: root.axiomPath + ".venv/bin/python3"
  readonly property string configPath: root.axiomPath + "config/"
  readonly property string statePath: root.configPath + "state/"

  readonly property string walCachePath: root.homeDirectory + ".cache/wal/schemes/"
  readonly property string cachePath: root.homeDirectory + ".cache/quickshell/axiom/generated/"
  readonly property string hyprlandPath: root.homeDirectory + ".config/hypr/"
}
