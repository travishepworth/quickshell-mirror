#!/usr/bin/env bash
#
# Quickshell theme -> Neovim palette file (read by ~/.config/nvim/lua/axiom_theme.lua),
# then reloads every running Neovim instance over its RPC socket.
#
# Usage: theme_nvim.sh <input_file.json> [output_file.json]
#   output defaults to $XDG_STATE_HOME/axiom/nvim-theme.json
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/theme_env.sh"

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
require_cmds jq nvim

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${XDG_STATE_HOME:-$HOME/.local/state}/axiom/nvim-theme.json}"
load_theme "$INPUT_FILE"
mkdir -p "$(dirname "$OUTPUT_FILE")"

# The file stem picks a native colorscheme on the nvim side; the palette is
# the mini.base16 fallback for themes it doesn't map
STEM="$(basename "$INPUT_FILE" .json)"
echo "📝 Writing Neovim palette..."
TMP_FILE="$(mktemp "$OUTPUT_FILE.XXXXXX")"
jq --arg stem "$STEM" --arg variant "$THEME_VARIANT" '{
    stem: $stem,
    name: (.name // $stem),
    variant: (if $variant == "light" then "light" else "dark" end),
    colors: (.colors // {})
}' "$INPUT_FILE" > "$TMP_FILE"
mv "$TMP_FILE" "$OUTPUT_FILE"
echo "✅ Palette written to '$OUTPUT_FILE'"

echo "🚀 Reloading all running Neovim instances..."
RELOADED=0
for SOCKET in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*.0; do
    [ -S "$SOCKET" ] || continue
    # "true" only from an nvim that has the module and reloaded without error
    RESULT=$(timeout 2 nvim --server "$SOCKET" --remote-expr \
        'luaeval("select(1, pcall(function() require(\"axiom_theme\").reload() end))")' 2>/dev/null || true)
    if [[ "$RESULT" == "true" || "$RESULT" == "v:true" ]]; then
        RELOADED=$((RELOADED + 1))
    fi
done
if [ "$RELOADED" -eq 0 ]; then
    echo "⚠️  No running Neovim instance was reloaded (none open, or axiom_theme isn't in their config)." >&2
else
    echo "✅ Reloaded $RELOADED Neovim instance(s)."
fi
