# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.org) desktop shell config (QML) for Hyprland, named "axiom". It provides the bar, notifications, lockscreen, app launcher, power menu, OSD, workspace overlay, and rounded corners for the compositor. There is no build step — QML is interpreted at runtime by the `qs` binary.

## Running / reloading

- The shell runs as a detached background process; it is not started/stopped via a foreground terminal command in this session.
- **View logs**: `scripts/log.sh`. It prints warnings/errors since the last reload with colour stripped, so a clean reload is just `Reloading configuration...` + `Configuration Loaded`. Add `--debug` to include `console.log` output, `--all` for the whole history, `-f` to follow, and `-g PATTERN` to grep. It wraps `qs log -c axiom -r <rules>`. Don't rely on stdout or journalctl, since output is redirected to /dev/null. `console.log` is debug level and hidden by default, so use it freely for tracing, and keep `console.warn` for real problems. A normal reload should produce no warnings.
- Config reloads are automatic: `ConfigManager` polls `config/user/config.json` and the active theme file every second and hot-reloads on change (see `services/ConfigManager.qml` `_checkForChanges`). `config/user/config.json` is owned by the settings UI (not meant for hand-editing), but editing it directly is still a valid way to test config changes without restarting.
- New singleton files (a new `pragma Singleton` QML file in `config/` or `services/`) are only registered when `qs` starts; hot reload picks up edits to existing ones but a newly added singleton reads as `undefined` until a full restart.
- Lockscreen can be triggered externally via `qs -c axiom ipc call lockscreen lock` (see hypridle.conf).
- Do not simulate cursor movement (e.g. `hyprctl dispatch movecursor`) to verify UI behavior — check logs/code instead.
- No automated test suite exists. Verify QML changes by running `scripts/log.sh` after a save (which triggers reload), and by reasoning through property bindings — there's no headless QML test runner set up here.

## Formatting

- `.qmlformat.ini` pins `qmlformat` settings: spaces not tabs, 2-space indent, no max column width. Run `/usr/lib/qt6/bin/qmlformat -i` on changed `.qml` files before committing. The `qmlformat` on PATH is Qt5's, which can't parse `pragma ComponentBehavior` and fails silently (exit 1, no output).
- The QML JS engine has no `Array.prototype.flatMap`; use `[].concat(...arr.map(...))`.

## Architecture

### Directory roles (from CONTRIBUTING.md)
```
shell.qml       entrypoint — instantiates one top-level Item per module (Bar, Lockscreen, Notifications, Overlay, OSD, ThemeSelector, AppLauncher, PowerMenu, WorkspaceOverlay, RoundedCorners)
modules/        top-level pieces loaded directly into shell.qml
components/     reusable UI building blocks
  reusable/     generic styled widgets (StyledRectButton, StyledTextEntry, BaseWidget, etc.) with no feature-specific logic
  widgets/      feature-specific composed components, grouped by feature (bar/, notifications/, popouts/, lockscreen/, menu/, applauncher/, powermenu/, workspaces/, overlay/, workspaceContainer/, common/)
  methods/      singleton pure-function helpers (Utils, IconResolver, SchemaValidation, WindowUtils, WorkspaceUtils)
  stolen/       code adapted from other dotfiles/projects, kept isolated pending reimplementation — see components/stolen/README.md
services/       pragma Singleton QtObjects — global state and side-effecting logic (see below)
config/         static QML config singletons + JSON config/theme files
assets/         static assets (icons, images)
scripts/        Python/shell scripts invoked as external processes (theming, wallpaper, stats) from qs.services
```

### Import convention

QML files import project-internal singletons/components via the `qs.` namespace, mapped to this repo root, e.g. `import qs.services`, `import qs.config`, `import qs.components.widgets.bar`. There are no `qmldir` files — Quickshell resolves `qs.*` automatically from the shell root directory. Prefer this over relative imports.

Most files also start with `pragma ComponentBehavior: Bound` (for delegates/components using `required property`) or `pragma Singleton` (for services/config singletons).

### Services layer (`services/*.qml`)

