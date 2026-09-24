// Adapted from end-4's dots-hyprland
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.config

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

  // --- Actions ---

  // The Lua window selector for a hyprctl address ("0x…"). Dispatchers take
  // it as `window`; without one they act on the focused window.
  function _window(address) {
    return `"address:${address}"`;
  }

  function moveWindowToWorkspace(windowAddress, targetWorkspace) {
    Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${targetWorkspace}, follow = false, window = ${_window(windowAddress)} })`);
  }

  function closeWindow(windowAddress) {
    Hyprland.dispatch(`hl.dsp.window.close({ window = ${_window(windowAddress)} })`);
  }

  function focusWindow(windowAddress) {
    Hyprland.dispatch(`hl.dsp.focus({ window = ${_window(windowAddress)} })`);
  }

  // Moves a window onto a workspace, tiling it on `side` ("left" | "right" |
  // "top" | "bottom") of `targetAddress`, or wherever when there's none.
  // Dwindle opens a moved window on the node nearest the cursor, and on the
  // focused window's when that's on the (active) workspace, then picks the
  // half by the cursor. So the chunk focuses the target if needed, warps the
  // cursor into the target's half and moves the window, then puts the cursor
  // back at `restore` (global). The target's box is read after the window has
  // left its workspace (`reinsert`: same workspace, moved out first), since
  // that reflows the layout. A floating window goes to `floatAt` instead.
  function placeWindow(address, workspaceId, targetAddress, side, restore, reinsert, floatAt) {
    const win = _window(address);
    const lines = [];
    if (floatAt) {
      if (!reinsert)
        lines.push(`run(function() return hl.dsp.window.move({ workspace = ${workspaceId}, follow = false, window = ${win} }) end)`);
      lines.push(`run(function() return hl.dsp.window.move({ x = ${Math.round(floatAt.x)}, y = ${Math.round(floatAt.y)}, window = ${win} }) end)`);
    } else {
      if (reinsert)
        lines.push(`run(function() return hl.dsp.window.move({ workspace = "name:axiom-drop", follow = false, window = ${win} }) end)`);
      if (targetAddress)
        lines.push(`aim(${_window(targetAddress)}, "${side}")`);
      lines.push(`run(function() return hl.dsp.window.move({ workspace = ${workspaceId}, follow = false, window = ${win} }) end)`);
      lines.push(`run(function() return hl.dsp.cursor.move({ x = ${Math.round(restore.x)}, y = ${Math.round(restore.y)} }) end)`);
    }
    _eval(_luaPrelude + lines.join("\n") + _luaEpilogue);
  }

  // Grows a window by (dw, dh) and moves it by (dx, dy). On a tiled window a
  // delta moves its nearest split by that much (dwindle smart resizing), so
  // the split follows the mouse; dx/dy only apply to floating windows.
  function resizeWindow(address, dw, dh, dx, dy) {
    const win = _window(address);
    const lines = [];
    if (dw !== 0 || dh !== 0)
      lines.push(`run(function() return hl.dsp.window.resize({ x = ${Math.round(dw)}, y = ${Math.round(dh)}, relative = true, window = ${win} }) end)`);
    if (dx !== 0 || dy !== 0)
      lines.push(`run(function() return hl.dsp.window.move({ x = ${Math.round(dx)}, y = ${Math.round(dy)}, relative = true, window = ${win} }) end)`);
    if (lines.length > 0)
      _eval(_luaPrelude + lines.join("\n") + _luaEpilogue);
  }

  // Every step runs even if an earlier one fails (so the cursor always goes
  // back); the failures are raised together at the end, and logged.
  // aim(): focus the target if it's on its monitor's active workspace, then
  // warp into the middle of its `side` half. Dwindle splits side by side when
  // the box is wider than tall (split_width_multiplier), so a side along the
  // other axis falls back to first/second half on the axis dwindle will use.
  readonly property string _luaPrelude: `local errs = {}
