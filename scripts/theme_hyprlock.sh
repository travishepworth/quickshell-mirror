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
usage_or_help 3 6 "$@"
if [[ $# -lt 7 ]]; then
    sed -n '6p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
require_cmds jq envsubst

load_theme "$1"
export_theme_colors
# hyprlock colors: rgb(rrggbb), no '#'
map_vars hex $(theme_color_vars)
export FONT="$3"
export WALLPAPER="${4#file://}"
export BLUR_PASSES=$([[ "$5" == "1" ]] && echo 3 || echo 0)
export GREETING="$6"
export PLACEHOLDER="$7"

# Only our variables: the template also uses hyprlock's own ($TIME)
render_template "$SCRIPT_DIR/templates/hyprlock_template.conf" "$2" \
    '$THEME_NAME $BACKGROUND $BACKGROUND_ALT $FOREGROUND $ACCENT $ACCENT_ALT $ERROR $FONT $WALLPAPER $BLUR_PASSES $GREETING $PLACEHOLDER'
