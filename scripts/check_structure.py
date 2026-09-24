#!/usr/bin/env python3
"""Guard the naming conventions the shell loads by.

Much of the shell has no lookup tables: a schema type or popout name *is*
a file name, loaded by URL at runtime. A typo, a rename or a missing import
only shows up when something tries to instantiate it. This checks, without
running anything:

  - every schema type (BarWidget, OverlayView, OverlayModule oneOfs) and
    every PopoutAnchor popoutName has its file
  - every URL-loaded directory is imported by name somewhere (qs only makes
    sibling types visible to URL-loaded files in directories it scanned)
  - every `import qs.…` names a directory that exists
  - every `SomethingManager.` names a service that exists, and nothing
    references a near-miss of a project singleton (a typo)
and warns about files in the loaded directories that nothing registers or
uses.

  scripts/check_structure.py        errors (exit 1) and warnings
"""
import difflib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / "config" / "json" / "config.schema.json"
QML_DIRS = ["components", "modules", "services", "config"]

# (schema oneOf definition, directory its types load from, import that must
# exist somewhere so qs scans that directory)
LOADERS = [
    ("BarWidget", "components/widgets/bar/modules", "qs.components.widgets.bar.modules"),
    ("OverlayView", "components/widgets/overlay/views", "qs.components.widgets.overlay.views"),
    ("OverlayModule", "components/widgets/overlay/modules", "qs.components.widgets.overlay.modules"),
]
POPOUT_DIR = "components/widgets/bar/popouts/content"
POPOUT_IMPORT = "qs.components.widgets.bar.popouts.content"

errors, warnings = [], []


def qml_files():
    files = [ROOT / "shell.qml"]
    for d in QML_DIRS:
        files.extend((ROOT / d).rglob("*.qml"))
    return files


def rel(path):
    return path.relative_to(ROOT).as_posix()


def schema_types(schema, name):
    defs = schema["definitions"]
    types = []
    for option in defs[name]["oneOf"]:
        target = defs.get(option.get("$ref", "").split("/")[-1], option)
        const = target.get("properties", {}).get("type", {}).get("const")
        if const:
            types.append(const)
    return types


def main():
    schema = json.loads(SCHEMA.read_text())
    sources = {rel(f): f.read_text() for f in qml_files()}
    everything = "\n".join(sources.values())
    imports = set(re.findall(r"^import (qs(?:\.\w+)+)", everything, re.M))

    def used_as_type(name, besides):
        """Instantiated or referenced by name anywhere but its own file."""
        pattern = re.compile(r"\b" + re.escape(name) + r"\b")
        return any(pattern.search(text) for path, text in sources.items() if path != besides)

    # Schema types -> files, and the directories' named imports
    for definition, directory, required_import in LOADERS:
        types = schema_types(schema, definition)
        for t in types:
            if not (ROOT / directory / f"{t}.qml").exists():
                errors.append(f"{definition} type '{t}' has no {directory}/{t}.qml")
        if required_import not in imports:
            errors.append(f"nothing imports {required_import}: files loaded by URL from {directory} won't see each other's types")
        for f in sorted((ROOT / directory).glob("*.qml")):
            if f.stem not in types and not used_as_type(f.stem, rel(f)):
                warnings.append(f"{rel(f)}: not a {definition} type and not used anywhere")

    # Popout names -> content files
    names = {}
    for path, text in sources.items():
        for m in re.finditer(r'popoutName:\s*"([^"]+)"', text):
            names.setdefault(m.group(1), path)
    for name, path in sorted(names.items()):
        if not (ROOT / POPOUT_DIR / f"{name}Popout.qml").exists():
            errors.append(f'{path}: popoutName "{name}" has no {POPOUT_DIR}/{name}Popout.qml')
    if POPOUT_IMPORT not in imports:
        errors.append(f"nothing imports {POPOUT_IMPORT}: popout content won't see its sibling types")
    for f in sorted((ROOT / POPOUT_DIR).glob("*Popout.qml")):
        name = f.stem[: -len("Popout")]
        if name not in names and not used_as_type(f.stem, rel(f)):
            warnings.append(f"{rel(f)}: no PopoutAnchor opens it and nothing embeds it")

    # qs.* imports resolve
    for path, text in sources.items():
        for m in re.finditer(r"^import (qs(?:\.\w+)+)", text, re.M):
            target = ROOT.joinpath(*m.group(1).split(".")[1:])
            if not target.is_dir():
                errors.append(f"{path}: import {m.group(1)} — no such directory")

    # Singleton references: FooManager. must be a service, and a near-miss
    # of any project singleton (AudioManger.) is a typo
    external = {"ToplevelManager"}  # Quickshell's own
    singletons = {f.stem for d in ("services", "config", "components/methods") for f in (ROOT / d).glob("*.qml")}
    services = {f.stem for f in (ROOT / "services").glob("*.qml")} | external
    for path, text in sources.items():
        # without strings and comments
        code = re.sub(r'"(?:[^"\\\n]|\\.)*"|`[^`]*`', '""', text)
        code = re.sub(r"//[^\n]*", "", code)
        for name in sorted(set(re.findall(r"(?<![\w.])([A-Z]\w+)\.", code))):
            if name in singletons or name in external:
                continue
            if name.endswith("Manager") and name not in services:
                errors.append(f"{path}: {name} is not a service")
                continue
            close = difflib.get_close_matches(name, singletons, n=1, cutoff=0.85)
            if close:
                errors.append(f"{path}: {name} — did you mean {close[0]}?")

    for e in errors:
        print(f"error    {e}")
    for w in warnings:
        print(f"warning  {w}")
    if not errors and not warnings:
        print("structure ok")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
