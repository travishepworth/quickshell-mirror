pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.components.methods

/**
 * Secrets (chat API keys) live outside the repo and outside config.json.
 * Lookup order for a backend's key:
 *   1. $<BACKEND>_API_KEY environment variable (e.g. GEMINI_API_KEY)
 *   2. $XDG_STATE_HOME/axiom/secrets.json  ({ "gemini": "…", … }), mode 600
 */
QtObject {
  id: root

  readonly property string stateDir: {
    const xdg = Quickshell.env("XDG_STATE_HOME");
    return (xdg ? xdg : Quickshell.env("HOME") + "/.local/state") + "/axiom";
  }
  readonly property string secretsPath: stateDir + "/secrets.json"

  property var _secrets: _read()

  function apiKey(backend) {
    const fromEnv = Quickshell.env(backend.toUpperCase() + "_API_KEY");
    if (fromEnv)
      return fromEnv;
    return _secrets[backend] ?? "";
  }

  // Merge `entries` ({ backend: key }) into the secrets file
  function store(entries) {
    const merged = Object.assign({}, root._secrets, entries);
    root._secrets = merged;
    // Contents go through stdin: argv is readable by any local user
    // (/proc/<pid>/cmdline). chmod also fixes an existing file's mode.
    _writer._pending = JSON.stringify(merged, null, 2);
    _writer.command = ["sh", "-c", "umask 077 && mkdir -p \"$(dirname \"$1\")\" && cat > \"$1\" && chmod 600 \"$1\"", "sh", root.secretsPath];
    _writer.stdinEnabled = true;
    _writer.running = true;
  }

  function _read() {
    const content = Utils.getFileContent("file://" + secretsPath);
    if (!content)
      return {};
    try {
      return JSON.parse(content);
    } catch (e) {
      console.error("[SecretsManager] Could not parse", secretsPath, e);
      return {};
    }
  }

  property Process _writer: Process {
    property string _pending: ""

    onStarted: {
      write(_pending);
      _pending = "";
      stdinEnabled = false; // closes stdin, so cat sees EOF
    }
    onExited: (code, status) => {
      if (code !== 0)
        console.error("[SecretsManager] Failed to write", root.secretsPath);
      else
        console.log("[SecretsManager] Saved", root.secretsPath);
    }
  }
}
