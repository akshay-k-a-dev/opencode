#!/usr/bin/env bash

# OpenCode ARM7L Installation Script
# This script sets up OpenCode to run on 32-bit ARM systems without Bun

set -e

echo "========================================"
echo "OpenCode ARM7L Setup"
echo "========================================"
echo ""
echo "⚠️  WARNING: Bun does NOT support 32-bit ARM"
echo "   This script creates a workaround using Node.js"
echo ""

# Check if running on ARM7L
ARCH=$(uname -m)
if [[ "$ARCH" != "armv7l" && "$ARCH" != "armv6l" && "$ARCH" != "arm" ]]; then
    echo "⚠️  Warning: Detected architecture is $ARCH, not armv7l"
    echo "This script is designed for 32-bit ARM systems."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Architecture: $ARCH"
echo ""

# Detect if running in Termux
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux/files/usr" ]; then
    echo "✓ Termux environment detected"
    PKG_MANAGER="pkg"
else
    echo "✓ Standard Linux environment"
    PKG_MANAGER="apt"
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo ""
    echo "Please install Node.js 18+ first:"
    echo ""
    if [ "$PKG_MANAGER" = "pkg" ]; then
        echo "  pkg update"
        echo "  pkg install nodejs-lts"
    else
        echo "  sudo apt update"
        echo "  sudo apt install nodejs npm"
    fi
    echo ""
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version is too old: $(node --version)"
    echo "Please upgrade to Node.js 18+"
    if [ "$PKG_MANAGER" = "pkg" ]; then
        echo "Run: pkg install nodejs-lts"
    fi
    exit 1
fi

echo "✓ Node.js version: $(node --version)"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed!"
    if [ "$PKG_MANAGER" = "pkg" ]; then
        echo "Run: pkg install nodejs-lts"
    else
        echo "Install Node.js (npm comes with it)"
    fi
    exit 1
fi

echo "✓ npm version: $(npm --version)"

# Check for git
if ! command -v git &> /dev/null; then
    echo "⚠️  Git is not installed"
    if [ "$PKG_MANAGER" = "pkg" ]; then
        echo "Installing git with pkg..."
        pkg install git
    else
        echo "Please install git: sudo apt install git"
        exit 1
    fi
fi

echo "✓ Git is available"
echo ""

# Get the OpenCode root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ARM7L_DIR="$SCRIPT_DIR"

echo "OpenCode root: $OPENCODE_ROOT"
echo "ARM7L directory: $ARM7L_DIR"
echo ""

# Step 1: Copy ARM7L files
echo "Step 1: Setting up ARM7L compatibility layer..."
cp "$ARM7L_DIR/package.json" "$OPENCODE_ROOT/packages/opencode/package-arm7l.json"
cp -r "$ARM7L_DIR/shims" "$OPENCODE_ROOT/packages/opencode/.shims"
cp "$ARM7L_DIR/tsconfig.json" "$OPENCODE_ROOT/packages/opencode/tsconfig-arm7l.json"

cd "$OPENCODE_ROOT/packages/opencode"

# Backup original package.json
if [ -f "package.json" ] && [ ! -f "package-original.json" ]; then
    cp package.json package-original.json
    echo "✓ Backed up original package.json"
fi

# Use ARM7L package.json
mv package-arm7l.json package.json

echo ""
echo "Step 2: Installing Node.js dependencies..."
echo "(This may take a while on ARM7L)"
echo ""

# Install dependencies with npm
npm install || {
    echo "❌ npm install failed!"
    echo "Try: npm install --verbose"
    exit 1
}

echo ""
echo "✓ Dependencies installed"
echo ""

# Step 3: Patch source files
echo "Step 3: Patching source files for Node.js compatibility..."
echo ""

# Run patch script
"$ARM7L_DIR/patch.sh" || {
    echo "❌ Patching failed!"
    exit 1
}

echo ""
echo "✓ Source files patched"
echo ""

# Step 4: Make bin script executable
chmod +x "$ARM7L_DIR/bin/opencode"

# Step 5: Create launcher script
cat > "$OPENCODE_ROOT/packages/opencode/opencode" << 'EOF'
#!/usr/bin/env node
// ARM7L launcher - loads shims before main code
import './.shims/bun-shim.js';
import './src/index.ts';
EOF
chmod +x "$OPENCODE_ROOT/packages/opencode/opencode"

echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
echo "To run OpenCode:"
echo "  cd $OPENCODE_ROOT/packages/opencode"
echo "  ./opencode"
echo "  # OR"
echo "  npx tsx src/index.ts"
echo ""
echo "To run with npm:"
echo "  npm start"
echo ""

if [ "$PKG_MANAGER" = "pkg" ]; then
    echo "Termux commands:"
    echo "  pkg install nodejs-lts  # Install/update Node.js"
    echo "  npm install            # Install dependencies"
    echo "  npm start              # Run OpenCode"
    echo ""
fi

echo "Troubleshooting:"
echo "  - If you see 'Bun is not defined', the shims didn't load"
echo "  - If native modules fail, those features won't work on ARM7L"
echo "  - Run ./restore.sh to undo patches"
echo ""
echo "⚠️  Note: This is a workaround. Some features may not work"
echo "   due to Bun being required for the official build."
echo ""
