#!/usr/bin/env bash
#
# Quickshell theme -> Cava colors (templates/cava_template.conf); creates a
# main Cava config including them if there is none.
#
# Usage: theme_cava.sh <input_file.json> [output_file.conf]
#   output defaults to ~/.config/cava/colors/wal-generated.conf
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/theme_env.sh"

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
require_cmds jq envsubst

INPUT_FILE="$1"
OUTPUT_FILE="${2:-$HOME/.config/cava/colors/wal-generated.conf}"
TEMPLATE_FILE="$SCRIPT_DIR/templates/cava_template.conf"
prepare_output "$TEMPLATE_FILE" "$OUTPUT_FILE"
load_theme "$INPUT_FILE"

# Semantic colors first (fallbacks read the raw palette), then quote all
export FOREGROUND=$(quote_color "$(theme_color foreground "$BASE05")")
export BACKGROUND=$(quote_color "$(theme_color background "$BASE00")")
export ACCENT=$(quote_color "$(theme_color accent "$BASE0D")")
export ACCENT_SECONDARY=$(quote_color "$(theme_color accentAlt "$BASE0E")")
if [[ "$THEME_VARIANT" == "dark" ]]; then
    export GRADIENT_COUNT=8
    export GRADIENT_7=$(quote_color "$BASE08")
    export GRADIENT_8="$ACCENT_SECONDARY"
else
    export GRADIENT_COUNT=6
    export GRADIENT_7=""
    export GRADIENT_8=""
fi
for base in BASE00 BASE01 BASE02 BASE03 BASE04 BASE05 BASE06 BASE07 BASE08 BASE09 BASE0A BASE0B BASE0C BASE0D BASE0E BASE0F; do
    export "$base=$(quote_color "${!base:-}")"
done

echo "📝 Generating Cava config from template..."
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"

if [ ! -s "$OUTPUT_FILE" ]; then
    echo "Error: Failed to generate config file." >&2
    exit 1
fi

# Create main config if it doesn't exist
MAIN_CONFIG="$HOME/.config/cava/config"
if [ ! -f "$MAIN_CONFIG" ]; then
    echo "📄 Creating main Cava config file..."
    cat > "$MAIN_CONFIG" <<EOF
# Main Cava Configuration
# Include the generated color theme
include = $OUTPUT_FILE

[general]
framerate = 60
autosens = 1
sensitivity = 100
bars = 0
bar_width = 2
bar_spacing = 1

[input]
method = pulse
source = auto

[output]
method = ncurses
channels = stereo
mono_option = average
EOF
    echo "   Main config created at '$MAIN_CONFIG'"
else
    echo "ℹ️  Main config already exists at '$MAIN_CONFIG'"
    echo "   To use the generated theme, add this line to your config:"
    echo "   include = $OUTPUT_FILE"
fi

echo "✅ Cava color configuration successfully generated at '$OUTPUT_FILE'!"
