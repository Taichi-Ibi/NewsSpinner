#!/usr/bin/env bash
# NewsSpinner — one-liner installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Taichi-Ibi/NewsSpinner/main/install.sh | bash
set -euo pipefail

REPO="Taichi-Ibi/NewsSpinner"
BRANCH="main"
DEST="${HOME}/.claude"

echo "=== NewsSpinner Installer ==="

# 1. Check dependencies
missing=()
for cmd in jq curl; do
  command -v "$cmd" > /dev/null 2>&1 || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "Error: missing required dependencies: ${missing[*]}" >&2
  echo "Install them and retry (e.g. brew install jq curl)" >&2
  exit 1
fi
echo "[1/4] Dependencies OK (jq, curl)"

# 2. Download repo and extract skills
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "[2/4] Downloading skills from GitHub..."
curl -fsSL "https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz" \
  | tar xz -C "$TMP" --strip-components=1

# 3. Copy .claude/skills/ to ~/.claude/skills/
mkdir -p "$DEST/skills"
cp -r "$TMP/.claude/skills/." "$DEST/skills/"
echo "[3/4] Skills installed to $DEST/skills/"

# 4. Run skill installer(s)
for install_sh in "$DEST/skills"/*/bin/install.sh; do
  [ -f "$install_sh" ] || continue
  bash "$install_sh"
done

echo ""
echo "=== Installation complete! ==="
echo "Restart Claude Code to activate the hook."
echo ""
echo "Quick start in Claude Code:"
echo "  /news-fetch add AI      # add a feed"
echo "  /news-fetch fetch       # fetch headlines"
