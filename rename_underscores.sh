#!/usr/bin/env bash
# Dry-run script to copy files named like "core_modelViewer.lua" -> "core/modelViewer.lua"
# Also: if a file ends with _VersionN (or _versionN) before .lua, copy its content to the same name without that suffix
#       to the underscore-implied path (overwriting), then delete the version file.
#       Example: utils_mathUtils_Version2.lua -> copy to utils/mathUtils.lua and delete utils_mathUtils_Version2.lua
# Usage:
#   ./rename_underscores.sh                 # show what would be copied (dry-run)
#   ./rename_underscores.sh --apply         # perform the copies
#   ./rename_underscores.sh --apply --force # kept for compatibility; copies always overwrite anyway
#   ./rename_underscores.sh --apply /path/to/dir

set -euo pipefail

DRY_RUN=1
FORCE=0
TARGET_DIR="."
FILE_PATTERN="*.lua"   # default: only process .lua files

print_usage() {
  cat <<EOF
Usage: $0 [--apply] [--force] [--all] [target_dir]
  --apply     Perform the moves (default is dry-run)
  --force     Overwrite existing destination files when applying
  --all       Process all files (not only .lua). By default only *.lua are handled.
  target_dir  Directory containing files with underscores (default: current dir)
EOF
}

# Simple argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) DRY_RUN=0; shift ;;
    --force) FORCE=1; shift ;;
    --all) FILE_PATTERN="*"; shift ;;          # new: allow processing all files
    --help) print_usage; exit 0 ;;
    --*) printf "Unknown option: %s\n" "$1" >&2; print_usage; exit 2 ;;
    *) TARGET_DIR="$1"; shift ;;
  esac
done

# Ensure target dir exists
if [ ! -d "$TARGET_DIR" ]; then
  printf "Error: target directory does not exist: %s\n" "$TARGET_DIR" >&2
  exit 2
fi

# Process only regular files matching FILE_PATTERN in the target directory root
find "$TARGET_DIR" -maxdepth 1 -type f -name "$FILE_PATTERN" -print0 | while IFS= read -r -d '' src; do
  base="$(basename "$src")"
  # Skip files without underscore
  if [[ "$base" != *"_"* ]]; then
    continue
  fi

  name="${base%.*}"
  ext="${base##*.}"

  # Versioned file: copy to plain-name underscore->slash path, then delete the version file
  if [[ "$name" =~ ^(.*)_([Vv]ersion[0-9]+)$ ]]; then
    name_nover="${BASH_REMATCH[1]}"
    new_base_nover="${name_nover}.${ext}"
    dest_rel="${new_base_nover//_//}"
    dest_rel="${dest_rel#/}"
    dest="$TARGET_DIR/$dest_rel"
    dest_dir="$(dirname "$dest")"

    if [ "$DRY_RUN" -eq 1 ]; then
      if [ -d "$dest_dir" ]; then
        printf "Would copy (version->plain): %s -> %s (dir exists)\n" "$src" "$dest"
      else
        printf "Would copy (version->plain): %s -> %s (would create dir: %s)\n" "$src" "$dest" "$dest_dir"
      fi
      if [ -e "$dest" ]; then
        printf "  Would overwrite existing: %s\n" "$dest"
      fi
      printf "Would delete version file: %s\n" "$src"
      continue
    fi

    if [ ! -d "$dest_dir" ]; then
      mkdir -p "$dest_dir"
      printf "Created dir: %s\n" "$dest_dir"
    fi
    cp -f -- "$src" "$dest"
    printf "Copied (version->plain): %s -> %s\n" "$src" "$dest"
    rm -f -- "$src"
    printf "Deleted version file: %s\n" "$src"
    continue
  fi

  # Non-versioned underscored file: copy to underscore->slash path (overwrite), keep original
  dest_rel="${base//_//}"
  dest_rel="${dest_rel#/}"
  dest="$TARGET_DIR/$dest_rel"
  dest_dir="$(dirname "$dest")"

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -d "$dest_dir" ]; then
      printf "Would copy: %s -> %s (dir exists)\n" "$src" "$dest"
    else
      printf "Would copy: %s -> %s (would create dir: %s)\n" "$src" "$dest" "$dest_dir"
    fi
    if [ -e "$dest" ]; then
      printf "  Would overwrite existing: %s\n" "$dest"
    fi
    continue
  fi

  if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir"
    printf "Created dir: %s\n" "$dest_dir"
  fi
  cp -f -- "$src" "$dest"
  printf "Copied: %s -> %s\n" "$src" "$dest"
done
