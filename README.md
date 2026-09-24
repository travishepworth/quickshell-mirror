# axiom

A desktop shell for [Hyprland](https://hypr.land), written in QML for [Quickshell](https://quickshell.org).
axiom is the widget half of [Axiom Dotfiles](https://github.com/axiom-dotfiles). It covers the bar, the overlay, notifications, the lockscreen, the app launcher, the power menu, the OSD, the workspace overlay, and the rounded screen border.

https://github.com/user-attachments/assets/a53f62e0-e2bc-4834-a05f-92b6cb115c35

> [!NOTE]
> This is a public mirror for issue tracking. Pull requests aren't accepted yet and will be closed. Issues are welcome: they are read, discussed and fixed here.
> axiom is pre-1.0, so the layout of `config.json` can still change between versions. Old configs are migrated automatically.

## Features

**Bar**
- Bars are defined in config. You can have any number, on any monitor and any edge, each one solid, transparent or split into floating pills.
- 21 widget types: Workspaces, a 5×5 WorkspaceGrid, Window, Time, Media, Volume, Microphone, Network, Bluetooth, Battery, SystemStats, SystemTray, Notifications, Updates, Weather, Tailscale, KeyboardLayout, IdleInhibitor, Privacy, Button (runs any command) and Separator.
- Popouts grow out of the bar, or out of the screen border, with filleted corners.

**Overlay**
- A full-screen overlay made of pages of cards. Each page is built from columns, each column from cells, and each cell holds modules.
- 23 modules, including a media player, audio mixer, system graphs, top processes, disks, updates, quick toggles, Bluetooth, network, weather, calendar, notes, favourites, screenshot, session controls, a workspace map and AI chat.
- Modules adapt to the shape of their slot (square, wide, tall or quarter).
- Built-in pages: a **Settings** page generated from the config schema, a **Bar editor**, an **Overlay editor**, **Themes** and **Keybinds**.

**Theming**
- Base16 themes, with dark and light pairs switched by one toggle: Catppuccin, Gruvbox, Solarized, Tokyo Night/Day and Submarine Sonar.
- Generate a theme from your wallpaper. pywal backends pick the candidate colors, then the palette is built in OKLCH to match the contrast of the hand-made themes.
- Wallpapers can be set per monitor, with transitions through [awww](https://github.com/LGFae/awww).
- The active theme is applied to kitty, cava, k9s, Neovim and hyprlock.

**The rest**
- Notification toasts and a notification center.
- An OSD that follows the volume of the apps you choose.
- A launcher that searches apps (ranked by how often and how recently you use them), open windows, a calculator and the web, runs shell commands, and controls the shell with `/` commands. A power menu that asks you to confirm.
- A workspace overlay with live window previews: drag a window onto a side of another window or onto another workspace, right-drag to resize it, middle-click to close it.
- AI chat with Gemini, OpenAI, Anthropic or an offline backend. API keys are read from environment variables or a secrets file with mode 600, never from `config.json`.
- A lockscreen with three modes: the built-in `ext-session-lock` locker (PAM), a themed hyprlock config that axiom generates, or none.
- Multi-monitor: interactive surfaces open on the primary monitor, or on whichever monitor has focus.
- Translations: English and Japanese, with more added as a single JSON file each.

## Requirements

**Required**
- Hyprland
- [Quickshell](https://quickshell.org) 0.3.1 or newer (`qs`)
- A Nerd Font (`Symbols Nerd Font`) for icons
- `jq`, `python3`

**Optional**, for the features that use them:

| Feature | Needs |
| --- | --- |
| Wallpapers | `awww` |
| Theme generation | ImageMagick (`magick` or `convert`). The Python packages are installed into `.venv` automatically from `scripts/requirements.txt` |
| Network widget / module | NetworkManager (`nmcli`) |
| Updates | `pacman-contrib` (`checkupdates`), plus `paru` or `yay` for AUR updates |
| Tailscale | `tailscale` |
| Screenshot module | `grim`, `slurp`, `wl-copy` |
| Launcher calculator | `qalc` (libqalculate), `wl-copy` |
| NVIDIA GPU stats | `nvidia-smi` (AMD is read from sysfs) |
| hyprlock mode | `hyprlock`, and `hypridle` to lock on idle |
| Theme integrations | `kitty`, `cava`, `k9s`, `nvim` |

## Installation

There's no installer yet. Clone into Quickshell's config directory:

```bash
git clone https://github.com/axiom-dotfiles/axiom.git ~/.config/quickshell/axiom
```

Start it from your Hyprland config:

```ini
exec-once = QML_XHR_ALLOW_FILE_READ=1 qs -c axiom
```

`QML_XHR_ALLOW_FILE_READ=1` is required, because the config, translations and theme files are read through `XMLHttpRequest`.

The [hypr](https://github.com/axiom-dotfiles/hypr) repository has a matching Hyprland config, with the keybinds below already set up.

## Keybinds and IPC

Every surface can be controlled over Quickshell IPC, so you can bind it to anything:

```bash
qs -c axiom ipc call <target> <function>
```

| Target | Functions |
| --- | --- |
| `overlay` | `open`, `close`, `toggle` |
| `appLauncher` | `open`, `close`, `toggle`, `search <text>` |
| `powermenu` | `open`, `close`, `toggle` |
| `workspaceOverlay` | `show`, `hide`, `toggle` |
| `idleInhibit` | `enable`, `disable`, `toggle`, `status` |
| `lockscreen` | `lock` |

```ini
bind = SUPER, SPACE, exec, qs -c axiom ipc call appLauncher toggle
bind = SUPER, TAB, exec, qs -c axiom ipc call overlay toggle
bind = SUPER, T, exec, qs -c axiom ipc call appLauncher search "/theme "
```

### Launcher

Plain text searches apps and open windows. When the text is math, the result shows first, and a web search comes last. A prefix picks one kind of search:

| Prefix | Does |
| --- | --- |
| `/` | Shell commands (list below) |
| `=` | Calculator (qalc: math, units, currencies). Enter copies the result |
| `>` | Runs a shell command. Shift+Enter runs it in your terminal |
| `?` | Web search, with the engine set in Settings |

Tab completes a command or its argument. Commands that change something you can see, like the theme, volume or wallpaper, keep the launcher open, so you can try several. `logout`, `reboot` and `poweroff` ask for a second Enter.

- **Session:** `/lock` `/suspend` `/hibernate` `/logout` `/reboot` `/poweroff` `/power`
- **Pages:** `/overlay [page]` `/settings` `/themes` `/bar` `/keybinds` `/editor` `/workspaces`
- **Look:** `/theme <name>` `/dark` `/light` `/mode` `/wallpaper <file|Random>` `/generate`
- **Audio and media:** `/volume <n|+n|-n>` `/mute` `/mic` `/output <device>` `/input <device>` `/play` `/next` `/prev`
- **Connectivity:** `/wifi [on|off]` `/bluetooth [on|off]` `/connect <device>`
- **Other:** `/dnd [on|off]` `/clear` `/caffeine [on|off]` `/ws <n>` `/save-config <name>` `/restore-config <name>` `/reload` `/help`

Every provider can be switched off under Settings › Desktop › Launcher. The same page sets the launcher's size, hidden apps, terminal and search engine, and where it opens: floating (centered or in the upper third), or attached to the top or bottom edge like the other edge popouts, with the search field above or below the results.

### Locking with hypridle

For the `quickshell` and `hyprlock` lockscreen modes:

```ini
general {
    lock_cmd = qs -c axiom ipc call lockscreen lock
    before_sleep_cmd = loginctl lock-session
}
```

In `none` mode axiom doesn't register the `lockscreen` target. Point hypridle at your own locker, and set **Lockscreen → Lock command** so that axiom's lock buttons run it too.

## Configuration

Everything is configured from inside the shell. Open the overlay, and use the **Settings**, **Bar editor**, **Overlay editor** and **Themes** pages.

- Settings are saved to `config/user/config.json`. The shell watches that file and reloads when it changes, so editing it by hand also works.
- An invalid `config.json` never replaces the running config. The shell keeps the last good one and refuses to save until the file is fixed.
- Configs from older versions are migrated automatically.
- `config/json/config.schema.json` defines every option and its default. It also generates the Settings page.
- Chat API keys are read from `GEMINI_API_KEY`, `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`. If those aren't set, they come from `$XDG_STATE_HOME/axiom/secrets.json`.

### Themes

- Hand-made themes live in `config/themes/`, and generated ones in `config/themes/generated/`.
- A theme is a base16 palette (`base00`–`base0F`) plus optional semantic overrides. See `config/themes/theme.schema.json`.
- To add a theme, drop a JSON file in `config/themes/`. To make a dark/light pair, give each file a `paired` field naming the other.

### Translations

- Pick a language in **Settings → General → Language**.
- To add a language, create `config/i18n/<code>.json` (see `ja.json`). It shows up in the dropdown right away.
- Missing strings fall back to English. `scripts/check_i18n.py` reports what's missing.

## Troubleshooting

View the shell's log with:

```bash
scripts/log.sh          # warnings and errors since the last reload
scripts/log.sh --debug  # include console.log output
scripts/log.sh -f       # follow
```

A clean reload prints only `Reloading configuration...` and `Configuration Loaded`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the directory layout and conventions, and [CLAUDE.md](CLAUDE.md) for the architecture in detail. There's no build step: `qs` interprets the QML and hot-reloads on save.

## Roadmap

- [ ] Onboarding and a setup wizard
- [ ] Installer / AUR package
- [ ] More translations
- [ ] CI, plus issue and pull request templates
- [ ] First stable release, after which changes land through PRs only

## License

[MIT](LICENSE)
