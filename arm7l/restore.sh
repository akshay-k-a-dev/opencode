#!/usr/bin/env bash

# Restore original OpenCode source files from backups

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
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
