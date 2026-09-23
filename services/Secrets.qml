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
    _writer.command = ["sh", "-c", "umask 077 && mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", root.secretsPath, JSON.stringify(merged, null, 2)];
    _writer.running = true;
  }

  function _read() {
    const content = Utils.getFileContent("file://" + secretsPath);
    if (!content)
      return {};
    try {
      return JSON.parse(content);
    } catch (e) {
      console.error("[Secrets] Could not parse", secretsPath, e);
      return {};
    }
  }

  property Process _writer: Process {
    onExited: (code, status) => {
      if (code !== 0)
        console.error("[Secrets] Failed to write", root.secretsPath);
      else
        console.log("[Secrets] Saved", root.secretsPath);
    }
  }
}
