---
name: ad
description: >
  Manage joke sponsor ads for the spinner.
  Trigger when user wants to add/remove/load ads, toggle premium mode,
  or skip ads. Keywords: ad, ads, 広告, スポンサー, sponsor, premium
argument-hint: "[add|remove|list|load|premium|--skip-ads] [text]"
disable-model-invocation: true
allowed-tools: Bash, AskUserQuestion
---

# JokeAds — Sponsor Ad Management

Replace Claude Code's spinner text with fake sponsor ads.

## Current Status

Ad inventory:
!`SPINNER_DIR="$(cd "${CLAUDE_SKILL_DIR}/../../.." && pwd)" && jq 'length' "$SPINNER_DIR/ads.json" 2>/dev/null || echo "0"` ads registered

Pool remaining:
!`SPINNER_DIR="$(cd "${CLAUDE_SKILL_DIR}/../../.." && pwd)" && jq 'length' "$SPINNER_DIR/pool.json" 2>/dev/null || echo "0"`

Premium status:
!`SPINNER_DIR="$(cd "${CLAUDE_SKILL_DIR}/../../.." && pwd)" && jq -r '.premium // false' "$SPINNER_DIR/config.json" 2>/dev/null || echo "false"`

## Prerequisites

If not yet installed, guide the user to run:

```
bash "${CLAUDE_SKILL_DIR}/bin/install.sh"
```

## Behavior

### No arguments (`$ARGUMENTS` is empty)

Use AskUserQuestion to let the user choose an action:
1. Load ads — reload ads into the spinner pool
2. Add a custom ad — ask for text, then run `add`
3. List all ads — show the ad inventory
4. Toggle Premium mode — activate/deactivate "premium"
5. Skip ads — run --skip-ads (warn them it "definitely works")

### `add <text>`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" add "$1"
```

- After adding, ask "Load ads now?" and run load if yes:
  ```bash
  bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" load
  ```

### `remove <text>`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" remove "$1"
```

### `list`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" list
```

### `load`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" load
```

### `premium`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" premium
```

Then run load to apply:
```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" load
```

### `--skip-ads`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" --skip-ads
```

After running, tell the user with a straight face that ads have been successfully skipped.

### `pool`

```bash
bash "${CLAUDE_SKILL_DIR}/bin/ads.sh" pool
```

## Error Handling

- Command failure: show the error output and suggest likely causes
- `jq` not installed: guide user to run `install.sh`
- Corrupted config.json: restore from default:
  ```bash
  SPINNER_DIR="$(cd "${CLAUDE_SKILL_DIR}/../../.." && pwd)"
  cp "${CLAUDE_SKILL_DIR}/config.json" "$SPINNER_DIR/config.json"
  ```
- Corrupted ads.json: restore from default:
  ```bash
  SPINNER_DIR="$(cd "${CLAUDE_SKILL_DIR}/../../.." && pwd)"
  cp "${CLAUDE_SKILL_DIR}/ads.json" "$SPINNER_DIR/ads.json"
  ```
