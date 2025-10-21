#!/usr/bin/env python3
import argparse
import os
import shutil
import sys

def process_file(path: str, dry_run: bool = False, verbose: bool = True):
    if not os.path.isfile(path):
        if verbose:
            print(f"Skip (not a file): {path}")
        return

    parent = os.path.dirname(os.path.abspath(path))
    base = os.path.basename(path)
    name, ext = os.path.splitext(base)

    parts = [p for p in name.split('_') if p]
    if len(parts) < 2:
        if verbose:
            print(f"Skip (needs at least 2 underscore parts): {base}")
        return

    first = parts[0]
    second = parts[1]
    # Per spec: new filename is the last two elements joined by underscore if available,
    # otherwise the last element.
    new_name_parts = parts[-2:] if len(parts) >= 2 else parts[-1:]
    new_name = "_".join(new_name_parts) + ext

    dest_dir = os.path.join(parent, first, second)
    dest_path = os.path.join(dest_dir, new_name)

    if not os.path.isdir(dest_dir):
        if verbose:
            print(f"Create dir: {dest_dir}")
        if not dry_run:
            os.makedirs(dest_dir, exist_ok=True)
    else:
        if verbose:
            print(f"Dir exists: {dest_dir}")

    if os.path.exists(dest_path):
        if verbose:
            print(f"Skip (target exists): {dest_path}")
        return

    if verbose:
        print(f"Copy: {path} -> {dest_path}")
    if not dry_run:
        shutil.copy2(path, dest_path)

def main(argv):
    parser = argparse.ArgumentParser(
        description="Copy files into subfolders based on underscore-separated names.\n"
                    "Example: dialog_utils_outline_logic.lua -> dialog/utils/outline_logic.lua"
    )
    parser.add_argument("files", nargs="+", help="Files to process (use shell globs)")
    parser.add_argument("--dry-run", action="store_true", help="Only print actions")
    parser.add_argument("-q", "--quiet", action="store_true", help="Reduce output")
    args = parser.parse_args(argv)

    verbose = not args.quiet
    for f in args.files:
        process_file(f, dry_run=args.dry_run, verbose=verbose)

if __name__ == "__main__":
    main(sys.argv[1:])