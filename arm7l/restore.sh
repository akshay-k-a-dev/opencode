#!/usr/bin/env bash

# Restore original OpenCode source files from backups

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find repository root by walking up until we find packages/opencode or .git
find_repo_root() {
  dir="$SCRIPT_DIR"
  while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
    if [ -d "$dir/packages/opencode" ] || [ -d "$dir/.git" ]; then
      echo "$dir"
      return 0
    fi
    next="$(dirname "$dir")"
    if [ "$next" = "$dir" ]; then break; fi
    dir="$next"
  done
  return 1
}

if OPENCODE_ROOT="$(find_repo_root)"; then
  :
else
  if [ -d "$HOME/opencode" ]; then
    OPENCODE_ROOT="$HOME/opencode"
    echo "Falling back to \$HOME/opencode: $OPENCODE_ROOT"
  else
    echo "❌ Could not locate repository root (searched for packages/opencode or .git)." >&2
    exit 1
  fi
fi

SRC_DIR="$OPENCODE_ROOT/packages/opencode/src"
BACKUP_DIR="$OPENCODE_ROOT/packages/opencode/.backup-arm7l"

echo "Restoring original source files..."

if [ ! -d "$BACKUP_DIR" ]; then
    echo "No backup directory found!"
    exit 1
fi

# Restore each backed up file
find "$BACKUP_DIR" -type f | while read -r backup; do
    filename=$(basename "$backup")
    # Convert _ back to / to get original path
    original="${filename//_//}"
    original="$OPENCODE_ROOT/packages/opencode/$original"
    
    if [ -f "$original" ]; then
        cp "$backup" "$original"
        echo "Restored: $original"
    fi
done

echo ""
echo "Restore complete!"
echo ""
