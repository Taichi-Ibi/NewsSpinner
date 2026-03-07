#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPINNER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # PROJECT/.claude/
ROTATE_SH="$SCRIPT_DIR/rotate.sh"
SETTINGS="$SPINNER_DIR/settings.json"

echo "=== JokeAds Installer ==="
echo "📢 スポンサー付きスピナー体験をお届けします"
echo ""

# 1. Check dependencies
missing=()
for cmd in jq; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    missing+=("$cmd")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Error: missing required dependencies: ${missing[*]}" >&2
  echo "Please install them and try again." >&2
  exit 1
fi
echo "[1/4] Dependencies OK (jq)"

# 2. Set execute permissions on scripts
chmod +x "$SCRIPT_DIR"/*.sh
echo "[2/4] Script permissions set"

# 3. Create config.json (preserve existing)
if [ ! -f "$SPINNER_DIR/config.json" ]; then
  cp "$SKILL_DIR/config.json" "$SPINNER_DIR/config.json"
  echo "[3/4] Default config.json created"
else
  echo "[3/4] config.json already exists, keeping current"
fi

# 4. Copy ads.json and initialize data files
if [ ! -f "$SPINNER_DIR/ads.json" ]; then
  cp "$SKILL_DIR/ads.json" "$SPINNER_DIR/ads.json"
  echo "[4/4] Default ads.json created ($(jq 'length' "$SPINNER_DIR/ads.json") ads loaded)"
else
  echo "[4/4] ads.json already exists, keeping current ($(jq 'length' "$SPINNER_DIR/ads.json") ads)"
fi
[ -f "$SPINNER_DIR/pool.json" ]    || echo '[]' > "$SPINNER_DIR/pool.json"
[ -f "$SPINNER_DIR/history.json" ] || echo '[]' > "$SPINNER_DIR/history.json"

# 5. Register UserPromptSubmit hook in project settings.json
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"

if jq -e '.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("rotate.sh"))' "$SETTINGS" > /dev/null 2>&1; then
  echo "[5/5] Spinner hook already registered"
else
  jq --arg cmd "$ROTATE_SH 2>/dev/null || true" '
    .hooks //= {} |
    .hooks.UserPromptSubmit //= [] |
    .hooks.UserPromptSubmit += [
      {
        "hooks": [
          {
            "type": "command",
            "command": $cmd
          }
        ]
      }
    ]
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "[5/5] UserPromptSubmit hook registered"
fi

# Load ads into pool automatically
echo ""
echo "Loading ads into pool..."
bash "$SCRIPT_DIR/ads.sh" load

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Restart Claude Code to activate the hook."
echo ""
echo "Quick start:"
echo "  /ad                                            # manage ads in Claude Code"
echo "  bash \"$SCRIPT_DIR/ads.sh\" list                # list all ads"
echo "  bash \"$SCRIPT_DIR/ads.sh\" add \"🍣 ...\"       # add a custom ad"
echo "  bash \"$SCRIPT_DIR/ads.sh\" --skip-ads          # skip ads (try it!)"
echo "  bash \"$SCRIPT_DIR/ads.sh\" premium             # go premium (try it!)"
