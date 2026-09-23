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

  readonly property int currentVersion: 2

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
}
