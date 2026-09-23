# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.org) desktop shell config (QML) for Hyprland, named "axiom". It provides the bar, notifications, lockscreen, app launcher, power menu, OSD, workspace overlay, and rounded corners for the compositor. There is no build step — QML is interpreted at runtime by the `qs` binary.

## Running / reloading

- The shell runs as a detached background process; it is not started/stopped via a foreground terminal command in this session.
- **View logs**: `qs log -c axiom -f` — do NOT rely on stdout or journalctl, output is redirected to /dev/null.
- Config reloads are automatic: `ConfigManager` polls `config/user/config.json` and the active theme file every second and hot-reloads on change (see `services/ConfigManager.qml` `_checkForChanges`). Editing `config/user/config.json` directly is a valid way to test config changes without restarting.
- Lockscreen can be triggered externally via `qs -c axiom ipc call lockscreen lock` (see hypridle.conf).
- Do not simulate cursor movement (e.g. `hyprctl dispatch movecursor`) to verify UI behavior — check logs/code instead.
- No automated test suite exists. Verify QML changes by watching `qs log -c axiom -f` for errors/warnings after a config file save (which triggers reload), and by reasoning through property bindings — there's no headless QML test runner set up here.

## Formatting

- `.qmlformat.ini` pins `qmlformat` settings: spaces not tabs, 2-space indent, no max column width. Run `qmlformat` on changed `.qml` files before committing if available.

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
- **ConfigManager** — the source of truth for runtime config. Owns `_config` (parsed `config/user/config.json`), `_theme` (parsed active theme JSON), and `_configSchema`. All config writes go through `setTheme()` / `setWallpaper()` / `saveConfig()`, which validate against the JSON schema before writing (via `SchemaValidation`), then trigger `forceReload()` and `themeIntegrations()`. Never mutate `ConfigManager.config` fields directly from UI code and expect persistence — call the setter functions.
- **ThemeManager** — theme discovery (`allThemes`/`defaultThemes`/`generatedThemes` ListModels via `FolderListModel`), theme generation from a wallpaper (spawns `scripts/generate_theme.py` per backend: wal, colorz, colorthief, haishoku), and dark/light pairing logic. Delegates actual persistence to `ConfigManager.setTheme`.
- **ShellManager** — cross-cutting UI signals (panel pin/lock/reservation toggles, lock screen, power menu) that modules connect to rather than calling each other directly.
- Other domain services (Audio, Battery, MprisController, Notifs, HyprlandData, HyprConfigManager, SystemManager, StateManager, BarManager, LauncherManager, SettingsMenu, Authentication, Chat) follow the same singleton pattern — one owns polling/IPC/process-spawning for its domain and exposes readonly properties + signals.

### Config layer (`config/*.qml`)

Also `pragma Singleton`, but these are typed config *readers*, not owners — they expose `readonly property` values derived from `ConfigManager.config` / `ConfigManager.theme` with `??` fallback defaults, e.g. `config/Config.qml`, `config/Bar.qml`, `config/Widget.qml`, `config/Menu.qml`, `config/Theme.qml`. UI code should read colors/settings from these (`Theme.background`, `Widget.padding`, `Bar.extent`) rather than reaching into `ConfigManager.config` directly.

`config/Theme.qml` exposes the base16 palette (`base00`-`base0F`) plus semantic aliases (`background`, `accent`, `error`, etc.) resolved through `_themeData.semantic`, and a `stringToColorMap` + `resolveColor(name)` for dynamic color lookup by string (used when a color name comes from JSON/config rather than a static binding).

`config/json/config.schema.json` is the authority for valid config shape; `config/json/config.default.json` is the shipped default; the live, user-editable file is `config/user/config.json`. Theme JSON files live in `config/themes/*.json` (static) and `config/themes/generated/*.json` (pywal-style, generated from wallpaper).

### Bar / widget composition pattern

`modules/Bar.qml` renders one `BarPanel` per entry in `Bar.bars` (a `Variants`/model), so multi-monitor / multi-panel bars are data-driven from config, not hardcoded. Bar contents are built from `components/widgets/bar/{BarContainer,BarModule,WidgetGroup,BarPanel}.qml` composing individual modules from `components/widgets/bar/modules/*.qml` (Time, Battery, Network, Workspaces, Media, SystemTray, Notifications, etc.). Popout panels (calendar, media, tray submenu, workspace) live in `components/widgets/bar/popouts/` and follow a shared `PopoutWrapperBase`/`PopoutAnchor` pattern.

### Popouts (bar + screen edge)

Shared pieces live in `components/widgets/popouts/`: `PopoutWrapperBase` (open/close/queue state, hover-loss dismiss timer), `SlideAnimation`, and `AttachedSurface` (the content box + connector + `CornerPiece` fillets that make a popout look like it grows out of a bar or the screen border; `edge` is a `Bar.Location`). Bar popouts (`bar/popouts/Popouts.qml`) share one wrapper per bar. Screen-edge popouts (`EdgePopout.qml`, used by `modules/Menu.qml`, `OSD.qml`, `ThemeSelector.qml`) are one independent instance per screen (`Variants` over `Quickshell.screens`). Each is an Overlay-layer `PanelWindow` with Normal exclusion and a `-borderWidth` margin, so it lands on the inner stroke of whatever reserves that edge: the border (`workspaceContainer/`) or a bar.

`components/reusable/BaseWidget.qml` is the common sizing/background wrapper most bar modules build on (`Widget.height`, `Widget.padding`, `Appearance.borderRadius`, vertical/horizontal orientation via `Bar.vertical`).

## Known housekeeping (from README TODO — informs likely refactor asks)

- Variable naming is not yet consistent across the codebase.
- Some components still use inline properties instead of `alias`es to reusable components.
- `components/stolen/` is intentionally temporary — treat replacing it with native implementations as welcome cleanup, not scope creep, if asked.
