import QtQuick
import Quickshell

import qs.config

/*
 * The launcher's slash commands, one per shell feature. LauncherManager
 * filters and runs them; each entry is
 *   { name, aliases, glyph, description, usage,
 *     needsArg,   Enter without an argument completes "/name " instead
 *     confirm,    asks for a second Enter first (destructive session actions)
 *     available() whether it's listed at all
 *     status()    current state, shown on the command's row
 *     options(arg) completion rows [{ title, subtitle, glyph, image, value }]
 *     run(arg, value) value is the picked option's, else undefined;
 *                     returns false to keep the launcher open (where the
 *                     change shows, so several can be tried), or a string
 *                     to search for instead }
 * Descriptions are read when listed, so they follow the language.
 */
QtObject {
  id: root

  readonly property var list: [
    // --- Session ---
    root._session("lock", ["lock-screen"], "\u{F033E}", "Lock the screen"), root._session("suspend", ["sleep"], "\u{F04B2}", "Suspend to RAM"), root._session("hibernate", [], "\u{F0717}", "Hibernate to disk"), root._session("logout", ["exit"], "\u{F0343}", "End the Hyprland session"), root._session("reboot", ["restart"], "\u{F0709}", "Restart the computer"), root._session("poweroff", ["shutdown"], "\u{F0906}", "Turn the computer off"),
    // --- Surfaces ---
    {
      name: "power",
      aliases: ["powermenu"],
      glyph: "\u{F0426}",
      description: () => I18n.tr("Open the power menu"),
      run: () => ShellManager.openPowerMenu()
    },
    {
      name: "workspaces",
      aliases: ["overview"],
      glyph: "\u{F0570}",
      description: () => I18n.tr("Open the workspace overview"),
      run: () => ShellManager.toggleWorkspaceOverlay()
    },
    {
      name: "overlay",
      aliases: ["page"],
      glyph: "\u{F056E}",
      usage: "[page]",
      description: () => I18n.tr("Open the overlay, or one of its pages"),
      options: () => root._overlayPages(),
      run: (arg, value) => {
        const page = value ?? arg.trim();
        if (page === "")
          ShellManager.toggleOverlay();
        else
          ShellManager.openOverlayPage(page);
      }
    },
    root._page("settings", ["prefs", "options"], "Settings", "Open the settings"), root._page("themes", [], "Themes", "Open the themes page"), root._page("bar", ["bareditor"], "BarEditor", "Open the bar editor"), root._page("keybinds", ["keys", "shortcuts"], "Keybinds", "Show the keybinds"), root._page("editor", ["overlay-editor"], "OverlayEditor", "Open the overlay editor"),
    // --- Appearance ---
    {
      name: "theme",
      aliases: ["colors"],
      glyph: "\u{F03D8}",
      usage: "<theme>",
      needsArg: true,
      description: () => I18n.tr("Switch the color theme"),
      status: () => ThemeManager.currentFamily?.label ?? Appearance.theme,
      options: () => ThemeManager.themeFamilies.map(family => ({
              title: family.label,
              subtitle: family === ThemeManager.currentFamily ? I18n.tr("Current") : family.generated ? I18n.tr("Generated") : family.dark && family.light ? I18n.tr("Dark and light") : family.dark ? I18n.tr("Dark") : I18n.tr("Light"),
              value: family
            })),
      run: (arg, value) => {
        if (value)
          ThemeManager.applyFamily(value);
        return false;
      }
    },
    {
      name: "dark",
      aliases: [],
      glyph: "\u{F0594}",
      description: () => I18n.tr("Use the theme's dark variant"),
      run: () => {
        ThemeManager.setLightMode(false);
        return false;
      }
    },
    {
      name: "light",
      aliases: [],
      glyph: "\u{F0599}",
      description: () => I18n.tr("Use the theme's light variant"),
      run: () => {
        ThemeManager.setLightMode(true);
        return false;
      }
    },
    {
      name: "mode",
      aliases: ["darkmode"],
      glyph: "\u{F050E}",
      description: () => I18n.tr("Toggle light and dark"),
      status: () => Appearance.darkMode ? I18n.tr("Dark") : I18n.tr("Light"),
      run: () => {
        ThemeManager.toggleDarkMode();
        return false;
      }
    },
    {
      name: "wallpaper",
      aliases: ["wall", "bg"],
      glyph: "\u{F02E9}",
      usage: "<file>",
      needsArg: true,
      description: () => I18n.tr("Set the focused monitor's wallpaper"),
      options: () => root._wallpapers(),
      run: (arg, value) => {
        let url = value;
        if (url === "random") {
          const walls = root._wallpapers().slice(1);
          url = walls.length > 0 ? walls[Math.floor(Math.random() * walls.length)].value : "";
        }
        if (url)
          ThemeManager.setWallpaperAndGenerate(url, "");
        return false;
      }
    },
    {
      name: "generate",
      aliases: ["pywal"],
      glyph: "\u{F0068}",
      description: () => I18n.tr("Generate themes from the current wallpaper"),
      status: () => ThemeManager.isGenerating ? I18n.tr("Generating…") : "",
      run: () => {
        const monitor = ShellManager.targetFor(LauncherConfig.monitors);
        const wallpaper = Appearance.wallpapers[monitor] || Appearance.wallpaper;
        if (wallpaper)
          ThemeManager.generateThemesFromWallpaper(wallpaper);
      }
    },
    // --- Audio & media ---
    {
      name: "volume",
      aliases: ["vol"],
      glyph: "\u{F057E}",
      usage: "<0-100 | +n | -n>",
      needsArg: true,
      description: () => I18n.tr("Set the output volume"),
      status: () => AudioManager.muted ? I18n.tr("Muted") : Math.round(AudioManager.volume * 100) + "%",
      run: arg => {
        const match = arg.trim().match(/^([+-]?)(\d+)%?$/);
        if (match) {
          const amount = parseInt(match[2]) / 100;
          if (match[1] === "+")
            AudioManager.increaseVolume(amount);
          else if (match[1] === "-")
            AudioManager.decreaseVolume(amount);
          else
            AudioManager.setVolume(amount);
        }
        return false;
      }
    },
    {
      name: "mute",
      aliases: [],
      glyph: "\u{F0581}",
      description: () => I18n.tr("Mute or unmute the output"),
      status: () => AudioManager.muted ? I18n.tr("Muted") : "",
      run: () => {
        AudioManager.toggleMute();
        return false;
      }
    },
    {
      name: "mic",
      aliases: ["microphone"],
      glyph: "\u{F036C}",
      description: () => I18n.tr("Mute or unmute the microphone"),
      status: () => AudioManager.sourceMuted ? I18n.tr("Muted") : "",
      run: () => {
        AudioManager.toggleSourceMute();
        return false;
      }
    },
    root._device("output", ["sink", "speakers"], "\u{F04C3}", "Choose the audio output", () => AudioManager.sinks, () => AudioManager.defaultSink), root._device("input", ["source"], "\u{F036C}", "Choose the audio input", () => AudioManager.sources, () => AudioManager.defaultSource), root._media("play", ["pause"], "\u{F040E}", "Play or pause", () => MediaManager.togglePlayPause()), root._media("next", ["skip"], "\u{F04AD}", "Next track", () => MediaManager.next()), root._media("prev", ["previous", "back"], "\u{F04AE}", "Previous track", () => MediaManager.previous()),
    // --- Connectivity ---
    {
      name: "wifi",
      aliases: ["wlan"],
      glyph: "\u{F05A9}",
      usage: "[on | off]",
      description: () => I18n.tr("Turn wifi on or off"),
      available: () => NetworkingManager.available,
      status: () => NetworkingManager.wifiEnabled ? I18n.tr("On") : I18n.tr("Off"),
      options: () => root._onOffOptions(),
      run: (arg, value) => {
        const on = root._onOff(value ?? arg);
        NetworkingManager.setWifiEnabled(on === null ? !NetworkingManager.wifiEnabled : on);
        return false;
      }
    },
    {
      name: "bluetooth",
      aliases: ["bt"],
      glyph: "\u{F00AF}",
      usage: "[on | off]",
      description: () => I18n.tr("Turn bluetooth on or off"),
      available: () => BluetoothManager.available,
      status: () => BluetoothManager.enabled ? I18n.tr("On") : I18n.tr("Off"),
      options: () => root._onOffOptions(),
      run: (arg, value) => {
        const on = root._onOff(value ?? arg);
        BluetoothManager.setEnabled(on === null ? !BluetoothManager.enabled : on);
        return false;
      }
    },
    {
      name: "connect",
      aliases: ["disconnect", "device"],
      glyph: "\u{F00B1}",
      usage: "<device>",
      needsArg: true,
      description: () => I18n.tr("Connect or disconnect a paired bluetooth device"),
      available: () => BluetoothManager.enabled,
      options: () => BluetoothManager.pairedDevices.map(device => ({
              title: BluetoothManager.deviceLabel(device),
              subtitle: BluetoothManager.deviceStatus(device),
              glyph: BluetoothManager.deviceIcon(device),
              value: device
            })),
      run: (arg, value) => {
        if (value)
          BluetoothManager.toggleDevice(value);
      }
    },
    // --- Notifications & idle ---
    {
      name: "dnd",
      aliases: ["quiet"],
      glyph: "\u{F009B}",
      usage: "[on | off]",
      description: () => I18n.tr("Do not disturb"),
      status: () => NotificationManager.dnd ? I18n.tr("On") : I18n.tr("Off"),
      options: () => root._onOffOptions(),
      run: (arg, value) => {
        const on = root._onOff(value ?? arg);
        NotificationManager.dnd = on === null ? !NotificationManager.dnd : on;
        return false;
      }
    },
    {
      name: "clear",
      aliases: ["clear-notifications"],
      glyph: "\u{F039F}",
      description: () => I18n.tr("Clear all notifications"),
      status: () => NotificationManager.count > 0 ? I18n.tr("{0} notifications", NotificationManager.count) : "",
      run: () => {
        NotificationManager.clearAll();
        return false;
      }
    },
    {
      name: "caffeine",
      aliases: ["awake", "inhibit"],
      glyph: "\u{F0176}",
      usage: "[on | off]",
      description: () => I18n.tr("Keep the screen awake"),
      status: () => IdleInhibitManager.enabled ? I18n.tr("On") : I18n.tr("Off"),
      options: () => root._onOffOptions(),
      run: (arg, value) => {
        const on = root._onOff(value ?? arg);
        IdleInhibitManager.enabled = on === null ? !IdleInhibitManager.enabled : on;
        return false;
      }
    },
    // --- Workspaces & shell ---
    {
      name: "ws",
      aliases: ["workspace"],
      glyph: "\u{F03A0}",
      usage: "<number>",
      needsArg: true,
      description: () => I18n.tr("Go to a workspace"),
      run: arg => {
        const id = parseInt(arg.trim());
        if (id > 0)
          HyprlandManager.goToWorkspace(id);
        else
          return false;
      }
    },
    {
      name: "config",
      aliases: ["set", "cfg"],
      glyph: "\u{F0493}",
      usage: "<setting> <value> | save <name> | restore <name>",
      needsArg: true,
      description: () => I18n.tr("Change a setting, or save and restore the config"),
      options: arg => root._configOptions(arg),
      run: (arg, value) => root._configRun(value)
    },
    {
      name: "reload",
      aliases: [],
      glyph: "\u{F0453}",
      description: () => I18n.tr("Reload the shell"),
      run: () => Quickshell.reload(false)
    },
    // --- Other searches ---
    root._prefix("calc", ["math"], "\u{F00EC}", "Calculate (or start with =)", "=", () => LauncherConfig.calculator), root._prefix("run", ["exec", "sh"], "\u{F018D}", "Run a shell command (or start with >)", ">", () => LauncherConfig.runCommands), root._prefix("web", ["search"], "\u{F059F}", "Search the web (or start with ?)", "?", () => LauncherConfig.webSearch), root._prefix("help", ["commands"], "\u{F02D7}", "List every command", "/", () => true)]

  // --- Builders for families of alike commands ---

  function _session(action, aliases, glyph, description) {
    return {
      name: action,
      aliases: aliases,
      glyph: glyph,
      confirm: ShellManager.destructiveActions.includes(action),
      // I18n.tr("Lock the screen") I18n.tr("Suspend to RAM") I18n.tr("Hibernate to disk")
      // I18n.tr("End the Hyprland session") I18n.tr("Restart the computer") I18n.tr("Turn the computer off")
      description: () => I18n.tr(description),
      run: () => ShellManager.sessionAction(action)
    };
  }

  // Opens the overlay on a page by view type
  function _page(name, aliases, type, description) {
    return {
      name: name,
      aliases: aliases,
      glyph: OverlayConfig.viewInfo(type)?.icon ?? "\u{F056E}",
      // I18n.tr("Open the settings") I18n.tr("Open the themes page") I18n.tr("Open the bar editor")
      // I18n.tr("Show the keybinds") I18n.tr("Open the overlay editor")
      description: () => I18n.tr(description),
      run: () => ShellManager.openOverlayPage(type)
    };
  }

  // Picks the default audio device from `nodes()`
  function _device(name, aliases, glyph, description, nodes, current) {
    return {
      name: name,
      aliases: aliases,
      glyph: glyph,
      usage: "<device>",
      needsArg: true,
      // I18n.tr("Choose the audio output") I18n.tr("Choose the audio input")
      description: () => I18n.tr(description),
      status: () => current()?.description ?? "",
      options: () => nodes().map(node => ({
              title: node.description || node.name,
              subtitle: node === current() ? I18n.tr("Current") : "",
              value: node
            })),
      run: (arg, value) => {
        if (value)
          AudioManager.setDefault(value);
        return false;
      }
    };
  }

  function _media(name, aliases, glyph, description, action) {
    return {
      name: name,
      aliases: aliases,
      glyph: glyph,
      // I18n.tr("Play or pause") I18n.tr("Next track") I18n.tr("Previous track")
      description: () => I18n.tr(description),
      available: () => MediaManager.hasActivePlayer,
      status: () => [MediaManager.trackTitle, MediaManager.trackArtist].filter(s => s).join(" · "),
      run: () => {
        action();
        return false;
      }
    };
  }

  // Switches the search to one of the prefixes
  function _prefix(name, aliases, glyph, description, prefix, available) {
    return {
      name: name,
      aliases: aliases,
      glyph: glyph,
      // I18n.tr("Calculate (or start with =)") I18n.tr("Run a shell command (or start with >)")
      // I18n.tr("Search the web (or start with ?)") I18n.tr("List every command")
      description: () => I18n.tr(description),
      available: available,
      run: arg => prefix + arg
    };
  }

  // --- /config ---

  // Every row's title is the whole argument it stands for, since rows are
  // matched against the typed argument and Tab completes to the title
  function _configOptions(arg) {
    const space = arg.indexOf(" ");
    if (space < 0) {
      const rows = [
        {
          title: "save",
          subtitle: I18n.tr("Save the current config under a name"),
          glyph: "\u{F0193}",
          value: {
            next: "save "
          }
        },
        {
          title: "restore",
          subtitle: I18n.tr("Restore a saved config"),
          glyph: "\u{F006F}",
          value: {
            next: "restore "
          }
        }
      ];
      return rows.concat(SettingsManager.settingPaths.map(entry => ({
            title: entry.key,
            subtitle: I18n.tr(entry.schema.title ?? entry.key) + " · " + root._configShow(SettingsManager.valueOf(entry.key), entry.schema),
            value: {
              next: entry.key + " "
            }
          })));
    }

    const head = arg.slice(0, space);
    const rest = arg.slice(space + 1);
    const names = root._savedConfigNames();
    if (head === "save") {
      const name = SavedConfigsManager.sanitize(rest);
      const rows = name === "" ? [] : [
        {
          title: "save " + rest.trim(),
          subtitle: names.includes(name) ? I18n.tr("Replace \"{0}\"", name) : I18n.tr("Save as \"{0}\"", name),
          value: {
            save: name
          }
        }
      ];
      return rows.concat(names.filter(saved => saved !== name).map(saved => ({
            title: "save " + saved,
            subtitle: I18n.tr("Replace \"{0}\"", saved),
            value: {
              save: saved
            }
          })));
    }
    if (head === "restore")
      return names.map(saved => ({
            title: "restore " + saved,
            value: {
              restore: saved
            }
          }));

    const entry = SettingsManager.settingFor(head);
    if (!entry)
      return [
        {
          title: arg.trim(),
          subtitle: I18n.tr("No setting \"{0}\"", head),
          glyph: "\u{F0026}",
          value: {}
        }
      ];
    const schema = entry.schema;
    const current = SettingsManager.valueOf(entry.key);
    const choices = schema.type === "boolean" ? ["on", "off"] : schema.type === "string" ? SettingsManager.optionsFor(schema) : null;
    const setRow = (text, parsed) => ({
          title: entry.key + " " + text,
          subtitle: parsed.error ?? (JSON.stringify(parsed.value) === JSON.stringify(current) ? I18n.tr("Current") : I18n.tr("Set {0} to {1} (now {2})", I18n.tr(schema.title ?? entry.key), root._configShow(parsed.value, schema), root._configShow(current, schema))),
          glyph: parsed.error ? "\u{F0026}" : "",
          value: parsed.error ? {} : {
            key: entry.key,
            set: parsed.value
          }
        });
    const typed = rest.trim();
    if (typed === "" && !choices)
      return [
        {
          title: entry.key,
          subtitle: I18n.tr("Type a value (now {0})", root._configShow(current, schema)),
          value: {}
        }
      ];
    let rows = [];
    // Typed text that isn't (the start of) a choice gets a row of its own,
    // so free values, and why one is rejected, show
    if (typed !== "" && !(choices ?? []).some(choice => choice.toLowerCase().startsWith(typed.toLowerCase())))
      rows.push(setRow(typed, SettingsManager.parseValue(schema, rest)));
    if (choices)
      rows = rows.concat(choices.map(choice => {
        const text = choice === "" ? "\"\"" : choice;
        return setRow(text, SettingsManager.parseValue(schema, text));
      }));
    return rows;
  }

  function _configRun(value) {
    if (value?.next)
      return "/config " + value.next;
    if (value?.save) {
      SavedConfigsManager.save(value.save);
      return;
    }
    if (value?.restore) {
      SavedConfigsManager.restore(value.restore);
      return;
    }
    if (value?.key !== undefined && !SettingsManager.commitValue(value.key, value.set))
      console.warn("[LauncherCommands] Could not set", value.key);
    return false;
  }

  function _configShow(value, schema) {
    if (schema.type === "boolean")
      return value ? I18n.tr("On") : I18n.tr("Off");
    if (Array.isArray(value))
      return value.length > 0 ? value.join(", ") : I18n.tr("None");
    if (value === "")
      return I18n.tr("Empty");
    return String(value);
  }

  function _savedConfigNames() {
    const names = [];
    const model = SavedConfigsManager.model;
    for (let i = 0; i < model.count; i++)
      names.push(model.get(i, "fileBaseName"));
    return names;
  }

  // --- Option lists ---

  function _onOffOptions() {
    return [
      {
        title: "on",
        value: "on"
      },
      {
        title: "off",
        value: "off"
      }
    ];
  }

  // "on" → true, "off" → false, anything else (a toggle) → null
  function _onOff(arg) {
    const word = (arg ?? "").trim().toLowerCase();
    if (["on", "1", "true", "yes"].includes(word))
      return true;
    if (["off", "0", "false", "no"].includes(word))
      return false;
    return null;
  }

  function _overlayPages() {
    const pages = OverlayConfig.views.map(view => {
      const info = OverlayConfig.viewInfo(view.type);
      return {
        title: view.name || info?.label || view.type,
        subtitle: view.name ? info?.label ?? view.type : "",
        glyph: info?.icon,
        value: view.name || view.type
      };
    });
    return pages.concat([
      {
        title: I18n.tr("Overlay editor"),
        glyph: "\u{F056E}",
        value: "OverlayEditor"
      }
    ]);
  }

  function _wallpapers() {
    const rows = [
      {
        title: I18n.tr("Random"),
        glyph: "\u{F049D}",
        value: "random"
      }
    ];
    const model = ThemeManager.wallpaperModel;
    for (let i = 0; i < model.count; i++)
      rows.push({
        title: model.get(i, "fileBaseName"),
        image: model.get(i, "fileUrl").toString(),
        value: model.get(i, "fileUrl").toString()
      });
    return rows;
  }
}
