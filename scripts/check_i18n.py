#!/usr/bin/env python3
"""Check the translation dictionaries in config/i18n against the source.

Keys come from:
  - every string literal passed to I18n.tr("...") in the QML, and
  - the config schema's titles, descriptions and string enum values (the
    settings UI translates those itself, so they need no code).

  scripts/check_i18n.py                 missing / unused entries per language
  scripts/check_i18n.py --fill          also add missing keys (empty) to each file
  scripts/check_i18n.py --untranslated  UI-looking string literals not wrapped in I18n.tr()

An empty or missing entry falls back to English at runtime, so a partly
translated file is always safe to ship.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
I18N = ROOT / "config" / "i18n"
SCHEMA = ROOT / "config" / "json" / "config.schema.json"
QML_DIRS = ["components", "modules", "services", "config"]
SKIP = []

# "..." with escapes, as the first argument of I18n.tr(
TR_CALL = re.compile(r'I18n\.tr\(\s*"((?:[^"\\]|\\.)*)"')
# Property assignments that are UI text, for --untranslated
UI_PROP = re.compile(r'\b(text|title|label|placeholderText|tooltipText|description|subtitle):\s*("(?:[^"\\]|\\.)*"|`[^`]*`)')


def qml_files():
    for d in QML_DIRS:
        for f in (ROOT / d).rglob("*.qml"):
            rel = f.relative_to(ROOT).as_posix()
            if not any(rel.startswith(s) for s in SKIP):
                yield f, rel


def unescape(s):
    return json.loads(f'"{s}"')


def schema_strings(node, out):
    if isinstance(node, dict):
        for key in ("title", "description"):
            if isinstance(node.get(key), str):
                out.add(node[key])
        if node.get("type") == "string" and isinstance(node.get("enum"), list):
            out.update(v for v in node["enum"] if isinstance(v, str))
        for value in node.values():
            schema_strings(value, out)
    elif isinstance(node, list):
        for value in node:
            schema_strings(value, out)


def collect_keys():
    keys = {}
    for f, rel in qml_files():
        for line_no, line in enumerate(f.read_text().splitlines(), 1):
            for m in TR_CALL.finditer(line):
                keys.setdefault(unescape(m.group(1)), f"{rel}:{line_no}")
    schema = set()
    schema_strings(json.loads(SCHEMA.read_text())["properties"], schema)
    schema_strings(json.loads(SCHEMA.read_text())["definitions"], schema)
    for s in schema:
        keys.setdefault(s, "schema")
    return keys


def untranslated():
    for f, rel in qml_files():
        for line_no, line in enumerate(f.read_text().splitlines(), 1):
            if "I18n.tr(" in line or line.strip().startswith("//"):
                continue
            for m in UI_PROP.finditer(line):
                literal = m.group(2)[1:-1]
                # Words, not glyphs/format strings/ids
                if re.search(r"[A-Za-z]{2,}", re.sub(r"\$\{[^}]*\}", "", literal)):
                    yield f"{rel}:{line_no}: {m.group(1)}: {m.group(2)}"


def main():
    if "--untranslated" in sys.argv:
        found = list(untranslated())
        print("\n".join(found) or "no untranslated UI literals found")
        return 1 if found else 0

    keys = collect_keys()
    status = 0
    for path in sorted(I18N.glob("*.json")):
        data = json.loads(path.read_text())
        strings = data.setdefault("strings", {})
        missing = [k for k in keys if not strings.get(k)]
        unused = [k for k in strings if k not in keys]
        print(f"{path.name}: {len(keys) - len(missing)}/{len(keys)} translated, {len(missing)} missing, {len(unused)} unused")
        for k in missing[:40]:
            print(f"  missing  {keys[k]}: {k!r}")
        if len(missing) > 40:
            print(f"  ... and {len(missing) - 40} more")
        for k in unused:
            print(f"  unused   {k!r}")
        if "--fill" in sys.argv:
            for k in missing:
                strings.setdefault(k, "")
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        status |= 1 if missing else 0
    return status


if __name__ == "__main__":
    sys.exit(main())
