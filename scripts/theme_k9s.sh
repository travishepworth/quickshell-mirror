#!/usr/bin/env bash
#
# Quickshell theme -> K9s skin (templates/k9s_template.yaml).
#
# Usage: theme_k9s.sh <input_file.json> [output_file.yaml]
#   output defaults to ~/.config/k9s/skins/wal-generated.yaml
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/theme_env.sh"

if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,6p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi
require_cmds jq envsubst

INPUT_FILE="$1"
OUTPUT_FILE="${2:-$HOME/.config/k9s/skins/wal-generated.yaml}"
TEMPLATE_FILE="$SCRIPT_DIR/templates/k9s_template.yaml"
prepare_output "$TEMPLATE_FILE" "$OUTPUT_FILE"
load_theme "$INPUT_FILE"

# Semantic colors first (fallbacks read the raw palette), then quote all
export FOREGROUND=$(quote_color "$(theme_color foreground "$BASE05")")
export BACKGROUND=$(quote_color "$(theme_color background "$BASE00")")
export BACKGROUND_ALT=$(quote_color "$(theme_color backgroundAlt "$BASE01")")
export BACKGROUND_ALT2=$(quote_color "$(theme_color backgroundHighlight "$BASE03")")
export FOREGROUND_INACTIVE=$(quote_color "$(theme_color foregroundInactive "$BASE04")")
export ACCENT=$(quote_color "$(theme_color accent "$BASE0D")")
export ACCENT_SECONDARY=$(quote_color "$(theme_color accentAlt "$BASE0E")")
export BORDER=$(quote_color "$(theme_color border "$BASE02")")
export BORDER_FOCUS=$(quote_color "$(theme_color borderFocus "$BASE0D")")
export WARNING=$(quote_color "$(theme_color warning "$BASE0A")")
export ERROR=$(quote_color "$(theme_color error "$BASE08")")
export SUCCESS=$(quote_color "$(theme_color success "$BASE0B")")
for base in BASE00 BASE01 BASE02 BASE03 BASE04 BASE05 BASE06 BASE07 BASE08 BASE09 BASE0A BASE0B BASE0C BASE0D BASE0E BASE0F; do
    export "$base=$(quote_color "${!base:-}")"
done

echo "📝 Generating K9s skin from template..."
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
if [ ! -s "$OUTPUT_FILE" ]; then
    echo "Error: Failed to generate skin file." >&2
    exit 1
fi
echo "✅ K9s skin successfully generated at '$OUTPUT_FILE'!"
