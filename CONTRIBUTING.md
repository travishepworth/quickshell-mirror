# Contributing

## Organization Strategy

### Structure
```bash
shell.qml     # entrypoint: one top-level item per module
modules/      # top-level pieces loaded directly into shell.qml
components/
  reusable/   # generic styled widgets, no feature-specific logic
  widgets/    # feature-specific components, grouped by feature
  methods/    # singleton helper functions (Utils, IconResolver, SchemaValidation, ...)
services/     # singletons owning global state and side effects
config/       # config reader singletons, the config schema, themes, translations
assets/       # static assets
scripts/      # scripts run by the shell (theming, wallpaper) and development tools
```

### Conventions
- Import project code through the `qs.` namespace (`import qs.services`).
- New settings go in `config/json/config.schema.json` with a default, plus a reader property; the settings UI is generated from the schema.
- User-visible text is English, wrapped in `I18n.tr("...")`; run `scripts/check_i18n.py` (and `--untranslated`) after changing text.
- Run `scripts/check_structure.py` after adding, renaming or moving files: types and popouts load by file name, so it catches a missing file or import before the shell does.
- Format changed QML with `/usr/lib/qt6/bin/qmlformat -i` (see `.qmlformat.ini`).

See [CLAUDE.md](CLAUDE.md) for the architecture in detail.