local function run(f)
  local ok, e = pcall(function() hl.dispatch(f()) end)
  if not ok then errs[#errs + 1] = tostring(e) end
end
local function aim(sel, side)
  local t = hl.get_window(sel)
  if not t then errs[#errs + 1] = "target not found"; return end
  local x, y = t.at.x or t.at[1], t.at.y or t.at[2]
  local w, h = t.size.x or t.size[1], t.size.y or t.size[2]
  local first = side == "left" or side == "top"
  local px, py = x + w / 2, y + h / 2
  if w > h * ${splitWidthMultiplier} then
    px = first and x + w / 4 or x + w * 3 / 4
  else
    py = first and y + h / 4 or y + h * 3 / 4
  end
  if t.workspace and t.workspace.active then
    run(function() return hl.dsp.focus({ window = sel }) end)
  end
  run(function() return hl.dsp.cursor.move({ x = px, y = py }) end)
end
`
  readonly property string _luaEpilogue: `
if #errs > 0 then error(table.concat(errs, "; ")) end`

  // Lua chunks run one at a time, in order, through `hyprctl eval`
  property var _evalQueue: []

  function _eval(lua) {
    _evalQueue.push(lua);
    if (!evalProcess.running)
      _nextEval();
  }

  function _nextEval() {
    if (_evalQueue.length === 0) {
      root.updateAll();
      return;
    }
    evalProcess.command = ["hyprctl", "eval", _evalQueue.shift()];
    evalProcess.running = true;
  }

  // Through the user's Hyprland script (it maps grid positions to
  // workspaces); detached, so quick successive clicks all go through
  function focusWorkspace(index) {
    Quickshell.execDetached([Paths.hyprlandPath + "scripts/gotoWorkspace.sh", String(index)]);
  }

  // Plain switch to a workspace by id (the standard Workspaces widget)
  function gotoWorkspace(id) {
    Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
  }

  // --- Queries ---

  function activeWorkspaceId() {
    return Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
  }

  // The Wayland toplevel for a hyprctl window address ("0x…")
  function toplevelForAddress(address) {
    for (const toplevel of Hyprland.toplevels.values) {
      if ("0x" + toplevel.address === address)
        return toplevel.wayland;
    }
    return null;
  }

  // First workspace id of a monitor's 5×5 grid: 25 ids per monitor, in
  // Hyprland's monitor order (the bar's WorkspaceGrid and the overview)
  function gridBase(monitor) {
    const monitors = Hyprland.monitors.values;
    for (let i = 0; i < monitors.length; i++) {
      if (monitors[i].id === monitor?.id)
        return i * 25 + 1;
    }
    return 1;
  }

  function biggestWindowForWorkspace(workspaceId) {
    const windowsInThisWorkspace = root.windowList.filter(w => w.workspace.id == workspaceId);
    return windowsInThisWorkspace.reduce((maxWin, win) => {
      const maxArea = (maxWin?.size[0] ?? 0) * (maxWin?.size[1] ?? 0);
      const winArea = (win?.size[0] ?? 0) * (win?.size[1] ?? 0);
      return winArea > maxArea ? win : maxWin;
    }, null);
  }

  // Hyprland's general:gaps_out per side, which it adds after every
  // reserved zone (transparent bars subtract it, see BarPanel)
  property var gapsOut: ({
      "top": 0,
      "right": 0,
      "bottom": 0,
      "left": 0
    })

  // dwindle:split_width_multiplier: a box wider than tall times this splits
  // side by side (placeWindow, and the overview's drop preview)
  property real splitWidthMultiplier: 1

  // Full-screen surfaces' backdrops (ScreenBackdrop) are Top-layer
  // surfaces that must sit under the bars and border, which are on the
  // same layer (or above) but mapped before them. A higher layer order stacks them under
  // (Hyprland: "closer to the edge of the monitor"; -1 puts it on top).
  // Rules added at runtime are lost when Hyprland reloads its config.
  function _addLayerRules() {
    _eval(`hl.layer_rule({ match = { namespace = "^axiom-backdrop$" }, order = 10 })`);
  }

  Component.onCompleted: {
    _fetch();
    getGaps.running = true;
    getSplitMultiplier.running = true;
    _addLayerRules();
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      // Layer surfaces (including our own popouts) don't affect clients
      if (event.name === "openlayer" || event.name === "closelayer")
        return;
      if (event.name === "configreloaded") {
        getGaps.running = true;
        getSplitMultiplier.running = true;
        root._addLayerRules();
      }
      root.updateAll();
    }
  }

  Process {
    id: evalProcess
    stdout: StdioCollector {
      id: evalCollector
      onStreamFinished: {
        const out = evalCollector.text.trim();
        if (out !== "" && out !== "ok")
          console.warn("[HyprlandManager] hyprctl eval:", out);
      }
    }
    stderr: StdioCollector {
      id: evalErrors
      onStreamFinished: {
        if (evalErrors.text.trim() !== "")
          console.warn("[HyprlandManager] hyprctl eval:", evalErrors.text.trim());
      }
    }
    onExited: root._nextEval()
  }

  Process {
    id: getSplitMultiplier
    command: ["hyprctl", "getoption", "dwindle:split_width_multiplier", "-j"]
    stdout: StdioCollector {
      id: splitCollector
      onStreamFinished: {
        const value = Number(root._parse(splitCollector.text, "getoption")?.float);
        if (value > 0)
          root.splitWidthMultiplier = value;
      }
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
      console.warn("[HyprlandManager] Could not parse hyprctl " + what + ":", e);
      return undefined;
    }
  }

  Process {
    id: getGaps
    command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
    stdout: StdioCollector {
      id: gapsCollector
      onStreamFinished: {
        // css is "top right bottom left" (CSS shorthand, like gaps_out)
        const option = root._parse(gapsCollector.text, "getoption");
        const css = String(option?.css ?? "").trim().split(/\s+/).map(Number);
        if (css.length === 0 || css.some(isNaN))
          return;
        const [top, right = top, bottom = top, left = right] = css;
        root.gapsOut = {
          "top": top,
          "right": right,
          "bottom": bottom,
          "left": left
        };
      }
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
