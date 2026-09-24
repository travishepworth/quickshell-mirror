# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.org) desktop shell config (QML) for Hyprland, named "axiom". It provides the bar, notifications, lockscreen, app launcher, power menu, OSD, workspace overlay, and rounded corners for the compositor. There is no build step — QML is interpreted at runtime by the `qs` binary.

## Running / reloading

- The shell runs as a detached background process; it is not started/stopped via a foreground terminal command in this session.
- **View logs**: `scripts/log.sh`. It prints warnings/errors since the last reload with colour stripped, so a clean reload is just `Reloading configuration...` + `Configuration Loaded`. Add `--debug` to include `console.log` output, `--all` for the whole history, `-f` to follow, and `-g PATTERN` to grep. It wraps `qs log -c axiom -r <rules>`. Don't rely on stdout or journalctl, since output is redirected to /dev/null. `console.log` is debug level and hidden by default, so use it freely for tracing, and keep `console.warn` for real problems. A normal reload should produce no warnings.
- Config reloads are automatic: `ConfigManager` watches `config/user/config.json` and the active theme file (`FileView` `watchChanges`, plus a 5s safety poll) and hot-reloads on change (see `services/ConfigManager.qml` `_checkForChanges`). An invalid or unreadable config.json never replaces the running config: the shell keeps the last good one (schema defaults at startup), and `savesBlocked` refuses every save until the file is fixed or a saved config is restored. Defaults are only written when the file is truly missing. `config/user/config.json` is owned by the settings UI (not meant for hand-editing), but editing it directly is still a valid way to test config changes without restarting.
- New singleton files (a new `pragma Singleton` QML file in `config/` or `services/`) are picked up by a hot reload with qs 0.3.1 (twelve renamed services were, 2026-09). Older qs only registered them at start; if a new singleton reads as `undefined`, ask the user to restart qs.
- Files loaded by URL (bar widgets, content, views) only see sibling types if some loaded file imports their directory by name: `BarWidgetHost` imports `qs.components.bar.widgets`, `BarPopouts` and `OverlaySlot` import `qs.components.content`, `OverlayPanel` imports `qs.components.views`. Without that, a new shared type there (e.g. `BarIconWidget`) reads as "is not a type" even though its file exists.
- Lock through `qs -c axiom ipc call lockscreen lock` (what hypridle's `lock_cmd` should run; routes by `Lockscreen.mode`, see Lockscreen below). **Never lock the built-in locker yourself while testing**: only the user can type the password. Test the lock surface by instantiating `LockSurface` in a hidden window instead.
- Do not simulate cursor movement (e.g. `hyprctl dispatch movecursor`) to verify UI behavior — check logs/code instead.
- **Run `scripts/check_structure.py` after adding, renaming or moving QML files.** It statically checks the naming conventions the shell loads by: every schema type (`BarWidget`/`OverlayView`/`OverlayModule`) and `popoutName` has its file, URL-loaded directories are imported by name, every `import qs.…` resolves, and no singleton reference is a typo (`AudioManger.`). Exit 1 on errors.
- No automated test suite exists. Verify QML changes by running `scripts/log.sh` after a save (which triggers reload), and by reasoning through property bindings — there's no headless QML test runner set up here.

## Formatting

- `.qmlformat.ini` pins `qmlformat` settings: spaces not tabs, 2-space indent, no max column width. Run `/usr/lib/qt6/bin/qmlformat -i` on changed `.qml` files before committing. The `qmlformat` on PATH is Qt5's, which can't parse `pragma ComponentBehavior` and fails silently (exit 1, no output).
- The QML JS engine has no `Array.prototype.flatMap` (use `[].concat(...arr.map(...))`) and no `Object.fromEntries` (use `reduce`).

## Architecture

### Directory roles
```
shell.qml       entrypoint — instantiates one top-level Item per module (Bar, Lockscreen, Notifications, Overlay, OSD, ThemeSelector, AppLauncher, PowerMenu, WorkspaceOverlay, RoundedCorners)
shell/          top-level pieces instantiated by shell.qml (one per surface)
components/     UI building blocks
  methods/      pure singleton helpers (Utils, IconResolver, SchemaValidation, ConfigMigration, WorkspaceGeometry)
  reusable/     generic styled widgets (StyledRectButton, StyledTextEntry, BaseWidget, TabBar, ...) with no feature-specific logic
  forms/        the schema-driven form widgets (SchemaForm, SchemaField, SchemaPropertiesForm, ...)
  content/      every loadable panel, loaded by name: overlay module types and bar popouts (see Content below)
    base/       content roots: Card (free-form card), Panel (column; popout or card), TitledCard, CardHeader
    parts/      helpers only content uses (ModuleHeader, StatFigure, AudioRow, TrayMenuItem, notifications/, chat/, ...)
  hosts/        where content appears: popout/ (bar + edge popouts: BarPopouts, PopoutAnchor, EdgePopout,
                AttachedSurface, ...) and overlay/ (OverlayPanel, OverlayPages, columns, cells, OverlaySlot)
  views/        overlay pages by view type (Custom, Keybinds, BarEditor, OverlayEditor) + their pieces
  bar/          the bar itself (BarPanel, BarContainer, WidgetGroup, BarWidgetHost); widgets/ = bar widget types
  surfaces/     standalone windows: launcher, lockscreen, notifications (toasts), powermenu, workspaces, border
services/       pragma Singleton QtObjects — global state and side-effecting logic (see below)
config/         static QML config singletons + JSON config/theme files
assets/         static assets (icons, images)
scripts/        Python/shell scripts invoked as external processes (theming, wallpaper, stats) from qs.services
```

### Layering

Dependencies point one way, so no layer needs to know about the ones above it:
- **`components/methods/`** are pure: no file access, processes, dispatches or `qs.*` imports (IconResolver only queries the icon theme and desktop entries).
- **Data owners** load and watch files: `ConfigManager` (config.json and the schema), `ThemeManager` (the active theme, `theme-defaults.json`, theme lists, generation, wallpaper, integrations) and `I18n` (dictionaries). ConfigManager reads no config reader.
- **`config/` readers** read only those owners (and each other).
- **Other services** may use readers and methods; they own side effects (`FileManager.read` for synchronous reads, `HyprlandManager` for window/workspace actions, `ShellManager.sessionAction` for power).
- **UI** may use everything below it.

### Import convention

QML files import project-internal singletons/components via the `qs.` namespace, mapped to this repo root, e.g. `import qs.services`, `import qs.config`, `import qs.components.bar`. There are no `qmldir` files — Quickshell resolves `qs.*` automatically from the shell root directory. Prefer this over relative imports.

Most files also start with `pragma ComponentBehavior: Bound` (for delegates/components using `required property`) or `pragma Singleton` (for services/config singletons).

### Services layer (`services/*.qml`)

Every file is `pragma Singleton QtObject` — one global instance per name, imported as `qs.services`. Key ones:
- **ConfigManager** — the source of truth for runtime config. Owns `_config` (parsed `config/user/config.json`) and `_configSchema`, loaded eagerly at creation (the active theme's data belongs to ThemeManager). Load pipeline: parse → `ConfigMigration.migrate` (upgrades old layouts by `version`, writes the result back once, moves API keys to `SecretsManager`) → `SchemaValidation.pruneUnknown` (drops unknown keys with a warning) → `SchemaValidation.applyDefaults` (fills every schema `default`) → validate. All config writes go through `setTheme()` / `setWallpaper()` / `saveConfig()` / `commit(object)` (draft services: runs prune/defaults/validate, returns false and changes nothing if rejected, so drafts stay dirty), which validate before writing, then `forceReload()`. Never mutate `ConfigManager.config` fields directly from UI code and expect persistence — call the setter functions (or `SettingsManager.setValue(path, value)` from settings UI). The editor services (SettingsManager, BarManager, OverlayManager) each hold a `ConfigDraft` (`services/ConfigDraft.qml`: working copy of one config path, `changed()` after in-place edits, `save()` merges onto the latest config via `commit`).
- **SecretsManager** — chat API keys, never in config.json: `$<BACKEND>_API_KEY` env var, else `$XDG_STATE_HOME/axiom/secrets.json` (mode 600).
- **ThemeManager** — owns the active theme: `currentTheme` (loaded eagerly, watched, reloaded when `Appearance.theme` or the file changes) and `defaults` (`theme-defaults.json`); `Appearance.darkMode` is derived from the theme's `variant`. Also theme discovery (`defaultThemes`/`generatedThemes`), generation from a wallpaper (`scripts/generate_theme.py` per backend), dark/light pairing, `setWallpaper` (runs `setWallpaper.sh`), and `themeIntegrations()` (kitty/cava/k9s), which run only when the active theme's name or contents change. The choice of theme is persisted through `ConfigManager.setTheme`.
- **ShellManager** — cross-cutting UI signals (dark mode, lock screen, power menu) that modules connect to rather than calling each other directly, and screen targeting: interactive surfaces (overlay, launcher, power menu, workspace overlay, OSD, theme selector) are built on `General.screens` (the primary monitor, or all with `General.monitors: "all"`), and only the instance on `ShellManager.targetScreen` (`isTarget(screen)`: the focused monitor in "all" mode) answers a shortcut, IPC call or OSD event. IPC handlers are `enabled` on the target instance only, since a target name can have one handler.
- **SystemManager** — CPU/memory/temp/GPU/disk stats. Reference-counted through a `ConsumerRegistry` (shared with UpdatesManager; identical re-registrations are no-ops): consumers call `acquire(owner, {interval, metrics, diskPaths})` / `release(owner)`, and it polls only the union of requested metrics (sysfs/procfs `FileView` reads, no processes on the hot path), stopping entirely with no consumers.
- **UpdatesManager** — pending pacman/AUR updates shared by every Updates widget (same acquire/release pattern). Only one `checkupdates` may run at a time: concurrent runs share its temp db and fail.
- **Anything that polls goes through a service's `acquire(owner, request)` / `release(owner)`** (a `ConsumerRegistry` inside), so each thing is fetched once for all widgets, at the shortest interval asked for, and not at all when nothing shows it. Widgets never run their own polling Process or repeating Timer. Besides SystemManager (`link` is the cheap primary-connection metric) and UpdatesManager: `WeatherManager`, `TailscaleManager` (`available`, `backendState`/`connected`, `tailnetName`, `ip`) and `CommandManager` (any shell command's output, `outputs[command]`, shared by identical commands; e.g. a Button's label). Acquire in `Component.onCompleted` (and again when the config-derived request changes: identical requests are no-ops), release in `onDestruction`.
- **BluetoothManager** — adapter power, scanning, sorted device lists and connect/pair/forget over `Quickshell.Bluetooth`. Not named `Bluetooth`, which would shadow Quickshell's singleton (and the `Bluetooth` bar widget file).
- **IdleInhibitManager** — shared caffeine state + `idleInhibit` IPC target; the Wayland inhibitor itself lives in `bar/widgets/IdleInhibitor.qml` (it needs a window).
- Other domain services (AudioManager, BatteryManager, MediaManager (MPRIS), NotificationManager, HyprlandManager, KeybindManager, StateManager, BarManager, LauncherManager, SettingsManager, SavedConfigsManager, ChatManager, AuthManager, LockManager) follow the same singleton pattern. Services are named `*Manager` — one owns polling/IPC/process-spawning for its domain and exposes readonly properties + signals.

### Config layer (`config/*.qml`)

Also `pragma Singleton`, but these are typed config *readers*, not owners — one per config section, exposing `readonly property` values from `ConfigManager.config`. No `??` fallbacks: the schema defaults are already filled in. Readers: `General` (displayName, primaryMonitor, `monitors`/`screens`), `Appearance` (theme, font, shape, motion tokens), `Widget`, `Bar` (from `Bars`; the first bar is primary), `PopoutConfig` (open/dismiss delays, edge trigger size — shared by bar and edge popouts), `OSDConfig` (volume OSD: edge, position, orientation, timeout, tracked apps), `OverlayConfig` (views + card-grid constants), `IconConfig`, `ChatConfig`, `ThemeIntegrations`, plus `Paths` (derived filesystem paths from `$HOME` / `Quickshell.shellDir`, not configurable) and `Theme`. Readers whose section name collides with a type get a `Config` suffix (`Popouts`, `Overlay`, `Icons`, `OSD`). UI code should read colors/settings from these (`Theme.background`, `Widget.padding`, `Bar.extent`) rather than reaching into `ConfigManager.config` directly.

**Animation timing is uniform:** every `duration:` uses `Appearance.animFast` / `animNormal` / `animSlow` (derived from `Appearance.motion.speed`, and 0 when `motion.enabled` is off), never a literal. Looping animations also gate `running` on `Appearance.animations`. Only behaviour timings (cursor blink, notification timeout, polling) stay as literals.

`config/Theme.qml` exposes the base16 palette (`base00`-`base0F`) plus semantic aliases (`background`, `accent`, `error`, etc.) resolved through `_themeData.semantic`, and a `stringToColorMap` + `resolveColor(name)` for dynamic color lookup by string (used when a color name comes from JSON/config rather than a static binding).

`config/json/config.schema.json` is the single source of truth: shape, `default`s, and — via `title`/`description`/`minimum`/`maximum`/`enum`/`x-options` — the settings UI, which is generated from it (`components/forms/SchemaForm.qml`; `x-settings: false` hides a key). Adding a setting = add it to the schema (with a default) and a reader property. `x-options: "colors"` makes a string a color picker over `base00`–`base0F` (read it with `Theme.resolveColor`, which also accepts semantic names and hex); `x-showIf` hides a field unless a sibling has a given value (evaluated by `SchemaField` itself, so it works in every form). Flat objects (array items, widget/module options, the bar's own fields) render through `forms/SchemaPropertiesForm.qml`; only the settings menu's sectioned `SchemaForm` builds its own rows. An `array` whose `items` is an object schema renders as an add/remove/reorder list of those fields (`SchemaArrayItem`). There is no separate defaults file. The live file is `config/user/config.json` (gitignored, UI-owned); bump `version` and extend `ConfigMigration` when changing its layout. Theme JSON files live in `config/themes/*.json` (static) and `config/themes/generated/*.json` (pywal-style, generated from wallpaper). `config/json/theme-defaults.json` is the one fallback palette and semantic → base16 map (dark and light), read (through `ThemeManager.defaults`) by `Theme` for keys a theme omits and for a missing theme, and by `scripts/generate_theme.py`. The `scripts/theme_*.sh` integrations share `scripts/lib/theme_env.sh` (dependency checks, one jq pass, `theme_color key fallback`).

### Translation (`config/I18n.qml`)

`General.language` picks the language. English is the source language: user-visible text is written in English, inline, as `I18n.tr("Text")`.
- **Dynamic values** use placeholders, so the whole sentence stays one key: `I18n.tr("{0} updates", count)`. Don't build sentences with template strings.
- **Dates and times** go through `I18n.formatDate(date, format)`, never `Qt.formatDateTime`, so day and month names follow the language. Named formats come from `I18n.dateFormat("longDate" | "mediumDate" | "shortDate" | "monthYear" | "fullDate" | "time24" | "time12")`.
- **The schema form translates itself.** The generic `Schema*` form widgets translate their own `label`/`title`/`description` and dropdown option labels. Callers pass English, and schema titles and descriptions need no code.
- **Adding a language** means adding `config/i18n/<code>.json`: `{"_meta": {"name", "locale", "formats"}, "strings": {english: translation}}`. It then appears in the language dropdown (`x-options: "languages"`).
- **Missing entries fall back to English.** The active dictionary reloads live when edited.
- **Checking coverage.** Run `scripts/check_i18n.py` after changing text; it lists missing and unused entries (`--fill` adds the missing ones empty, `--untranslated` finds UI literals not wrapped in `tr()`).
  - Keys only chosen at runtime (e.g. `I18n.tr(form.shape)`) must be declared in a comment next to the call, as `I18n.tr("square") ...`, so the checker sees them.
- **Leave developer-facing strings in English:** logs, validation errors, migration notes.

### Bar / widget composition pattern

`shell/Bar.qml` renders one `BarPanel` per entry in `Bar.bars` (a `Variants`/model), so multi-monitor / multi-panel bars are data-driven from config, not hardcoded. Each module's options live under its `<Type>Widget.properties.properties` definition in the schema. `SchemaValidation` picks the `BarWidget` oneOf option by `type`, so widget properties get their defaults filled like the rest of the config and modules read `properties.<key>` directly. The bar editor (`views/barEditor/WidgetItemDelegate.qml`) renders them with the same `SchemaField` rows as the settings menu. Bar contents are built from `components/bar/{BarContainer,BarWidgetHost,WidgetGroup,BarPanel}.qml` composing widgets from `components/bar/widgets/<type>.qml` (Time, Battery, Network, Workspaces, Media, SystemTray, Notifications, etc.). A widget opens a popout by dropping in a `PopoutAnchor` with a `popoutName`; the per-bar `BarPopouts` (in `hosts/popout/`) loads `content/<popoutName>.qml` by URL, so a new popout is a content file plus an anchor.

### Content (loaded by name, shown by hosts)

`components/content/<Name>.qml` holds every loadable panel. The name is the overlay module `type` (`OverlayModule.oneOf`) and/or a bar `popoutName`; one file can be both (AudioMixer, BluetoothDevices, Notifications, Updates). Hosts load it by URL and pass their context:
- **Roots.** `Card` (`content/base/`) is a free-form card (box, `properties`, slot context); card-only content uses it. `Panel` lays its children out in a column and works in either host: in a bar popout it sizes to its content with the popout box (`wrapper` set, `hovered` read for dismissal); in a card the host passes `embedded: true`, it fills the slot with the card box, and `compactContent` (e.g. a `StatFigure`) replaces the column in a quarter slot. Both expose `properties`, `slotRect`, `cols`/`rows`, `shape`, `compact`, `pad`.
- **Hosts.** `hosts/overlay/OverlaySlot` (card: `properties`, `slotRect`, `embedded: true`) and `hosts/popout/BarPopouts` (popout: `wrapper`, then the anchor's payload keys copied onto matching properties).
- Pairs that look different by design stay separate files: `Weather` (card) / `WeatherForecast` (popout), `NowPlaying` / `Media`, `ClockCalendar` / `Calendar`.

### Overlay composition (views → columns → cells → modules)

`Overlay.views` in the schema drives the overlay's pages, just as `Bars` drives the bar. Views are made of columns, columns of cells, and cells of modules. Everything loads by naming convention, so there are no lookup tables:
- **View** (`OverlayPages` → `OverlayView`): `components/views/<type>.qml`, which receives `screen` and `viewConfig`. `Custom` (`views/Custom.qml`) places its `columns` side by side. `Keybinds` and `BarEditor` are hand-built pages. The bar editor's own pieces live in `views/barEditor/`.
- **Column** (`OverlayColumn`): just `{ cells: [...] }`. The cells flow left to right and wrap at the column's widest cell, so Singles after a Wide sit side by side under it; an empty Single acts as a gap. `OverlayConfig.columnFlow(cells)` computes the same arrangement, which the editor preview uses for sizing.
- **Cell** (`OverlayCell`): `layout` names an entry in `OverlayConfig.layouts`. Each entry is `{ cols, rows, slots: { name: [col, row, colSpan, rowSpan] } }` on a half-card grid, and `OverlayConfig.span(n)` converts half units to pixels. `Tall` (two cards high) and `Wide` (two cards wide) hold panel-sized modules. Adding a layout means one entry there plus the `OverlayCell.layout` enum in the schema.
- **Module** (`OverlaySlot`): `content/<type>.qml`, filling its slot. Its root is `Card` (box, `properties`, slot context; override only what differs, like `color`) or `Panel` (see Content). Titled scrolling panels (Settings, ThemeEditor, the bar editor panels) use `TitledCard`, which has a `CardHeader` with `title`, `dirty`, `save()`/`reset()`, `headerExtras`, and children that go into the scrolling body. Adding a module means the file plus an `…OverlayModule` definition in `OverlayModule.oneOf`, with `x-shapes` listing the slot shapes it fits. Shapes are `square`, `horizontal` and `vertical`, taken from the slot's span (`OverlayConfig.slotShape`/`fits`); leaving `x-shapes` out means any shape. The editor only offers modules that fit and treats a misfit as a problem that blocks Save, and `OverlayCell` logs a warning for one. Helpers used only by content go in `content/parts/` (subfolders for groups, e.g. `parts/settings/`). `OverlaySlot` imports `qs.components.content` so that `qs` scans the URL-loaded content; without it, their own `qs.*` imports fail with "not installed".

Views and modules are `oneOf`s discriminated by `type`, like `BarWidget`.

**Loading:** one overlay per screen in `General.screens` (`shell/Overlay.qml`). Only the current page and its neighbours (navigation wraps) are instantiated, and only while the overlay is open (`OverlayPages.isLoaded` → `OverlayPage.loaded`), so modules must not assume they live forever: acquire in `Component.onCompleted`, release in `onDestruction`, and keep state that must survive in a service.

**Writing overlay modules:**
- **Shape-aware.** `Card` and `Panel` expose the slot's `slotRect`, `cols`/`rows` (half units), `shape` and `compact` (a quarter slot), plus `pad`. Each module picks its internal layout from these: side by side when horizontal, stacked when vertical, the key figure only when compact.
- **Shared parts** live in `content/parts/`: `ModuleHeader`, `Sparkline`, `StatFigure`, `IconToggle`.
- **Content can be both.** A `Panel`-rooted file is a bar popout and a card at once; branch on `embedded` for card-only parts (a header, a mode switch, acquiring with the card's `properties`).
- **Data sources.**
  - `SystemManager` adds `history: true` (60-sample ring buffers), a `net` metric (`/proc/net/dev` rates plus a 10s nmcli poll for `netInfo`/`wifiEnabled`, with `setWifi`) and a `processes` metric (two-frame `top`, with `kill(pid)`).
  - Weather comes from `WeatherManager` (acquire with `{ latitude, longitude, location, units, intervalMinutes }`, read `sourceFor(request)`): one `WeatherSource` per distinct location and units, shared by the bar widget and the module.
- **Never derive a Repeater model, or anything passed to `acquire()`, from live values.** Build it from config (and tool availability) only. When the set of items is itself derived, model the Repeater by a joined string key or a count (`model: rows.length`, delegate reads `rows[index]`): an `int`/`string` only notifies when it actually changes, so the delegates survive each sample. A model that re-evaluates on every sample rebuilds its delegates (and Canvases) many times a second. That once pushed qs past 25 GB. `SystemManager.acquire()` now ignores identical re-registrations.
- **Testing a module safely.**
  - The running shell only picks up schema changes on a QML reload, and a reload only fires when a file it has *loaded* changes. A new module file doesn't count until something uses it.
  - A config checked against a stale schema fails validation, and the whole shell falls back to defaults until it's fixed.
  - So confirm the schema was reloaded after your edit before putting a new module into `config.json`. Add modules one at a time and watch `qs`'s RSS.

**Overlay editor:**
- `views/OverlayEditor.qml` with its pieces in `views/overlayEditor/`. It's not in config: `OverlayPages` adds it as a persistent page after the Repeater, so it's always last, can't be removed, and survives the page rebuild that every config change causes.
- All edits go through `services/OverlayManager.qml`, a draft copy of `Overlay.views` like `BarManager`: `problems` blocks Save, and Save merges onto the latest config.
- The preview draws `PlaceholderTile`s from `OverlayConfig.layouts` at a computed scale, not with `Item.scale`.
- Module and view pickers read `OverlayConfig.availableModuleTypes` / `availableViewTypes`, which come from the schema's `oneOf`s, so new types show up there automatically. The slot panel generates property rows from each module's `properties` schema.
- `TypePickerPopup` (overlay root) is the shared "pick a type" popup used by both the bar editor and the overlay editor.

### Popouts (bar + screen edge)

Shared pieces live in `components/hosts/popout/`: `PopoutWrapperBase` (open/close/queue state, hover-loss dismiss timer), `SlideAnimation`, and `AttachedSurface` (the content box + connector + `CornerPiece` fillets that make a popout look like it grows out of a bar or the screen border; `edge` is a `Bar.Location`). Bar popouts (`BarPopouts.qml`) share one wrapper per bar. Screen-edge popouts (`EdgePopout.qml`, used by `OSD.qml` and `ThemeSelector.qml`) are one independent instance per screen (`Variants` over `Quickshell.screens`). Each is an Overlay-layer `PanelWindow` with Normal exclusion and a `-borderWidth` margin, so it lands on the inner stroke of whatever reserves that edge: the border (`surfaces/border/`) or a bar.

Icon + label bar widgets extend `bar/widgets/BarIconWidget.qml` (the BarWidgetHost inputs `barConfig`/`popouts`/`panel`/`screen`/`properties`, orientation, configured colors; override `backgroundColor` for states). `components/reusable/BaseWidget.qml` is the common sizing/background wrapper underneath (`Widget.height`, `Widget.padding`, `Appearance.borderRadius`, vertical/horizontal orientation via `Bar.vertical`).

### Lockscreen (`Lockscreen.mode`)

`LockManager.lock()` is the one way to lock; lock buttons call it through `ShellManager.sessionAction("lock")`, and idle daemons through the `lockscreen` IPC target:
- **`quickshell`** (default): the built-in locker, `shell/Lockscreen.qml`. A `WlSessionLock` (Wayland `ext-session-lock-v1`, the protocol hyprlock uses) with one `WlSessionLockSurface` per screen showing `surfaces/lockscreen/LockSurface.qml`. While locked the compositor shows only the lock surfaces and sends them all input; if qs dies the session stays locked (Hyprland's fallback; `misc:allow_session_lock_restore` lets a restarted qs take it back). The locked state lives in a `PersistentProperties`, so a QML reload comes back locked. **Only `AuthManager.authenticationSucceeded` (PAM, `login` stack) unlocks**: there is no IPC unlock, and nothing on the surface may run commands.
- **`hyprlock`**: `ThemeManager.generateHyprlockConfig()` writes `$XDG_STATE_HOME/axiom/hyprlock.conf` from `scripts/templates/hyprlock_template.conf` (theme colors, font, wallpaper, blur, translated greeting) on theme/wallpaper/font/language changes and on switching to this mode; lock runs `hyprlock -c` with it. The user's own `hyprlock.conf` is never touched.
- **`none`**: axiom provides no locker and no IPC target (so an idle daemon pointed at axiom can't loop through `loginctl lock-session`); lock buttons run `Lockscreen.lockCommand`.
- **hypridle** for the first two: `lock_cmd = qs -c axiom ipc call lockscreen lock`, `before_sleep_cmd = loginctl lock-session`; for `none`, no axiom references.

### Naming

- **Services** are `*Manager` singletons; non-singleton helper types in `services/` (`ConfigDraft`, `ConsumerRegistry`, `WeatherSource`) are named for what they are.
- **Config readers** are named for their schema section, with a `Config` suffix only where the section name is a type (`OSDConfig`, `OverlayConfig`, …). `Paths` holds derived paths.
- **Hosts** say what they host: `BarWidgetHost` (one bar widget), `OverlaySlot` (content in a cell slot), `OverlayPages` / `OverlayView` (the overlay's pages / one view), `BarPopouts` (a bar's popouts).
- **Content** files are named by their overlay module `type` and/or bar `popoutName`; roots are `Card`, `Panel`, `TitledCard` (+ `CardHeader`).
- **Reusable widgets** that stand in for a Qt control are `Styled*` (`StyledText`, `StyledTabBar`, …), which avoids clashes with QtQuick.Controls names; composites are named for what they are (`SquareIconButton`, `IconTextWidget`).
- **Surface windows** get a `Window` suffix when their shell entry has the same concept's name (`shell/PowerMenu` → `PowerMenuWindow`).
- **Root ids** are `root` (the exceptions keep a different id only because the file already uses `root` for a child, or the id is also a keyword or property name).
- **Bar widget and content names can overlap** (`Weather`, `Media`, …: schema types, so config depends on them). No file may see both: `scripts/check_structure.py` errors if a file instantiates a type that two of its visible directories define.

## Known housekeeping (from README TODO — informs likely refactor asks)

- Variable naming is not yet consistent across the codebase.
- Some components still use inline properties instead of `alias`es to reusable components.
