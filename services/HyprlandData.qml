// Adapted from end-4's dots-hyprland
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/* Provides access to some Hyprland data not available in Quickshell.Hyprland. */
Singleton {
  id: root
  property var windowList: []
  property var activeWorkspace: null

  // Refetch soon. Events arrive in bursts (a window opening fires several),
  // so they are coalesced into one fetch.
  function updateAll() {
    _debounce.restart();
  }

  function biggestWindowForWorkspace(workspaceId) {
    const windowsInThisWorkspace = root.windowList.filter(w => w.workspace.id == workspaceId);
    return windowsInThisWorkspace.reduce((maxWin, win) => {
      const maxArea = (maxWin?.size[0] ?? 0) * (maxWin?.size[1] ?? 0);
      const winArea = (win?.size[0] ?? 0) * (win?.size[1] ?? 0);
      return winArea > maxArea ? win : maxWin;
    }, null);
  }

  Component.onCompleted: _fetch()

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      // Layer surfaces (including our own popouts) don't affect clients
      if (event.name === "openlayer" || event.name === "closelayer")
        return;
      root.updateAll();
    }
  }

  property Timer _debounce: Timer {
    interval: 50
    onTriggered: root._fetch()
  }

  // Set when a fetch is asked for while one is still running: starting a
  // running Process is a no-op, so it's re-run once the current one ends
  property bool _pending: false

  function _fetch() {
    if (getClients.running || getActiveWorkspace.running) {
      _pending = true;
      return;
    }
    getClients.running = true;
    getActiveWorkspace.running = true;
  }

  function _fetchFinished() {
    if (_pending && !getClients.running && !getActiveWorkspace.running) {
      _pending = false;
      _fetch();
    }
  }

  function _parse(text, what) {
    try {
      return JSON.parse(text);
    } catch (e) {
      console.warn("[HyprlandData] Could not parse hyprctl " + what + ":", e);
      return undefined;
    }
  }

  Process {
    id: getClients
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        const clients = root._parse(clientsCollector.text, "clients");
        if (Array.isArray(clients))
          root.windowList = clients;
      }
    }
    onExited: root._fetchFinished()
  }

  Process {
    id: getActiveWorkspace
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      id: activeWorkspaceCollector
      onStreamFinished: {
        const workspace = root._parse(activeWorkspaceCollector.text, "activeworkspace");
        if (workspace)
          root.activeWorkspace = workspace;
      }
    }
    onExited: root._fetchFinished()
  }
}
