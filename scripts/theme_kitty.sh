#!/usr/bin/env bash
#
# Quickshell theme -> Kitty colors (templates/kitty_template.conf), then
# reloads every running Kitty instance that allows remote control.
#
# Usage: theme_kitty.sh <input_file.json> [output_file.conf]
#   output defaults to ~/.config/kitty/theme/generated.conf
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/theme_env.sh"

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,6p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
require_cmds jq envsubst kitty

INPUT_FILE="$1"
OUTPUT_FILE="${2:-$HOME/.config/kitty/theme/generated.conf}"
TEMPLATE_FILE="$SCRIPT_DIR/templates/kitty_template.conf"
prepare_output "$TEMPLATE_FILE" "$OUTPUT_FILE"
load_theme "$INPUT_FILE"

export FOREGROUND=$(theme_color foreground "$BASE05")
export BACKGROUND=$(theme_color background "$BASE00")
export BACKGROUND_ALT=$(theme_color backgroundAlt "$BASE01")
export FOREGROUND_INACTIVE=$(theme_color foregroundInactive "$BASE03")
export ACCENT=$(theme_color accent "$BASE0D")
export BORDER=$(theme_color border "$BASE02")
export BORDER_FOCUS=$(theme_color borderFocus "$BASE0D")
export WARNING=$(theme_color warning "$BASE09")

echo "📝 Generating Kitty config from template..."
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
if [ ! -s "$OUTPUT_FILE" ]; then
    echo "Error: Failed to generate config file." >&2
    exit 1
fi
echo "✅ Config written to '$OUTPUT_FILE'"

echo "🚀 Reloading all running Kitty instances..."
RELOADED=false
for SOCKET in /tmp/kitty-*; do
    [ -S "$SOCKET" ] || continue
    echo "   Reloading via socket: $SOCKET"
    if kitty @ --to "unix:$SOCKET" set-colors --all --configured "$OUTPUT_FILE" 2>/dev/null; then
        RELOADED=true
    fi
done
if [ "$RELOADED" = false ]; then
    echo "⚠️  Warning: Could not reload any Kitty instances via remote control." >&2
    echo "   Either none are open, or remote control is off: add 'allow_remote_control yes' to kitty.conf." >&2
else
    echo "✅ Kitty instances reloaded successfully!"
fi
