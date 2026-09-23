pragma Singleton
import QtQuick
import Quickshell.Io

// Pending package updates, shared by every Updates widget. Only one check
// may run at a time: concurrent `checkupdates` runs share its temporary sync
// db and fail with "Cannot fetch updates". Widgets register with
// acquire(owner, {intervalMinutes, aurHelper}) (aurHelper "" for no AUR)
// and drop it with release(owner); checks run at the shortest requested
// interval, and the AUR is checked if any widget asks for it.
QtObject {
  id: root

  // [{ name, from, to }]
  property var repoPackages: []
  property var aurPackages: []
  readonly property bool checking: _repo.running || _aur.running

  function acquire(owner, request) {
    const consumers = _consumers.filter(c => c.owner !== owner);
    consumers.push({
      "owner": owner,
      "interval": (request?.intervalMinutes ?? 30) * 60000,
      "aurHelper": request?.aurHelper ?? ""
    });
    _consumers = consumers;
  }

  function release(owner) {
    _consumers = _consumers.filter(c => c.owner !== owner);
  }

  function refresh() {
    if (_repo.running) {
      _repoPending = true;
    } else {
      _repo.running = true;
    }
    if (_aurHelper === "") {
      aurPackages = [];
    } else if (_aur.running) {
      _aurPending = true;
    } else {
      _aur.command = ["sh", "-c", `command -v ${_aurHelper} >/dev/null || exit 127; ${_aurHelper} -Qua`];
      _aur.running = true;
    }
  }

  function parse(text) {
    return text.split("\n").map(line => line.trim().split(/\s+/)).filter(f => f.length >= 4 && f[2] === "->").map(f => ({
          "name": f[0],
          "from": f[1],
          "to": f[3]
        }));
  }

  // -- Private --
  property var _consumers: []
  property bool _repoPending: false
  property bool _aurPending: false

  readonly property bool _active: _consumers.length > 0
  readonly property int _interval: _active ? Math.min(..._consumers.map(c => c.interval)) : 1800000
  readonly property string _aurHelper: _consumers.find(c => c.aurHelper !== "")?.aurHelper ?? ""

  // Check straight away when the first widget appears or the AUR setting
  // changes; the Timer coalesces a burst of registrations into one check
  on_ActiveChanged: if (_active)
    _settle.restart()
  on_AurHelperChanged: if (_active)
    _settle.restart()

  property Timer _settle: Timer {
    interval: 500
    onTriggered: root.refresh()
  }

  property Timer _poll: Timer {
    interval: root._interval
    repeat: true
    running: root._active
    onTriggered: root.refresh()
  }

  property Process _repo: Process {
    command: ["checkupdates", "--nocolor"]
    stdout: StdioCollector {
      id: repoOut
    }
    stderr: StdioCollector {
      id: repoErr
    }
    // 0: updates listed, 2: none, anything else: failed (offline, db locked)
    onExited: exitCode => {
      if (exitCode === 0 || exitCode === 2)
        root.repoPackages = root.parse(repoOut.text);
      else
        console.warn(`[PackageUpdates] checkupdates failed (${exitCode}): ${repoErr.text.trim()}`);
      if (root._repoPending) {
        root._repoPending = false;
        running = true;
      }
    }
  }

  property Process _aur: Process {
    stdout: StdioCollector {
      id: aurOut
    }
    // -Qua exits 1 when nothing is outdated
    onExited: exitCode => {
      if (exitCode === 127) {
        console.warn(`[PackageUpdates] AUR helper '${root._aurHelper}' is not installed`);
        root.aurPackages = [];
      } else {
        root.aurPackages = root.parse(aurOut.text);
      }
      if (root._aurPending) {
        root._aurPending = false;
        running = true;
      }
    }
  }
}
