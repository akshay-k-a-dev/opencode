#!/usr/bin/env bash

# Patch OpenCode source files to work without Bun on ARM7L
# This script modifies imports and API calls to use Node.js equivalents

set -e

echo "========================================"
echo "OpenCode ARM7L Source Patcher"
echo "========================================"
echo ""

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

echo "Source directory: $SRC_DIR"
echo ""

# Create backup directory
BACKUP_DIR="$OPENCODE_ROOT/packages/opencode/.backup-arm7l"
mkdir -p "$BACKUP_DIR"

echo "Creating backups in: $BACKUP_DIR"

# Function to patch a file
patch_file() {
    local file="$1"
    local backup="$BACKUP_DIR/$(echo "$file" | sed 's|/|_|g')"
    
    # Create backup if not exists
    if [ ! -f "$backup" ]; then
        cp "$file" "$backup"
    fi
    
    echo "Patching: $file"
    
    # Replace bun:test imports
    sed -i 's/from "bun:test"/from "..\/.shims\/bun-test-shim"/g' "$file"
    sed -i "s/from 'bun:test'/from '..\/.shims\/bun-test-shim'/g" "$file"
    
    # Replace bun:* imports with shim
    sed -i 's/from "bun:\([^"]*\)"/from "..\/.shims\/bun-shim"/g' "$file"
    sed -i "s/from 'bun:\([^']*\)'/from '..\/.shims\/bun-shim'/g" "$file"
    
    # Add Bun shim import at top of files that use Bun global
    if grep -q "Bun\." "$file" 2>/dev/null && ! grep -q "import.*bun-shim" "$file"; then
        # Check if it's a TypeScript file
        if [[ "$file" == *.ts ]]; then
            # Add import after any existing imports or at top
            sed -i '1s/^/import "..\/.shims\/bun-shim"\n/' "$file"
        fi
    fi
}

# Find all TypeScript files
find "$SRC_DIR" -name "*.ts" -type f | while read -r file; do
    # Skip node_modules and dist
    if [[ "$file" == *"node_modules"* ]] || [[ "$file" == *"dist"* ]]; then
        continue
    fi
    
    # Check if file uses Bun APIs
    if grep -l "Bun\.\|from \"bun:\|from 'bun:" "$file" > /dev/null 2>&1; then
        patch_file "$file"
    fi
done

echo ""
echo "========================================"
echo "Patching complete!"
echo "========================================"
echo ""
echo "Backups stored in: $BACKUP_DIR"
echo ""
echo "To restore original files:"
echo "  ./restore.sh"
echo ""
