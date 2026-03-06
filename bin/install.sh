#!/usr/bin/env bash
set -euo pipefail

SPINNER_DIR="${NEWSSPINNER_DIR:-$HOME/.newsspinner}"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== NewsSpinner Installer ==="

# 1. Check dependencies
for cmd in jq curl; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "Error: '$cmd' is required but not found. Please install it." >&2
    exit 1
  fi
done
echo "Dependencies OK (jq, curl)"

# 2. Create directories
mkdir -p "$SPINNER_DIR/bin"
mkdir -p "$CLAUDE_DIR"
echo "Directories created"

# 3. Copy scripts and set permissions
for script in fetch.sh rotate.sh install.sh uninstall.sh; do
  if [ -f "$SCRIPT_DIR/bin/$script" ]; then
    cp "$SCRIPT_DIR/bin/$script" "$SPINNER_DIR/bin/$script"
    chmod +x "$SPINNER_DIR/bin/$script"
  fi
done
echo "Scripts installed"

# 4. Create config.json if not exists
if [ ! -f "$SPINNER_DIR/config.json" ]; then
  cp "$SCRIPT_DIR/config.json" "$SPINNER_DIR/config.json"
  echo "Default config.json created"
else
  echo "config.json already exists, skipping"
fi

# 5. Initialize pool.json and history.json
echo '[]' > "$SPINNER_DIR/pool.json"
echo '[]' > "$SPINNER_DIR/history.json"
echo "pool.json and history.json initialized"

# 6. Add PostToolUse hook to settings.json
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

# Backup settings
cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
echo "settings.json backed up"

# Check if newsspinner hook already exists
if jq -e '.hooks.PostToolUse[]?.hooks[]? | select(.command | contains("newsspinner"))' "$SETTINGS" > /dev/null 2>&1; then
  echo "NewsSpinner hook already registered, skipping"
else
  # Add the PostToolUse hook, preserving existing hooks
  jq '
    .hooks //= {} |
    .hooks.PostToolUse //= [] |
    .hooks.PostToolUse += [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.newsspinner/bin/rotate.sh 2>/dev/null || true"
          }
        ]
      }
    ]
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "PostToolUse hook registered"
fi

# 7. Run initial fetch
echo ""
echo "Running initial fetch..."
bash "$SPINNER_DIR/bin/fetch.sh"

echo ""
echo "=== Installation complete! ==="
echo "Restart Claude Code to activate the hook."
echo ""
echo "Commands:"
echo "  bash ~/.newsspinner/bin/fetch.sh      # Fetch new headlines"
echo "  bash ~/.newsspinner/bin/rotate.sh     # Manually rotate spinner"
echo "  bash ~/.newsspinner/bin/uninstall.sh  # Remove NewsSpinner"
