#!/usr/bin/env bash
# Install TVMonkey on macOS / Linux.
#
# Usage:
#   ./scripts/install.sh        # build and install into ~/.local/bin
#   PREFIX=/usr/local/bin ./scripts/install.sh
#
# The script requires Bun (for compiling the binary) and npm (for dependencies).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
BIN_NAME="tvmonkey"

echo "[tvmonkey-install] repo: $REPO_ROOT"
echo "[tvmonkey-install] install prefix: $PREFIX"

# --- prerequisites ---
if ! command -v bun &> /dev/null; then
  echo "[tvmonkey-install] ERROR: Bun is required to build the binary."
  echo "[tvmonkey-install] Install from https://bun.sh then re-run."
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo "[tvmonkey-install] ERROR: npm is required to install dependencies."
  exit 1
fi

echo "[tvmonkey-install] Bun: $(bun --version)"
echo "[tvmonkey-install] npm: $(npm --version)"

# --- build ---
cd "$REPO_ROOT"
if [ ! -d "node_modules" ]; then
  echo "[tvmonkey-install] installing npm dependencies..."
  npm install
fi

echo "[tvmonkey-install] building binary..."
npm run build

if [ ! -f "dist/$BIN_NAME" ]; then
  echo "[tvmonkey-install] ERROR: build did not produce dist/$BIN_NAME"
  exit 1
fi

# --- install binary ---
mkdir -p "$PREFIX"
cp "dist/$BIN_NAME" "$PREFIX/$BIN_NAME"
chmod +x "$PREFIX/$BIN_NAME"

# --- config directory (private) ---
CONFIG_DIR="$HOME/.tvmonkey"
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"
echo "[tvmonkey-install] config dir: $CONFIG_DIR (0700)"

# --- verify PATH ---
if ! command -v tvmonkey &> /dev/null; then
  if [[ ":$PATH:" != *":$PREFIX:"* ]]; then
    echo ""
    echo "[tvmonkey-install] WARNING: $PREFIX is not in your PATH."
    echo "[tvmonkey-install] Add this line to your shell profile (~/.zshrc, ~/.bashrc, etc.):"
    echo "    export PATH=\"$PREFIX:\$PATH\""
    echo "[tvmonkey-install] Then reload: source ~/.zshrc  # or ~/.bashrc"
  fi
fi

# --- success ---
echo ""
echo "[tvmonkey-install] DONE — installed $PREFIX/$BIN_NAME"
echo "[tvmonkey-install] Version: $("$PREFIX/$BIN_NAME" --version)"
echo ""
echo "Next steps:"
echo "  1. Make sure $PREFIX is in PATH (or open a new terminal)."
echo "  2. Run: tvmonkey"
echo "  3. The TUI config panel opens on first run — fill NGQ_API_KEY and save."
echo ""
echo "To run bridge as a background service:"
echo "  tvmonkey --bridge"
echo "Service examples are in INSTALL.md (launchd/systemd/Windows)."
