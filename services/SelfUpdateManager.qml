pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

/*
 * Updates axiom itself (not packages: that's UpdatesManager). Releases are
 * `v*` tags on the clone's remote, and scripts/self_update.sh does the git
 * work: `check` fetches the tags and compares, `apply` fast-forwards to the
 * newest. A clone with changed tracked files, local commits or another
 * branch is `blocked` and never touched.
 *
 * SelfUpdate.mode: "auto" installs a new release and notifies; "notify"
 * notifies, and the notification opens Settings → Updates; "off" never
 * checks. Checks run once per qs launch (not per hot reload) and daily.
 * Each release is notified once.
 *
 *   qs -c axiom ipc call selfUpdate check
 *   qs -c axiom ipc call selfUpdate update
 *   qs -c axiom ipc call selfUpdate open
 */
Singleton {
  id: root

  readonly property bool checking: _check.running
  readonly property bool applying: _apply.running
  readonly property bool busy: checking || applying

  // The installed release tag ("" before the first one), and HEAD
  readonly property string current: _result.current ?? ""
  readonly property string commit: _result.commit ?? ""
  // The newest release ("" when the remote has none)
  readonly property string latest: _result.latest ?? ""
  // "uptodate" | "available" | "diverged" | "" (no releases, or not checked)
  readonly property string state: _result.state ?? ""
  // Past the newest release (a development clone)
  readonly property bool ahead: _result.ahead ?? false
  readonly property int behind: _result.behind ?? 0
  // Why it can't update: "dirty" | "diverged" | "branch" | "nogit" | ""
  readonly property string blocked: _result.blocked ?? ""
  // The newest release's tag message
  readonly property string notes: _result.notes ?? ""
  readonly property string error: _result.error ?? ""
  // ms since the epoch, 0 before the first check
  readonly property real lastChecked: _saved.lastChecked ?? 0

  readonly property bool available: state === "available" && blocked === ""

  function check() {
    if (root.busy)
      return;
    _check.command = [Paths.scriptsPath + "self_update.sh", "check"];
    _check.running = true;
  }

  function apply() {
    if (root.busy || !root.available)
      return;
    _apply.command = [Paths.scriptsPath + "self_update.sh", "apply", root.latest];
    _apply.running = true;
  }

  function openSettings() {
    SettingsManager.query = "";
    SettingsManager.category = "Updates";
    ShellManager.openOverlayPage("Settings");
  }

  // I18n.tr("It has changed files. Commit or discard them to update.")
  // I18n.tr("It has commits of its own that the release doesn't.")
  // I18n.tr("It's on a branch other than main.")
  // I18n.tr("It isn't a git clone.")
  function blockedReason(reason) {
    switch (reason) {
    case "dirty":
      return I18n.tr("It has changed files. Commit or discard them to update.");
    case "diverged":
      return I18n.tr("It has commits of its own that the release doesn't.");
    case "branch":
      return I18n.tr("It's on a branch other than main.");
    case "nogit":
      return I18n.tr("It isn't a git clone.");
    }
    return "";
  }

  // -- Private --

  property var _result: ({})
  // { lastChecked, notifiedTag, result }: the last result survives reloads
  // and restarts, so the page has something to show before the next check
  property var _saved: ({})
  readonly property var _state: StateManager.createStateHandler("selfupdate")
  readonly property string _desktopEntry: "axiom-update"

  function _save(changes) {
    root._saved = Object.assign({}, root._saved, changes);
    root._state.save(root._saved);
  }

  function _parse(text) {
    try {
      return JSON.parse(text.trim());
    } catch (e) {
      return {
        error: text.trim() || "no output"
      };
    }
  }

  function _notify(summary, body) {
    NotificationManager.sendNotification("axiom", summary, body, {
      desktopEntry: root._desktopEntry
    });
  }

  function _onChecked(result) {
    root._result = result;
    root._save({
      lastChecked: Date.now(),
      result: result
    });
    if (result.error) {
      console.warn(`[SelfUpdateManager] Check failed: ${result.error}`);
      return;
    }
    if (result.state !== "available" && result.state !== "diverged")
      return;
    const auto = SelfUpdate.mode === "auto";
    if (auto && root.available) {
      root.apply();
      return;
    }
    // Once per release
    if (root.latest === root._saved.notifiedTag || SelfUpdate.mode === "off")
      return;
    root._save({
      notifiedTag: root.latest
    });
    if (root.blocked === "")
      root._notify(I18n.tr("axiom {0} is available", root.latest), I18n.tr("Click to see what's new and update."));
    else
      root._notify(I18n.tr("axiom {0} is available", root.latest), I18n.tr("Your copy can't update: {0}", root.blockedReason(root.blocked)));
  }

  function _onApplied(result, exitCode) {
    root._result = result;
    root._save({
      result: result
    });
    if (exitCode !== 0 || result.error) {
      console.warn(`[SelfUpdateManager] Update failed: ${result.error}`);
      root._notify(I18n.tr("axiom update failed"), result.error || I18n.tr("Unknown error"));
      return;
    }
    console.log(`[SelfUpdateManager] Updated to ${result.current}`);
    root._save({
      notifiedTag: result.current
    });
    root._notify(I18n.tr("axiom updated to {0}", result.current), result.notes || I18n.tr("Click to see what's new."));
    // git replaces files rather than editing them, which qs's file
    // watcher can miss, so reload explicitly
    _reloadTimer.restart();
  }

  // Survives hot reloads, so a reload (including the one after an update)
  // doesn't check again
  PersistentProperties {
    id: _run
    reloadableId: "axiomSelfUpdate"
    property bool checked: false
  }

  // Let the startup settle (and the network come up) before fetching
  Timer {
    id: _startup
    interval: 15000
    onTriggered: {
      _run.checked = true;
      root.check();
    }
  }

  Timer {
    interval: 24 * 60 * 60 * 1000
    repeat: true
    running: SelfUpdate.mode !== "off"
    onTriggered: root.check()
  }

  // Gives the notification a moment to go out first
  Timer {
    id: _reloadTimer
    interval: 1000
    onTriggered: Quickshell.reload(false)
  }

  Process {
    id: _check
    stdout: StdioCollector {
      id: _checkOut
    }
    onExited: root._onChecked(root._parse(_checkOut.text))
  }

  Process {
    id: _apply
    stdout: StdioCollector {
      id: _applyOut
    }
    onExited: exitCode => root._onApplied(root._parse(_applyOut.text), exitCode)
  }

  IpcHandler {
    target: "selfUpdate"

    function check(): void {
      root.check();
    }

    function update(): void {
      root.apply();
    }

    // Settings → Updates
    function open(): void {
      root.openSettings();
    }
  }

  Connections {
    target: SelfUpdate
    function onModeChanged() {
      if (SelfUpdate.mode !== "off" && !_run.checked)
        _startup.restart();
    }
  }

  Component.onCompleted: {
    root._saved = root._state.load({});
    root._result = root._saved.result ?? {};
    NotificationManager.registerHandler(root._desktopEntry, () => root.openSettings());
    if (SelfUpdate.mode !== "off" && !_run.checked)
      _startup.start();
  }
}
