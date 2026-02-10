# OpenCode ARM7L (32-bit) Build

This directory contains instructions and utilities for building OpenCode on ARM7L (32-bit ARM) systems.

## ⚠️ Important Limitations

**Bun does not support 32-bit ARM architecture.** This means:

- You cannot use the standard Bun-compiled binary
- You must run OpenCode from TypeScript source using Node.js
- Some Bun-specific features need shims

## Prerequisites

On your ARM7L device (phone/tablet/embedded device), you need:

- Node.js 18+ (LTS recommended)
- npm (comes with Node.js)
- Git

### Installing on Android (Termux)

**Using pkg (Termux package manager):**

```bash
pkg update
pkg install nodejs-lts git
```

### Installing on Debian/Ubuntu ARM7L

```bash
sudo apt update
sudo apt install nodejs npm git
```

### Manual Installation

If `pkg` or `apt` are not available:

```bash
# Download Node.js ARM7L binary
wget https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-armv7l.tar.xz
tar -xf node-v20.11.0-linux-armv7l.tar.xz
cd node-v20.11.0-linux-armv7l
sudo cp -R * /usr/local/
```

## Build Instructions

### Option 1: Quick Start (Recommended)

1. Clone the OpenCode repository:

```bash
pkg install git  # if not already installed
git clone https://github.com/anomalyco/opencode.git
cd opencode
```

2. Run the ARM7L setup:

```bash
cd arm7l
./install.sh
```

3. Run OpenCode:

```bash
cd ../packages/opencode
npm start
```

### Dev launcher (no Bun)

If you want a `bun dev`-like workflow on 32-bit ARM without Bun, use the included launcher `arm7l/dev.sh`.

Examples:

```bash
# Start the TUI / dev mode (preloads Bun shims automatically)
cd arm7l
./dev.sh dev

# Start headless server on the default port
./dev.sh serve --port 4096

# Run the packaged CLI (if installed)
./dev.sh run --help

# Run the ARM installer, patcher, or restore
./dev.sh install
./dev.sh patch
./dev.sh restore
```

This script preloads the Bun shims and runs `tsx` (via npx if needed) so you can run the TypeScript entrypoints directly under Node.js.

### Option 2: Manual Setup

1. Install system dependencies with pkg:

```bash
pkg install nodejs-lts git
```

2. Install Bun shims globally:

```bash
npm install -g bun-types
```

3. Set up environment variables:

```bash
export NODE_OPTIONS="--experimental-specifier-resolution=node"
export OPENCODE_ARM7L=1
```

4. Install Node.js dependencies:

```bash
cd packages/opencode
cp ../../arm7l/package.json .
npm install
```

## Package Managers

### System Packages (Termux)

Use `pkg` for system-level packages:

```bash
pkg update                    # Update package lists
pkg install nodejs-lts       # Install Node.js
pkg install git              # Install Git
pkg install python           # If needed for native builds
```

### Node.js Packages

Use `npm` for Node.js/JavaScript packages:

```bash
npm install                  # Install dependencies
npm start                    # Run OpenCode
npm test                     # Run tests
```

## What Works / What Doesn't

### ✅ Should Work

- Core CLI commands
- File operations (with shims)
- Basic AI provider integrations
- Config management

### ⚠️ May Have Issues

- Bun-specific optimizations
- Native dependencies (@opentui/core, @parcel/watcher)
- Performance (slower than Bun)
- Some TUI features

### ❌ Won't Work

- Bun-specific APIs without shims
- Native compiled modules that lack arm7l binaries
- Performance comparable to Bun builds

## Native Dependencies

The following packages have native binaries that may not support arm7l:

1. **@opentui/core** - Terminal UI library
2. **@parcel/watcher** - File watching
3. **bun-pty** - Pseudoterminal support

> Note: `tree-sitter-bash` (shell parsing) is removed from the ARM7L package.json and is disabled via overrides because it requires native build tooling (Android NDK) that is not expected on unrooted Termux devices. Some parsing-related features may be unavailable.

You'll need to:

- Find arm7l-compatible alternatives
- Build from source if possible
- Or work without those features

## Troubleshooting

### pkg command not found

Make sure you're using Termux on Android:

```bash
# Check if running in Termux
 echo $PREFIX
# Should output: /data/data/com.termux/files/usr
```

If not in Termux, use your distribution's package manager (apt, yum, etc.)

### "Cannot find module 'bun:\*'"

The Bun shims aren't loaded. Make sure to:

1. Copy the shims directory contents
2. Import shims before other code

### Native module errors

Some packages don't provide arm7l binaries. Options:

1. Skip those features
2. Build the native module from source
3. Use pure-JavaScript alternatives

### npm install fails

If npm install fails on ARM7L, try:

```bash
# Clear cache
npm cache clean --force

# Install with verbose output
npm install --verbose

# Skip optional dependencies
npm install --no-optional
```

### Performance issues

Node.js is slower than Bun. Consider:

- Running on a more powerful device
- Using ARM64 device instead
- Reducing concurrent operations

## Alternative: Docker/QEMU

If source build doesn't work, try Docker with QEMU:

```bash
# On a x64/ARM64 machine
docker run --platform linux/arm/v7 -it node:20-alpine
# Then build inside the container
```

## Getting Help

- OpenCode issues: https://github.com/anomalyco/opencode/issues
- Bun ARM support: https://github.com/oven-sh/bun/issues/5060
- Termux packages: https://github.com/termux/termux-packages

## Development

To contribute arm7l improvements:

1. Test on actual arm7l hardware
2. Document any workarounds
3. Submit PRs with `[arm7l]` prefix

---

**Note**: This is a community-maintained workaround. Official arm7l support requires Bun to add 32-bit ARM support first.
