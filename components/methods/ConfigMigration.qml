pragma Singleton
import QtQuick

/**
 * Upgrades older config.json layouts to the current one (see
 * config/json/config.schema.json). Pure functions only: ConfigManager runs
 * migrate() on load, then writes the result back once.
 *
 * When the layout changes, bump currentVersion (and the schema's version
 * default) and add a step to migrate(), like _v1ToV2.
 *
 * Secrets (chat API keys) found in a config belong in `secrets`, so they
 * never get written back into config.json.
 */
QtObject {
  id: root

  readonly property int currentVersion: 6

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
      result = _v1ToV2(result, changes);
    if (version < 3)
      result = _v2ToV3(result, changes);
    if (version < 4)
      result = _v3ToV4(result, changes);
    if (version < 5)
      result = _v4ToV5(result, changes);
    if (version < 6)
      result = _v5ToV6(result, changes);
    result.version = Math.max(version, root.currentVersion);

    return {
      config: result,
      secrets: secrets,
      changes: changes,
      migrated: version < root.currentVersion
    };
  }

  // v2 added a standard "Workspaces" bar widget; until then that name was
  // the 5x5 grid, now "WorkspaceGrid"
  function _v1ToV2(config, changes) {
    (config.Bars ?? []).forEach((bar, barIndex) => {
      const widgets = bar?.widgets ?? {};
      Object.keys(widgets).forEach(section => {
        (widgets[section] ?? []).forEach(widget => {
          if (widget?.type !== "Workspaces")
            return;
          widget.type = "WorkspaceGrid";
          changes.push(`Bars[${barIndex}].widgets.${section}: Workspaces -> WorkspaceGrid`);
        });
      });
    });
    return config;
  }

  // v3 sizes bar widgets from their bar (extent minus 2 * inset) instead of
  // Widget.height; each bar's inset keeps its widgets the size they were
  function _v2ToV3(config, changes) {
    const widgetHeight = config.Widget?.height ?? 30;
    (config.Bars ?? []).forEach((bar, barIndex) => {
      if (!bar || bar.inset !== undefined)
        return;
      bar.inset = Math.max(0, Math.floor(((bar.extent ?? 30) - widgetHeight) / 2));
      changes.push(`Bars[${barIndex}].inset = ${bar.inset}`);
    });
    return config;
  }

  // v4 lists a dark/light pair as one theme with a light mode switch, so
  // the setting that allowed switching between them is gone
  function _v3ToV4(config, changes) {
    if (config.Appearance?.autoThemeSwitch !== undefined) {
      delete config.Appearance.autoThemeSwitch;
      changes.push("Appearance.autoThemeSwitch removed");
    }
    return config;
  }

  // v5 made Settings a view type of its own instead of a module: a Custom
  // view holding nothing but Settings becomes one, and Settings modules
  // anywhere else are dropped (an empty slot is a gap), keeping one page
  function _v4ToV5(config, changes) {
    const views = config.Overlay?.views;
    if (!Array.isArray(views))
      return config;
    const slotsOf = view => [].concat(...(view?.columns ?? []).map(column => (column?.cells ?? []).map(cell => cell?.slots ?? {})));
    const isSettings = module => module?.type === "Settings";
    let converted = false;
    let dropped = false;
    views.forEach((view, viewIndex) => {
      if (view?.type !== "Custom")
        return;
      const modules = [].concat(...slotsOf(view).map(slots => Object.keys(slots).map(key => slots[key])));
      if (modules.length > 0 && modules.every(isSettings)) {
        views[viewIndex] = view.visible === undefined ? {
          "type": "Settings"
        } : {
          "type": "Settings",
          "visible": view.visible
        };
        converted = true;
        changes.push(`Overlay.views[${viewIndex}]: Custom Settings view -> Settings view`);
        return;
      }
      slotsOf(view).forEach(slots => Object.keys(slots).forEach(key => {
          if (!isSettings(slots[key]))
            return;
          delete slots[key];
          dropped = true;
          changes.push(`Overlay.views[${viewIndex}]: Settings module removed`);
        }));
    });
    if (dropped && !converted) {
      views.push({
        "type": "Settings"
      });
      changes.push("Overlay.views: Settings view added");
    }
    return config;
  }

  // v6 split General.monitors "all" (every monitor, opening on the focused
  // one) into "focused" (that) and "all" (open on every monitor at once)
  function _v5ToV6(config, changes) {
    if (config.General?.monitors === "all") {
      config.General.monitors = "focused";
      changes.push("General.monitors: all -> focused");
    }
    return config;
  }
}
