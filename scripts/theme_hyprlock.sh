#!/usr/bin/env bash
#
# Quickshell theme -> hyprlock config (templates/hyprlock_template.conf), for
# axiom's "hyprlock" lockscreen mode. Never touches ~/.config/hypr/hyprlock.conf.
#
# Usage: theme_hyprlock.sh <theme.json> <output.conf> <font> <wallpaper> <blur 0|1> <greeting> <placeholder>
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/theme_env.sh"

if [[ $# -lt 7 || "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,6p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
require_cmds jq envsubst

INPUT_FILE="$1"
OUTPUT_FILE="$2"
TEMPLATE_FILE="$SCRIPT_DIR/templates/hyprlock_template.conf"
prepare_output "$TEMPLATE_FILE" "$OUTPUT_FILE"
load_theme "$INPUT_FILE"

# hyprlock colors: rgb(rrggbb), no '#'
hex() { echo "${1#\#}"; }
export BACKGROUND=$(hex "$(theme_color background "$BASE00")")
export BACKGROUND_ALT=$(hex "$(theme_color backgroundAlt "$BASE01")")
export FOREGROUND=$(hex "$(theme_color foreground "$BASE05")")
export ACCENT=$(hex "$(theme_color accent "$BASE0D")")
export ACCENT_ALT=$(hex "$(theme_color accentAlt "$BASE0E")")
export ERROR=$(hex "$(theme_color error "$BASE08")")
export FONT="$3"
export WALLPAPER="${4#file://}"
export BLUR_PASSES=$([[ "$5" == "1" ]] && echo 3 || echo 0)
export GREETING="$6"
export PLACEHOLDER="$7"

# Only our variables: the template also uses hyprlock's own ($TIME)
envsubst '$THEME_NAME $BACKGROUND $BACKGROUND_ALT $FOREGROUND $ACCENT $ACCENT_ALT $ERROR $FONT $WALLPAPER $BLUR_PASSES $GREETING $PLACEHOLDER' < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
if [ ! -s "$OUTPUT_FILE" ]; then
    echo "Error: Failed to generate hyprlock config." >&2
    exit 1
fi
echo "✅ hyprlock config written to '$OUTPUT_FILE'"
