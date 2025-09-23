#!/usr/bin/env bash

# --- Configuration ---
# The directory to start searching from. "." means the current directory.
SEARCH_DIR="."

# The file pattern to search for. We are looking for QML files.
FILE_PATTERN="*.qml"

# The old and new import paths.
# We will replace OLD_PATH with NEW_PATH at the beginning of an import string.
OLD_PATH="qs.components.stolen.common"
NEW_PATH="qs.components.stolen.end4.common"
# ---------------------

# This is a safety measure. It escapes the dots in the OLD_PATH so that
# sed treats them as literal characters, not as "any character" wildcards.
ESCAPED_OLD_PATH=$(echo "$OLD_PATH" | sed 's/\./\\./g')

echo "This script will recursively find all '$FILE_PATTERN' files in '$SEARCH_DIR' and"
echo "replace import paths starting with:"
echo "  FROM: $OLD_PATH"
echo "  TO:   $NEW_PATH"
echo ""

# Use `grep` to find all files that will be affected and list them for the user.
# -r: recursive
# -l: list filenames only
# --include: only search in files matching this pattern
echo "The following files will be modified:"
FILES_TO_CHANGE=$(grep -r -l --include="$FILE_PATTERN" "$OLD_PATH" "$SEARCH_DIR")

if [ -z "$FILES_TO_CHANGE" ]; then
  echo "No files found containing the old import path. Exiting."
  exit 0
fi

echo "$FILES_TO_CHANGE"
echo ""

# Ask for user confirmation before making any changes.
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo "" # move to a new line

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

echo "Proceeding with replacement..."

# Use `find` to locate the files and `sed` to perform the replacement in-place.
# -type f: find only files
# -name: filter by the file pattern
# -exec: execute a command on the found files
#   sed -i: edit the files in-place
#   "s/.../.../g": the substitution command (s), with global flag (g)
#   {}: placeholder for the filename find found
#   +: groups multiple filenames into a single command for efficiency
find "$SEARCH_DIR" -type f -name "$FILE_PATTERN" -exec sed -i "s/$ESCAPED_OLD_PATH/$NEW_PATH/g" {} +

echo "Replacement complete."
