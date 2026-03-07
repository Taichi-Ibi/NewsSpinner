#!/usr/bin/env bash
# NewsSpinner — one-liner installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Taichi-Ibi/NewsSpinner/main/install.sh | bash
set -euo pipefail

REPO="Taichi-Ibi/NewsSpinner"
BRANCH="main"
PROJECT_ROOT="$(pwd)"
CLAUDE_DIR="${PROJECT_ROOT}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"

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

# 2. Ensure project-local .claude/ exists
mkdir -p "${CLAUDE_DIR}"
echo "[2/4] Using project directory: ${PROJECT_ROOT}"

# 3. Download repo and extract skills
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "[3/4] Downloading skills from GitHub..."
curl -fsSL "https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz" \
  | tar xz -C "$TMP" --strip-components=1

# 4. Copy .claude/skills/ to project-local ./.claude/skills/
mkdir -p "${SKILLS_DIR}"
cp -r "$TMP/.claude/skills/." "${SKILLS_DIR}/"
echo "       Skills installed to ${SKILLS_DIR}/"

# 5. Run skill installer(s)
for install_sh in "${SKILLS_DIR}"/*/bin/install.sh; do
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
echo ""
