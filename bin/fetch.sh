#!/usr/bin/env bash
set -euo pipefail

SPINNER_DIR="${NEWSSPINNER_DIR:-$HOME/.newsspinner}"
CONFIG="$SPINNER_DIR/config.json"
POOL="$SPINNER_DIR/pool.json"
HISTORY="$SPINNER_DIR/history.json"
LOCK="$SPINNER_DIR/.lock"

# Ensure files exist
[ -f "$POOL" ] || echo '[]' > "$POOL"
[ -f "$HISTORY" ] || echo '[]' > "$HISTORY"

if [ ! -f "$CONFIG" ]; then
  echo "Error: $CONFIG not found. Run install.sh first." >&2
  exit 1
fi

MAX_POOL_SIZE=$(jq -r '.max_pool_size // 50' "$CONFIG")
MAX_TITLE_LEN=$(jq -r '.max_title_length // 40' "$CONFIG")

# Truncate title if needed
truncate_title() {
  local title="$1"
  if [ "${#title}" -gt "$MAX_TITLE_LEN" ]; then
    echo "${title:0:$((MAX_TITLE_LEN - 1))}…"
  else
    echo "$title"
  fi
}

# Extract titles from RSS/Atom XML
extract_titles() {
  local xml="$1"
  # Extract <title> content, handling CDATA; skip the first (feed-level) title
  grep -oP '<title[^>]*>\s*(?:<!\[CDATA\[)?\K[^<\]]+' <<< "$xml" | tail -n +2
}

do_fetch() {
  local added=0
  local feed_count
  feed_count=$(jq -r '.feeds | length' "$CONFIG")

  for ((i = 0; i < feed_count; i++)); do
    local url name xml
    url=$(jq -r ".feeds[$i].url" "$CONFIG")
    name=$(jq -r ".feeds[$i].name" "$CONFIG")

    # Fetch RSS feed
    xml=$(curl -sL --max-time 10 "$url" 2>/dev/null) || {
      echo "Warning: Failed to fetch $name ($url)" >&2
      continue
    }

    # Extract and process titles
    while IFS= read -r raw_title; do
      # Skip empty lines
      [ -z "$raw_title" ] && continue

      # Trim whitespace
      raw_title=$(echo "$raw_title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [ -z "$raw_title" ] && continue

      # Truncate
      local title
      title=$(truncate_title "$raw_title")

      # Check current pool size
      local pool_size
      pool_size=$(jq 'length' "$POOL")
      if [ "$pool_size" -ge "$MAX_POOL_SIZE" ]; then
        echo "Pool is full ($MAX_POOL_SIZE). Stopping." >&2
        break 2
      fi

      # Check for duplicates in pool and history
      if jq -e --arg t "$title" 'index($t) != null' "$POOL" > /dev/null 2>&1; then
        continue
      fi
      if jq -e --arg t "$title" 'index($t) != null' "$HISTORY" > /dev/null 2>&1; then
        continue
      fi

      # Add to pool
      jq --arg t "$title" '. + [$t]' "$POOL" > "$POOL.tmp" && mv "$POOL.tmp" "$POOL"
      added=$((added + 1))
    done < <(extract_titles "$xml")
  done

  local total
  total=$(jq 'length' "$POOL")
  echo "Added $added new titles. Pool size: $total"
}

# Use flock if available
if command -v flock > /dev/null 2>&1; then
  exec 9>"$LOCK"
  flock -w 10 9 || { echo "Error: Could not acquire lock" >&2; exit 1; }
  do_fetch
  exec 9>&-
else
  do_fetch
fi

# Run rotate once to update spinner immediately
bash "$SPINNER_DIR/bin/rotate.sh" 2>/dev/null || true
