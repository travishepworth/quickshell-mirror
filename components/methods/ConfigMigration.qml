pragma Singleton
import QtQuick

/**
 * Upgrades older config.json layouts to the current one (see
 * config/json/config.schema.json). Pure functions only: ConfigManager runs
 * migrate() on load, then writes the result back once.
 *
 * Secrets (chat API keys) found in old configs are split out and returned
 * separately, so they never get written back into config.json.
 */
QtObject {
  id: root

  readonly property int currentVersion: 8

  /**
   * @param config  Parsed config.json (not modified)
   * @return { config, secrets, changes, migrated }
   *   secrets: { backendName: apiKey } pulled out of the old config
   *   changes: human-readable list of what was done, for the log
   */
  function migrate(config) {
    let result = JSON.parse(JSON.stringify(config ?? {}));
    const secrets = {};
    const changes = [];
    const version = result.version ?? 1;

    if (version < 2)
      result = _v1ToV2(result, secrets, changes);
    if (version < 3)
      result = _v2ToV3(result, changes);
    if (version < 4)
      result = _v3ToV4(result, changes);
    if (version < 5)
      result = _v4ToV5(result, changes);
    if (version < 6)
      result = _v5ToV6(result, changes);
    if (version < 7)
      result = _v6ToV7(result, changes);
    if (version < 8)
      result = _v7ToV8(result, changes);

    return {
      config: result,
      secrets: secrets,
      changes: changes,
      migrated: version < root.currentVersion
    };
  }

  function _take(obj, key) {
    if (!obj || !(key in obj))
      return undefined;
    const value = obj[key];
    delete obj[key];
    return value;
  }

  function _set(obj, path, value) {
    if (value === undefined)
      return;
    const parts = path.split(".");
    let cur = obj;
    for (let i = 0; i < parts.length - 1; i++) {
      if (typeof cur[parts[i]] !== "object" || cur[parts[i]] === null)
        cur[parts[i]] = {};
      cur = cur[parts[i]];
    }
    cur[parts[parts.length - 1]] = value;
  }

  function _v1ToV2(old, secrets, changes) {
    const out = {};
    if (old.$schema !== undefined)
      out.$schema = old.$schema;
    out.version = 2;

    const move = (value, path, from) => {
      if (value === undefined)
        return;
      _set(out, path, value);
      changes.push(from + " → " + path);
    };

    // --- Config / Display → General, Appearance, Icons ---
    const cfg = old.Config ?? {};
    move(_take(cfg, "userName"), "General.displayName", "Config.userName");
    move(_take(cfg, "wallpaper"), "Appearance.wallpaper", "Config.wallpaper");
    move(_take(cfg, "customIconOverrides"), "Icons.overrides", "Config.customIconOverrides");
    const display = old.Display ?? {};
    move(_take(display, "primary"), "General.primaryMonitor", "Display.primary");

    // --- Appearance: flat → font / shape / motion ---
    const app = old.Appearance ?? {};
    for (const key of ["theme", "darkMode", "autoThemeSwitch"])
      if (app[key] !== undefined)
        _set(out, "Appearance." + key, app[key]);
    move(_take(app, "fontFamily"), "Appearance.font.family", "Appearance.fontFamily");
    move(_take(app, "fontSize"), "Appearance.font.size", "Appearance.fontSize");
    move(_take(app, "borderRadius"), "Appearance.shape.radius", "Appearance.borderRadius");
    move(_take(app, "borderWidth"), "Appearance.shape.borderWidth", "Appearance.borderWidth");
    move(_take(app, "screenMargin"), "Appearance.shape.screenMargin", "Appearance.screenMargin");
    move(_take(app, "animations"), "Appearance.motion.enabled", "Appearance.animations");
    const duration = _take(app, "animationDuration");
    if (duration !== undefined && duration > 0) {
      // Old setting was a duration where 150ms was "normal"; new one is a
      // speed percentage where 100 is normal.
      const speed = Math.max(25, Math.min(400, Math.round(150 / duration * 100)));
      move(speed, "Appearance.motion.speed", "Appearance.animationDuration (" + duration + "ms)");
    }
    move(_take(app, "workspacePopoutIcons"), "Popouts.workspaceIcons", "Appearance.workspacePopoutIcons");

    // --- Widget: keep sizing only ---
    const widget = old.Widget ?? {};
    for (const key of ["height", "padding", "spacing"])
      if (widget[key] !== undefined)
        _set(out, "Widget." + key, widget[key]);

    // --- Menu → Overlay + SidePanel ---
    const menu = old.Menu ?? {};
    move(_take(menu, "views"), "Overlay.views", "Menu.views");
    move(_take(menu, "enablePanel"), "SidePanel.enabled", "Menu.enablePanel");

    // --- Bar → Bars (primary first, display → monitor, autoHide → reserveSpace) ---
    if (Array.isArray(old.Bar)) {
      const bars = old.Bar.slice().sort((a, b) => (b.primary === true) - (a.primary === true));
      out.Bars = bars.map(bar => {
        const b = {};
        for (const key of ["id", "enabled", "location", "extent", "spacing", "widgets"])
          if (bar[key] !== undefined)
            b[key] = bar[key];
        if (bar.display !== undefined)
          b.monitor = bar.display;
        if (bar.autoHide !== undefined)
          b.reserveSpace = !bar.autoHide;
        return b;
      });
      changes.push("Bar → Bars (display → monitor, autoHide → reserveSpace, primary bar first)");
    }

    // --- ChatConfig → Chat, API keys → secrets ---
    const chat = old.ChatConfig;
    if (chat) {
      const c = {};
      if (chat.enabled !== undefined)
        c.enabled = chat.enabled;
      if (chat.defaultBackend !== undefined)
        c.defaultBackend = chat.defaultBackend;
      if (chat.backends) {
        c.backends = {};
        for (const name in chat.backends) {
          const backend = Object.assign({}, chat.backends[name]);
          const key = _take(backend, "apiKey");
          if (key)
            secrets[name] = key;
          c.backends[name] = backend;
        }
      }
      out.Chat = c;
      changes.push("ChatConfig → Chat");
      if (Object.keys(secrets).length > 0)
        changes.push("Chat API keys → secrets file (" + Object.keys(secrets).join(", ") + ")");
    }

    // --- ThemeIntegrations: only the implemented ones ---
    const ti = old.ThemeIntegrations ?? {};
    for (const key of ["kitty", "k9s", "cava"])
      if (ti[key] !== undefined)
        _set(out, "ThemeIntegrations." + key, ti[key]);

    changes.push("Dropped unused keys (workspaceCount, singleMonitor, resolution, monitors, containerWidth, Menu card/pinning settings, bar padding, unimplemented theme integrations)");
    return out;
  }

  // Semantic color names → the base16 slot they default to (Theme.qml's
  // fallbacks), for widget colors saved before colors were base keys only
  readonly property var _semanticToBase: ({
      "background": "base00",
      "backgroundAlt": "base01",
      "backgroundHighlight": "base02",
      "foreground": "base05",
      "foregroundAlt": "base04",
      "foregroundHighlight": "base06",
      "foregroundInactive": "base03",
      "border": "base03",
      "borderFocus": "base0D",
      "accent": "base0D",
      "accentAlt": "base0E",
      "success": "base0B",
      "warning": "base0A",
      "error": "base08",
      "info": "base0C",
      "red": "base08",
      "green": "base0B",
      "yellow": "base0A",
      "blue": "base0D",
      "magenta": "base0E",
      "cyan": "base0C",
      "orange": "base09",
      "grey": "base03",
      "bg0": "base00",
      "bg1": "base01",
      "bg2": "base02"
    })

  // "Theme.info" / "info" → "base0C"; base keys and hex pass through
  function _baseColor(value) {
    if (typeof value !== "string")
      return value;
    const key = value.includes(".") ? value.substring(value.lastIndexOf(".") + 1) : value;
    return root._semanticToBase[key] ?? key;
  }

  function _v2ToV3(old, changes) {
    const out = old;
    out.version = 3;
    for (const bar of out.Bars ?? []) {
      for (const zone in bar.widgets ?? {}) {
        bar.widgets[zone] = (bar.widgets[zone] ?? []).map(widget => {
          if (widget.type === "TimeJapanese") {
            changes.push(`Bars.${bar.id}.${zone}: TimeJapanese → Time (style: japanese)`);
            return Object.assign({}, widget, {
              "type": "Time",
              "properties": {
                "style": "japanese",
                "use24Hour": true
              }
            });
          }
          if (widget.type === "Logo") {
            const props = widget.properties ?? {};
            const button = {
              "action": "powerMenu"
            };
            if (props.icon !== undefined)
              button.icon = props.icon;
            if (props.backgroundColor !== undefined)
              button.backgroundColor = _baseColor(props.backgroundColor);
            changes.push(`Bars.${bar.id}.${zone}: Logo → Button (action: powerMenu)`);
            return Object.assign({}, widget, {
              "type": "Button",
              "properties": button
            });
          }
          return widget;
        });
      }
    }
    return out;
  }

  function _v3ToV4(old, changes) {
    const out = old;
    out.version = 4;
    const timeout = _take(out.Popouts, "osdTimeout");
    if (timeout !== undefined) {
      _set(out, "OSD.timeout", timeout);
      changes.push("Popouts.osdTimeout → OSD.timeout");
    }
    return out;
  }

  // Overlay views went from bare type names (whose contents were hardcoded
  // QML) to JSON-built views. The old types have no JSON equivalent, so a
  // list using them is dropped and the schema default (the old layout,
  // rebuilt in JSON) fills it back in.
  function _v4ToV5(old, changes) {
    const out = old;
    out.version = 5;
    const legacy = ["OverView", "ConfigEditor", "KeybindView", "ThemeSelector"];
    const views = out.Overlay?.views;
    if (Array.isArray(views) && views.some(v => legacy.includes(v?.type))) {
      delete out.Overlay.views;
      changes.push("Overlay.views → new JSON layout (reset to default)");
    }
    return out;
  }

  // Overlay columns lost their `type`: every column is a stack of cells,
  // and the prebuilt Settings/ThemeEditor columns became modules in a Tall
  // cell.
  function _v5ToV6(old, changes) {
    const out = old;
    out.version = 6;
    let rewritten = 0;
    (out.Overlay?.views ?? []).forEach(view => {
      if (!Array.isArray(view?.columns))
        return;
      view.columns = view.columns.map(column => {
        if (!column || column.type === undefined)
          return column;
        rewritten++;
        if (column.type === "Cells")
          return {
            cells: column.cells ?? []
          };
        return {
          cells: [
            {
              layout: "Tall",
              slots: {
                main: {
                  type: column.type
                }
              }
            }
          ]
        };
      });
    });
    if (rewritten > 0)
      changes.push(`Overlay columns → cell stacks (${rewritten} rewritten)`);
    return out;
  }

  // The first overlay modules (Cpu, Gpu, Memory, Storage, Volume, Media)
  // were replaced by the module suite: each slot gets its successor
  function _v6ToV7(old, changes) {
    const out = old;
    out.version = 7;
    const successors = {
      "Cpu": {
        "type": "SystemGraphs",
        "properties": {
          "metrics": ["cpu"]
        }
      },
      "Memory": {
        "type": "SystemGraphs",
        "properties": {
          "metrics": ["mem"]
        }
      },
      "Gpu": {
        "type": "SystemGraphs",
        "properties": {
          "metrics": ["gpu"]
        }
      },
      "Storage": {
        "type": "Disks"
      },
      "Volume": {
        "type": "VolumeDials"
      },
      "Media": {
        "type": "NowPlaying"
      }
    };
    let replaced = 0;
    (out.Overlay?.views ?? []).forEach(view => {
      (view?.columns ?? []).forEach(column => {
        (column?.cells ?? []).forEach(cell => {
          Object.keys(cell?.slots ?? {}).forEach(slot => {
            const next = successors[cell.slots[slot]?.type];
            if (next) {
              cell.slots[slot] = JSON.parse(JSON.stringify(next));
              replaced++;
            }
          });
        });
      });
    });
    if (replaced > 0)
      changes.push(`Overlay: ${replaced} old module(s) → their replacements`);
    return out;
  }

  // The Time widget's `style` ("standard" / "japanese") became the global
  // General.language: a Japanese clock carries over as language "ja"
  function _v7ToV8(old, changes) {
    const out = old;
    out.version = 8;
    let japanese = false;
    (out.Bars ?? []).forEach(bar => {
      Object.values(bar?.widgets ?? {}).forEach(zone => {
        (zone ?? []).forEach(widget => {
          if (widget?.type === "Time" && widget.properties && "style" in widget.properties) {
            japanese = japanese || widget.properties.style === "japanese";
            delete widget.properties.style;
          }
        });
      });
    });
    if (japanese && !out.General?.language) {
      _set(out, "General.language", "ja");
      changes.push("Time style: japanese → General.language: ja");
    }
    return out;
  }
}
