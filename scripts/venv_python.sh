#!/usr/bin/env bash
# Runs python in the repo's venv, creating or updating it first when needed:
#   venv_python.sh SCRIPT [ARGS...]
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPTS_DIR/setup_venv.sh"
exec "$SCRIPTS_DIR/../.venv/bin/python3" "$@"
