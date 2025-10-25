#!/usr/bin/env bash
# Dry-run script to move files named like "core_modelViewer.lua" -> "core/modelViewer.lua"
# Also: if a file ends with _VersionN (or _versionN) before .lua, copy it to the same name without that suffix
#       in the same directory (no underscore->slash conversion), then delete the version file
#       so utils_mathUtils_Version2.lua -> overwrite utils_mathUtils.lua
# Usage:
#   ./rename_underscores.sh                 # show what would be moved (dry-run)
#   ./rename_underscores.sh --apply         # perform the moves
#   ./rename_underscores.sh --apply --force # perform moves, overwrite existing targets
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
  OVERWRITE_THIS_MOVE=0
  # Skip files without underscore
  if [[ "$base" != *"_"* ]]; then
    continue
  fi

  name="${base%.*}"
  ext="${base##*.}"

  # If file ends with _VersionN or _versionN, prepare a copy destination without that suffix
  if [[ "$name" =~ ^(.*)_([Vv]ersion[0-9]+)$ ]]; then
    name_nover="${BASH_REMATCH[1]}"
    new_base_nover="${name_nover}.${ext}"
    # Keep in the same directory as the source file (no underscore->slash conversion)
    dest_nover_dir="$(dirname "$src")"
    dest_nover="$dest_nover_dir/$new_base_nover"

    if [ "$DRY_RUN" -eq 1 ]; then
      if [ -d "$dest_nover_dir" ]; then
        printf "Would copy (version->base): %s -> %s (dir exists)\n" "$src" "$dest_nover"
      else
        printf "Would copy (version->base): %s -> %s (would create dir: %s)\n" "$src" "$dest_nover" "$dest_nover_dir"
      fi
      if [ -e "$dest_nover" ]; then
        if [ "$FORCE" -eq 1 ]; then
          printf "  Note: destination exists: %s (would overwrite due to --force)\n" "$dest_nover"
        else
          printf "  Note: destination exists: %s (would overwrite because it's a version copy)\n" "$dest_nover"
        fi
      fi
      printf "Would delete version file after copy: %s\n" "$src"
      # Prepare to move the renamed base file and overwrite destination
      src="$dest_nover"
      base="$(basename "$src")"
      OVERWRITE_THIS_MOVE=1
      printf "Would move (renamed versioned file): %s -> %s\n" "$src" "$dest"
      continue
    else
      # Apply: ensure destination dir exists, then copy (force overwrite)
      if [ ! -d "$dest_nover_dir" ]; then
        mkdir -p "$dest_nover_dir"
        printf "Created dir: %s\n" "$dest_nover_dir"
      fi
      cp -f -- "$src" "$dest_nover"
      printf "Copied version file over base: %s -> %s\n" "$src" "$dest_nover"
      rm -f -- "$src"
      printf "Deleted version file: %s\n" "$src"
      # Prepare to move the renamed base file and overwrite destination
      src="$dest_nover"
      base="$(basename "$src")"
      OVERWRITE_THIS_MOVE=1
    fi
  fi

  # Continue with normal behavior: move file into underscore->slash layout
  # Build destination relative path by replacing underscores with slashes
  new_rel="${base//_//}"
  # Avoid creating an absolute path when filename starts with underscore
  new_rel="${new_rel#/}"

  dest="$TARGET_DIR/$new_rel"
  dest_dir="$(dirname "$dest")"

  # If destination equals source, no move is needed
  if [ "$src" = "$dest" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      printf "No move needed (already at final path): %s\n" "$src"
    fi
    continue
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -d "$dest_dir" ]; then
      printf "Would move: %s -> %s (dir exists)\n" "$src" "$dest"
    else
      printf "Would move: %s -> %s (would create dir: %s)\n" "$src" "$dest" "$dest_dir"
    fi

    if [ -e "$dest" ]; then
      if [ "$OVERWRITE_THIS_MOVE" -eq 1 ]; then
        printf "  Note: destination exists: %s (would overwrite due to versioned rename)\n" "$dest"
      elif [ "$FORCE" -eq 1 ]; then
        printf "  Note: destination exists: %s (would overwrite due to --force)\n" "$dest"
      else
        printf "  Note: destination exists: %s (would skip by default)\n" "$dest"
      fi
    fi
  else
    # Apply mode: ensure destination directory exists
    if [ ! -d "$dest_dir" ]; then
      mkdir -p "$dest_dir"
      printf "Created dir: %s\n" "$dest_dir"
    fi

    # Handle existing destination
    if [ -e "$dest" ]; then
      if [ "$OVERWRITE_THIS_MOVE" -eq 1 ]; then
        rm -f -- "$dest"
        printf "Removed existing destination (versioned overwrite): %s\n" "$dest"
      elif [ "$FORCE" -eq 1 ]; then
        rm -f -- "$dest"
        printf "Removed existing destination (force): %s\n" "$dest"
      else
        printf "Skipping %s -> %s: destination exists (use --force to overwrite)\n" "$src" "$dest" >&2
        continue
      fi
    fi

    mv -v -- "$src" "$dest"
  fi
done