Every file is `pragma Singleton QtObject` — one global instance per name, imported as `qs.services`. Key ones:
- **ConfigManager** — the source of truth for runtime config. Owns `_config` (parsed `config/user/config.json`), `_theme` (parsed active theme JSON), and `_configSchema`, loaded eagerly at creation. Load pipeline: parse → `ConfigMigration.migrate` (upgrades old layouts by `version`, writes the result back once, moves API keys to `Secrets`) → `SchemaValidation.pruneUnknown` (drops unknown keys with a warning) → `SchemaValidation.applyDefaults` (fills every schema `default`) → validate. All config writes go through `setTheme()` / `setWallpaper()` / `saveConfig()`, which validate before writing, then trigger `forceReload()` and `themeIntegrations()`. Never mutate `ConfigManager.config` fields directly from UI code and expect persistence — call the setter functions (or `SettingsMenu.setValue(path, value)` from settings UI).
- **Secrets** — chat API keys, never in config.json: `$<BACKEND>_API_KEY` env var, else `$XDG_STATE_HOME/axiom/secrets.json` (mode 600).
- **ThemeManager** — theme discovery (`allThemes`/`defaultThemes`/`generatedThemes` ListModels via `FolderListModel`), theme generation from a wallpaper (spawns `scripts/generate_theme.py` per backend: wal, colorz, colorthief, haishoku), and dark/light pairing logic. Delegates actual persistence to `ConfigManager.setTheme`.
- **ShellManager** — cross-cutting UI signals (dark mode, lock screen, power menu) that modules connect to rather than calling each other directly.
- **SystemManager** — CPU/memory/temp/GPU/disk stats. Reference-counted: consumers call `acquire(owner, {interval, metrics, diskPaths})` / `release(owner)`, and it polls only the union of requested metrics (sysfs/procfs `FileView` reads, no processes on the hot path), stopping entirely with no consumers.
- **PackageUpdates** — pending pacman/AUR updates shared by every Updates widget (same acquire/release pattern). Only one `checkupdates` may run at a time: concurrent runs share its temp db and fail.
- **BluetoothManager** — adapter power, scanning, sorted device lists and connect/pair/forget over `Quickshell.Bluetooth`. Not named `Bluetooth`, which would shadow Quickshell's singleton (and the `Bluetooth` bar widget file).
- **IdleInhibit** — shared caffeine state + `idleInhibit` IPC target; the Wayland inhibitor itself lives in `bar/modules/IdleInhibitor.qml` (it needs a window).
- Other domain services (Audio, Battery, MprisController, Notifs, HyprlandData, HyprConfigManager, StateManager, BarManager, LauncherManager, SettingsMenu, Authentication, Chat) follow the same singleton pattern — one owns polling/IPC/process-spawning for its domain and exposes readonly properties + signals.

### Config layer (`config/*.qml`)

Also `pragma Singleton`, but these are typed config *readers*, not owners — one per config section, exposing `readonly property` values from `ConfigManager.config`. No `??` fallbacks: the schema defaults are already filled in. Readers: `General` (displayName, primaryMonitor), `Appearance` (theme, font, shape, motion tokens), `Widget`, `Bar` (from `Bars`; the first bar is primary), `PopoutConfig` (open/dismiss delays, edge trigger size — shared by bar and edge popouts), `OSDConfig` (volume OSD: edge, position, orientation, timeout, tracked apps), `SidePanel`, `OverlayConfig` (views + card-grid constants), `IconConfig`, `ChatConfig`, `ThemeIntegrations`, plus `Config` (derived paths from `$HOME` / `Quickshell.shellDir`, not configurable) and `Theme`. Readers whose section name collides with a type get a `Config` suffix (`Popouts`, `Overlay`, `Icons`, `OSD`). UI code should read colors/settings from these (`Theme.background`, `Widget.padding`, `Bar.extent`) rather than reaching into `ConfigManager.config` directly.

**Animation timing is uniform:** every `duration:` uses `Appearance.animFast` / `animNormal` / `animSlow` (derived from `Appearance.motion.speed`, and 0 when `motion.enabled` is off), never a literal. Looping animations also gate `running` on `Appearance.animations`. Only behaviour timings (cursor blink, notification timeout, polling) stay as literals.

`config/Theme.qml` exposes the base16 palette (`base00`-`base0F`) plus semantic aliases (`background`, `accent`, `error`, etc.) resolved through `_themeData.semantic`, and a `stringToColorMap` + `resolveColor(name)` for dynamic color lookup by string (used when a color name comes from JSON/config rather than a static binding).

`config/json/config.schema.json` is the single source of truth: shape, `default`s, and — via `title`/`description`/`minimum`/`maximum`/`enum`/`x-options` — the settings UI, which is generated from it (`components/widgets/common/SchemaForm.qml`; `x-settings: false` hides a key). Adding a setting = add it to the schema (with a default) and a reader property. `x-options: "colors"` makes a string a color picker over `base00`–`base0F` (read it with `Theme.resolveColor`, which also accepts semantic names and hex); `x-showIf` hides a field unless a sibling has a given value. An `array` whose `items` is an object schema renders as an add/remove/reorder list of those fields (`SchemaArrayItem`). There is no separate defaults file. The live file is `config/user/config.json` (gitignored, UI-owned); bump `version` and extend `ConfigMigration` when changing its layout. Theme JSON files live in `config/themes/*.json` (static) and `config/themes/generated/*.json` (pywal-style, generated from wallpaper).

