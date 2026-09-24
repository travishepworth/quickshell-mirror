pragma Singleton
import QtQuick
import Quickshell.Io

// Tailscale's state for every widget that shows it: one
// `tailscale status --json` at the shortest interval asked for, only while
// something has acquire()d it.
QtObject {
  id: root

  // Installed at all (false until the first check says otherwise)
  property bool available: false
  // "Running", "Stopped", "NeedsLogin", ... ("" if unknown)
  property string backendState: ""
  readonly property bool connected: backendState === "Running"
  property string tailnetName: ""
  property string ip: ""

  // request: { interval } (ms)
  function acquire(owner, request) {
    _registry.acquire(owner, {
      "interval": request?.interval ?? 10000
    });
  }

  function release(owner) {
    _registry.release(owner);
  }

  function refresh() {
    if (!_check.running)
      _check.running = true;
  }

  // -- Private --
  property ConsumerRegistry _registry: ConsumerRegistry {}
  readonly property int _interval: _registry.active ? Math.max(5000, Math.min(..._registry.requests.map(r => r.interval))) : 10000

  property Timer _timer: Timer {
    interval: root._interval
    running: root._registry.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  property Process _check: Process {
    command: ["sh", "-c", "command -v tailscale >/dev/null || exit 127; tailscale status --json 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        let status = null;
        try {
          status = JSON.parse(text);
        } catch (e) {}
        root.backendState = status?.BackendState ?? "";
        root.tailnetName = status?.CurrentTailnet?.Name ?? "";
        root.ip = status?.Self?.TailscaleIPs?.[0] ?? "";
      }
    }
    onExited: exitCode => root.available = exitCode !== 127
  }
}
