# Shared by the theme_*.sh integrations (sourced, not run): dependency
# checks, argument handling and one jq pass over a Quickshell theme file.
#
#   source "$SCRIPT_DIR/lib/theme_env.sh"
#   require_cmds jq envsubst
#   load_theme "$INPUT_FILE"        # THEME_*, BASE00..BASE0F, THEME_SEMANTIC
#   theme_color accent "$BASE0D"    # a semantic color as hex, else the fallback

# Every missing command is an error
require_cmds() {
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: '$cmd' is not installed." >&2
            exit 1
        fi
    done
}

# Output path's directory exists; template is present
prepare_output() {
    local template="$1" output="$2"
    if [ ! -f "$template" ]; then
        echo "Error: Template file not found at '$template'" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$output")"
}

declare -gA THEME_SEMANTIC=()

# Exports THEME_NAME/THEME_AUTHOR/THEME_VARIANT and BASE00..BASE0F (hex, as
# in the theme), and fills THEME_SEMANTIC[key] with each semantic color
# resolved through the palette
load_theme() {
    local file="$1" key value
    if [ ! -f "$file" ]; then
        echo "Error: Input file not found at '$file'" >&2
        exit 1
    fi
    echo "🎨 Reading theme from '$file'..."
    local entries
    entries=$(jq -r '
        . as $theme
        | (["NAME", (.name // "Unknown")], ["AUTHOR", (.author // "N/A")], ["VARIANT", (.variant // "unknown")] | "meta\t\(.[0])\t\(.[1])"),
          ((.colors // {}) | to_entries[] | "base\t\(.key | ascii_upcase)\t\(.value)"),
          ((.semantic // {}) | to_entries[] | "sem\t\(.key)\t\($theme.colors[.value] // .value)")
    ' "$file")
    while IFS=$'\t' read -r kind key value; do
        case "$kind" in
            meta) export "THEME_$key=$value" ;;
            base) export "$key=$value" ;;
            sem) THEME_SEMANTIC["$key"]="$value" ;;
        esac
    done <<< "$entries"
}

# theme_color KEY [FALLBACK]
theme_color() {
    local value="${THEME_SEMANTIC[$1]:-}"
    echo "${value:-${2:-}}"
}

# "#rrggbb" in quotes, for YAML/INI values ('""' when empty)
quote_color() {
    local color="${1#\#}"
    if [ -z "$color" ] || [ "$color" == "null" ]; then
        echo '""'
    else
        echo "\"#${color}\""
    fi
}