### Bar / widget composition pattern

`modules/Bar.qml` renders one `BarPanel` per entry in `Bar.bars` (a `Variants`/model), so multi-monitor / multi-panel bars are data-driven from config, not hardcoded. Each module's options live under its `<Type>Widget.properties.properties` definition in the schema. `SchemaValidation` picks the `BarWidget` oneOf option by `type`, so widget properties get their defaults filled like the rest of the config and modules read `properties.<key>` directly. The bar editor (`overlay/views/barEditor/WidgetItemDelegate.qml`) renders them with the same `SchemaField` rows as the settings menu. Bar contents are built from `components/widgets/bar/{BarContainer,BarModule,WidgetGroup,BarPanel}.qml` composing individual modules from `components/widgets/bar/modules/*.qml` (Time, Battery, Network, Workspaces, Media, SystemTray, Notifications, etc.). Bar popouts follow a shared `PopoutWrapperBase`/`PopoutAnchor` pattern: `components/widgets/bar/popouts/` holds only the plumbing (`Popouts.qml`, the per-bar wrapper that maps a popout name to its content, and `PopoutAnchor.qml`, which modules drop in to open one), and every popout's content (plus helpers only content uses, e.g. `AudioRow`, `TrayMenuItem`, `TraySubmenuWrapper`) lives in `bar/popouts/content/`. A new popout = a file in `content/` + a case and Component in `Popouts.qml`.

### Overlay composition (views → columns → cells → modules)

`Overlay.views` in the schema drives the overlay's pages, just as `Bars` drives the bar. Views are made of columns, columns of cells, and cells of modules. Everything loads by naming convention, so there are no lookup tables:
- **View** (`OverlayTabWrapper` → `OverlayViewWrapper`): `views/<type>.qml`, which receives `screen` and `viewConfig`. `Custom` (`views/Custom.qml`) places its `columns` side by side. `Keybinds` and `BarEditor` are hand-built pages. The bar editor's own pieces live in `views/barEditor/`.
- **Column** (`OverlayColumn`): just `{ cells: [...] }`, stacked top to bottom.
- **Cell** (`OverlayCell`): `layout` names an entry in `OverlayConfig.layouts`. Each entry is `{ cols, rows, slots: { name: [col, row, colSpan, rowSpan] } }` on a half-card grid, and `OverlayConfig.span(n)` converts half units to pixels. `Tall` (two cards high) and `Wide` (two cards wide) hold panel-sized modules. Adding a layout means one entry there plus the `OverlayCell.layout` enum in the schema.
- **Module** (`OverlayModule`): `modules/<type>.qml`, filling its slot. A module's root is `OverlayCard`, which provides the card box and `properties`; override only what differs, like `color`. Titled scrolling panels (Settings, ThemeEditor, the bar editor panels) use `PanelCard`, which has a `PanelHeader` with `title`, `dirty`, `save()`/`reset()`, `headerExtras`, and children that go into the scrolling body. Adding a module means the file plus an `…OverlayModule` definition in `OverlayModule.oneOf`. Helpers used only by modules go in subfolders (`modules/settings/`). `OverlayModule` imports `qs.components.widgets.overlay.modules` so that `qs` scans the URL-loaded modules; without it, their own `qs.*` imports fail with "not installed".

Views and modules are `oneOf`s discriminated by `type`, like `BarWidget`.

### Popouts (bar + screen edge)

Shared pieces live in `components/widgets/popouts/`: `PopoutWrapperBase` (open/close/queue state, hover-loss dismiss timer), `SlideAnimation`, and `AttachedSurface` (the content box + connector + `CornerPiece` fillets that make a popout look like it grows out of a bar or the screen border; `edge` is a `Bar.Location`). Bar popouts (`bar/popouts/Popouts.qml`) share one wrapper per bar. Screen-edge popouts (`EdgePopout.qml`, used by `modules/Menu.qml`, `OSD.qml`, `ThemeSelector.qml`) are one independent instance per screen (`Variants` over `Quickshell.screens`). Each is an Overlay-layer `PanelWindow` with Normal exclusion and a `-borderWidth` margin, so it lands on the inner stroke of whatever reserves that edge: the border (`workspaceContainer/`) or a bar.

`components/reusable/BaseWidget.qml` is the common sizing/background wrapper most bar modules build on (`Widget.height`, `Widget.padding`, `Appearance.borderRadius`, vertical/horizontal orientation via `Bar.vertical`).

## Known housekeeping (from README TODO — informs likely refactor asks)

- Variable naming is not yet consistent across the codebase.
- Some components still use inline properties instead of `alias`es to reusable components.
- `components/stolen/` is intentionally temporary — treat replacing it with native implementations as welcome cleanup, not scope creep, if asked.
