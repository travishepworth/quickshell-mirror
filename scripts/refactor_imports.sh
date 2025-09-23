#!/usr/bin/env bash

# --- Default Configuration ---
DEFAULT_OLD_PATH="qs.modules.common"
DEFAULT_NEW_PATH="qs.components.stolen.common"

# --- Script Configuration ---
SEARCH_DIR="."
FILE_PATTERN="*.qml"

# --- Function to display usage information ---
usage() {
  echo "Usage: $0 [-i|--input <old_path>] [-o|--output <new_path>]"
  echo
  echo "Recursively finds and replaces import paths in QML files."
  echo
  echo "Options:"
  echo "  -i, --input   The import path to search for (e.g., 'qs.modules.common')."
  echo "  -o, --output  The new import path to replace it with (e.g., 'qs.components.stolen.common')."
  echo "  -h, --help    Display this help message."
  echo
  echo "If no options are provided, the script uses the hardcoded default paths:"
  echo "  Default Input:  $DEFAULT_OLD_PATH"
  echo "  Default Output: $DEFAULT_NEW_PATH"
  echo
  echo "NOTE: --input and --output must be used together."
  exit 1
}

# --- Initialize variables ---
INPUT_PATH=""
OUTPUT_PATH=""

# --- Parse Command-Line Arguments ---
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -i|--input)
      INPUT_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--output)
      OUTPUT_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      usage
      ;;
    *)    # unknown option
      echo "Error: Unknown option '$1'"
      usage
      ;;
  esac
done

# --- Validate Arguments and Set Final Paths ---
# Condition 1: Both arguments were provided. Use them.
if [[ -n "$INPUT_PATH" && -n "$OUTPUT_PATH" ]]; then
  OLD_PATH="$INPUT_PATH"
  NEW_PATH="$OUTPUT_PATH"
# Condition 2: Neither argument was provided. Use defaults.
elif [[ -z "$INPUT_PATH" && -z "$OUTPUT_PATH" ]]; then
  OLD_PATH="$DEFAULT_OLD_PATH"
  NEW_PATH="$DEFAULT_NEW_PATH"
# Condition 3: Only one of the two was provided. This is an error.
else
  echo "Error: You must provide both --input and --output arguments together."
  usage
fi

# --- Main Script Logic (unchanged from before) ---

# Escape dots for use in sed regex
ESCAPED_OLD_PATH=$(echo "$OLD_PATH" | sed 's/\./\\./g')

echo "This script will recursively find all '$FILE_PATTERN' files in '$SEARCH_DIR' and"
echo "replace import paths starting with:"
echo "  FROM: $OLD_PATH"
echo "  TO:   $NEW_PATH"
echo ""

# Find all files that will be affected
FILES_TO_CHANGE=$(grep -r -l --include="$FILE_PATTERN" "$OLD_PATH" "$SEARCH_DIR")

if [ -z "$FILES_TO_CHANGE" ]; then
  echo "No files found containing the old import path. Exiting."
  exit 0
fi

echo "The following files will be modified:"
echo "$FILES_TO_CHANGE"
echo ""

# Ask for user confirmation
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo "" # move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

echo "Proceeding with replacement..."

find "$SEARCH_DIR" -type f -name "$FILE_PATTERN" -exec sed -i "s/$ESCAPED_OLD_PATH/$NEW_PATH/g" {} +

echo "Replacement complete."
