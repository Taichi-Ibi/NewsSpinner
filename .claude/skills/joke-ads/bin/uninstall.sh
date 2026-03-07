#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPINNER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # PROJECT/.claude/
SETTINGS="$SPINNER_DIR/settings.json"

echo "=== JokeAds Uninstaller ==="

# 1. Clean up settings.json
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"

  jq '
    # Remove hook entries containing "rotate.sh"
    if .hooks.PostToolUse then
      .hooks.PostToolUse = [
        .hooks.PostToolUse[] |
        select((.hooks // []) | all(.command // "" | contains("rotate.sh") | not))
      ]
    else . end |
    # Clean up empty arrays/objects
    if (.hooks.PostToolUse // []) | length == 0 then del(.hooks.PostToolUse) else . end |
    if (.hooks // {}) | length == 0 then del(.hooks) else . end |
    # Remove spinnerVerbs override
    del(.spinnerVerbs)
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "[1/2] Hook and spinnerVerbs removed from settings.json"
else
  echo "[1/2] settings.json not found, skipping"
fi

# 2. Remove runtime data files (preserve config.json, ads.json, and skill files)
removed=()
for f in pool.json history.json; do
  if [ -f "$SPINNER_DIR/$f" ]; then
    rm "$SPINNER_DIR/$f"
    removed+=("$f")
  fi
done
if [ "${#removed[@]}" -gt 0 ]; then
  echo "[2/2] Removed runtime data: ${removed[*]}"
else
  echo "[2/2] No runtime data files found, skipping"
fi

echo ""
echo "=== Uninstall complete! ==="
echo "広告のない世界へようこそ。…でも本当にそれでいいんですか？"
echo "Restart Claude Code to apply changes."
