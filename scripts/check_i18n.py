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
# Property assignments that are UI text, for --untranslated: the whole
# value expression, so literals in ternaries and concatenations are seen
UI_PROP = re.compile(r'\b(text|title|label|placeholderText|tooltipText|description|subtitle|status):\s*(.+)$')
# Object-literal UI fields ("label": "Text", name: "Text" in option lists)
UI_FIELD = re.compile(r'"?(label|title|text|description|tooltip)"?\s*:\s*"((?:[^"\\]|\\.)*)"')
STRING = re.compile(r'"((?:[^"\\]|\\.)*)"|`([^`]*)`')
# tr() whose first argument isn't a string literal
DYNAMIC_TR = re.compile(r'I18n\.tr\(\s*(?!["\)])')
# tr() calls (literal first argument), stripped before looking for literals
TR_LITERAL = re.compile(r'I18n\.tr\(\s*"(?:[^"\\]|\\.)*"')
# A literal compared against, or used as a key, isn't shown
COMPARED = re.compile(r'(===|!==|==|!=|case)\s*$')


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


def is_words(literal):
    """Words, not glyphs, format strings, ids, paths or colors."""
    literal = re.sub(r"\$\{[^}]*\}", "", literal)
    if literal.startswith(("#", "qrc:", "file:", "/", "image://")) or "." in literal.split(" ")[0] and " " not in literal:
        return False
    return bool(re.search(r"[A-Za-z]{2,}", literal))


def shown_literals(expr):
    """String literals in a value expression that would reach the screen."""
    expr = TR_LITERAL.sub("I18n.tr(_", expr)
    for m in STRING.finditer(expr):
        literal = m.group(1) if m.group(1) is not None else m.group(2)
        before, after = expr[:m.start()], expr[m.end():]
        if COMPARED.search(before) or re.match(r"\s*(===|!==|==|!=|\]|:)", after) or before.rstrip().endswith("["):
            continue
        if m.group(2) is not None:
            # a template: its text parts, around the ${...} expressions
            literal = re.sub(r"\$\{[^}]*\}", " ", literal)
        if is_words(literal):
            yield literal


def untranslated():
    for f, rel in qml_files():
        lines = f.read_text().splitlines()
        for line_no, line in enumerate(lines, 1):
            code = line.split("//")[0] if "://" not in line else line
            if not code.strip() or "console." in code:
                continue
            m = UI_PROP.search(code)
            if m:
                for literal in shown_literals(m.group(2)):
                    yield f"{rel}:{line_no}: {m.group(1)}: {literal!r}"
            for field in UI_FIELD.finditer(code):
                if not (m and field.start() >= m.start(2)) and is_words(field.group(2)):
                    yield f"{rel}:{line_no}: {field.group(1)}: {field.group(2)!r}"
            if DYNAMIC_TR.search(code):
                # Keys chosen at runtime must be declared in a nearby comment
                context = "\n".join(lines[max(0, line_no - 6):line_no])
                if not re.search(r'//.*I18n\.tr\("', context):
                    yield f"{rel}:{line_no}: dynamic tr() without declared keys: {code.strip()[:90]}"


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
