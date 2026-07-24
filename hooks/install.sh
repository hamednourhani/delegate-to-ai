#!/bin/bash
# Hook installer: symlinks hooks to user hooks directory and registers them
# in ~/.claude/settings.json.
# Usage: ./install.sh <hook-name>
#   <hook-name>: name of the hook to install (e.g., session-hygiene-check)
#
# Example:
#   ./install.sh session-hygiene-check
#
# A hook directory (hooks/claude/<hook-name>/) may contain one file per
# Claude Code event it hooks into (e.g. UserPromptSubmit, SessionStart,
# PreToolUse, PostToolUse, Stop, SubagentStop, Notification,
# PreCompact). Every matching file found is installed and registered —
# this script does not assume a single fixed event type.

set -euo pipefail

VALID_EVENTS=(
  UserPromptSubmit SessionStart SessionEnd PreToolUse PostToolUse
  Stop SubagentStop Notification PreCompact
)

is_valid_event() {
  local candidate="$1"
  for e in "${VALID_EVENTS[@]}"; do
    [ "$e" = "$candidate" ] && return 0
  done
  return 1
}

# Check for required dependencies
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    echo ""
    echo "The installer needs jq to:"
    echo "  • Register hooks in ~/.claude/settings.json"
    echo "  • Parse configuration files"
    echo ""
    echo "Without jq, hooks won't be picked up by Claude Code."
    echo ""
    echo "Install jq:"
    echo "  macOS:  brew install jq"
    echo "  Ubuntu: sudo apt-get install jq"
    echo "  Fedora: sudo dnf install jq"
    echo ""
    return 1
  fi
  return 0
}

# Validate jq before proceeding
if ! check_jq; then
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting installation."
    exit 1
  fi
  echo "⚠️  Installation proceeding without jq. settings.json registration will be skipped."
fi

# Validate arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <hook-name>"
  echo ""
  echo "Arguments:"
  echo "  <hook-name>: name of the hook (e.g., session-hygiene-check)"
  echo ""
  echo "Example:"
  echo "  $0 session-hygiene-check"
  exit 1
fi

HOOK_NAME="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$SCRIPT_DIR/claude/$HOOK_NAME"

if [ ! -d "$HOOK_DIR" ]; then
  echo "❌ Hook not found: $HOOK_NAME"
  echo "Available hooks in $SCRIPT_DIR/claude/:"
  ls -1 "$SCRIPT_DIR/claude/" 2>/dev/null || echo "  (none)"
  exit 1
fi

# Discover which events this hook implements (one file per event, named
# after the event, e.g. UserPromptSubmit, SessionStart, PreToolUse)
EVENTS=()
for f in "$HOOK_DIR"/*; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  if is_valid_event "$base"; then
    EVENTS+=("$base")
  fi
done

if [ ${#EVENTS[@]} -eq 0 ]; then
  echo "❌ No recognized event files found in $HOOK_DIR"
  echo "   Expected one of: ${VALID_EVENTS[*]}"
  exit 1
fi

HOOKS_DIR="$HOME/.claude/hooks"
if [ ! -d "$HOOKS_DIR" ]; then
  mkdir -p "$HOOKS_DIR"
  echo "📁 Created directory: $HOOKS_DIR"
fi

# Register a single event's hook into ~/.claude/settings.json.
# Claude Code only invokes hooks declared there — a symlink in
# ~/.claude/hooks/ alone is never picked up.
register_hook() {
  local event="$1"
  local cmd="$2"

  if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found — register this manually in ~/.claude/settings.json:"
    echo "   \"hooks\": { \"$event\": [ { \"matcher\": \"*\", \"hooks\": [ { \"type\": \"command\", \"command\": \"$cmd\" } ] } ] }"
    return
  fi

  local settings_file="$HOME/.claude/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo '{}' > "$settings_file"
  fi

  # Abort rather than touch a file that isn't valid JSON to begin with —
  # never attempt to merge into something we can't parse.
  if ! jq empty "$settings_file" &> /dev/null; then
    echo "❌ $settings_file is not valid JSON — refusing to modify it."
    echo "   Fix it manually, then re-run to register $event."
    return 1
  fi

  if jq -e --arg event "$event" --arg cmd "$cmd" \
      '.hooks[$event] // [] | any(.hooks[]?.command == $cmd)' \
      "$settings_file" &> /dev/null; then
    echo "ℹ️  $event already registered in settings.json"
    return
  fi

  # Timestamped backup before any mutation, so a bad merge is always recoverable.
  local backup_file
  backup_file="${settings_file}.bak.$(date +%Y%m%d%H%M%S 2>/dev/null || echo pre-install)"
  cp "$settings_file" "$backup_file"

  local tmp_file
  tmp_file="$(mktemp)"
  if ! jq --arg event "$event" --arg cmd "$cmd" '
    .hooks //= {} |
    .hooks[$event] //= [] |
    .hooks[$event] += [
      { "matcher": "*", "hooks": [ { "type": "command", "command": $cmd } ] }
    ]
  ' "$settings_file" > "$tmp_file"; then
    echo "❌ jq merge failed — $settings_file left untouched (backup: $backup_file)"
    rm -f "$tmp_file"
    return 1
  fi

  # Validate the merged output is well-formed JSON before it ever replaces
  # the real file — never let a malformed result land.
  if ! jq empty "$tmp_file" &> /dev/null; then
    echo "❌ Merged result is not valid JSON — $settings_file left untouched (backup: $backup_file)"
    rm -f "$tmp_file"
    return 1
  fi

  mv "$tmp_file" "$settings_file"
  echo "✅ Registered $event in $settings_file (backup: $backup_file)"
}

for event in "${EVENTS[@]}"; do
  HOOK_SRC="$HOOK_DIR/$event"
  HOOK_DST="$HOOKS_DIR/${HOOK_NAME}-${event}"

  if [ -e "$HOOK_DST" ] && [ ! -L "$HOOK_DST" ]; then
    echo "⚠️  File already exists (not a symlink): $HOOK_DST"
    echo "   Skipping to avoid overwriting"
    continue
  fi

  [ -L "$HOOK_DST" ] && rm "$HOOK_DST"
  ln -s "$HOOK_SRC" "$HOOK_DST"

  if [ -L "$HOOK_DST" ]; then
    echo "✅ $HOOK_NAME ($event) installed"
    echo "   Symlink: $HOOK_DST → $HOOK_SRC"
  else
    echo "❌ Installation failed for $event"
    continue
  fi

  register_hook "$event" "$HOOK_DST"
done
