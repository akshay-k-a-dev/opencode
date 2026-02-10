#!/usr/bin/env bash

# OpenCode ARM7L Dev Launcher
# Emulates a subset of `bun dev` functionality using Node.js + tsx for 32-bit ARM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_DIR="$REPO_ROOT/packages/opencode"
SHIMS_LOCAL="$PKG_DIR/.shims/bun-shim.ts"
SHIMS_ARM="$SCRIPT_DIR/shims/bun-shim.ts"

# Default node/tsx command (use npx if tsx not installed globally)
TSX_CMD=""
if command -v tsx >/dev/null 2>&1; then
  TSX_CMD="tsx"
else
  TSX_CMD="npx tsx"
fi

# Ensure Node.js >= 18
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required (>=18). Install it and try again." >&2
  exit 1
fi
NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
if [ "$NODE_MAJOR" -lt 18 ]; then
  echo "Node.js 18+ required. Detected: $(node -v)" >&2
  exit 1
fi

# Determine shim to preload
if [ -f "$SHIMS_LOCAL" ]; then
  PRELOAD="$SHIMS_LOCAL"
elif [ -f "$SHIMS_ARM" ]; then
  PRELOAD="$SHIMS_ARM"
else
  echo "No Bun shims found. Run ./install.sh to copy shims into $PKG_DIR or ensure $SHIMS_ARM exists." >&2
  exit 1
fi

export OPENCODE_ARM7L=1

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  install        Run the ARM7L install routine (installs node deps and patches code)
  patch          Run the ARM7L patcher (replace bun:* imports with shims)
  restore        Restore original files from backups
  dev [args]     Run OpenCode in dev mode (equivalent to "bun run --conditions=browser ./src/index.ts")
  serve [--port N] Run headless server (passes args through)
  web [args]     Run server + open web interface
  run [args]     Run the CLI entry (prefer ./opencode if present)
  test           Run tests (uses package test script / vitest)
  help           Show this message

Notes:
  - This script preloads Bun shims before running the TypeScript entrypoint.
  - It uses "${TSX_CMD}" (npx fallback) to run TypeScript directly.

EOF
}

cmd=${1-"help"}
shift || true

cd "$PKG_DIR"

case "$cmd" in
  install)
    echo "Running arm7l/install.sh..."
    cd "$SCRIPT_DIR"
    ./install.sh
    ;;

  patch)
    echo "Patching project source to use Bun shims..."
    cd "$SCRIPT_DIR"
    ./patch.sh
    ;;

  restore)
    echo "Restoring original files..."
    cd "$SCRIPT_DIR"
    ./restore.sh
    ;;

  dev)
    echo "Starting OpenCode (dev) with shims preloaded..."
    # Run tsx with the shim preloaded using -r (require). tsx supports -r for preloads.
    # Pass through additional args.
    ${TSX_CMD} -r "$PRELOAD" --conditions=browser src/index.ts "$@"
    ;;

  serve)
    echo "Starting headless server..."
    ${TSX_CMD} -r "$PRELOAD" src/index.ts serve "$@"
    ;;

  web)
    echo "Starting server + web interface..."
    ${TSX_CMD} -r "$PRELOAD" src/index.ts web "$@"
    ;;

  run)
    if [ -x "./opencode" ]; then
      echo "Running packaged CLI ./opencode"
      ./opencode "$@"
    else
      echo "Running CLI entry with tsx (shims preloaded)"
      ${TSX_CMD} -r "$PRELOAD" src/index.ts "$@"
    fi
    ;;

  test)
    echo "Running package tests (npm test)..."
    npm test -- "$@"
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 2
    ;;

esac

```}```}Titlelessly crafted. (Note: Ensure it's executable.)} This created dev.sh with content. Need to make executable: use run_in_terminal to chmod +x or can create file with proper mode? The create_file will create without execute bit. Use run_in_terminal to chmod +x. Precede with brief status update: I'll make file executable. Use functions.run_in_terminal. Also perhaps create a small README addition or update README to mention the script exists. But instruction said create script—done. But to be thorough, update arm7l/README.md to include usage snippet about dev.sh. Let's edit README to add small 