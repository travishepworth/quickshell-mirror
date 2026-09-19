#!/usr/bin/env bash
# Creates/updates the venv used by all python scripts in this repo (cube.py, generate_theme.py).
set -euo pipefail

AXIOM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$AXIOM_DIR/.venv"

python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip --quiet
"$VENV_DIR/bin/pip" install -r "$AXIOM_DIR/scripts/requirements.txt"

echo "venv ready at $VENV_DIR"
