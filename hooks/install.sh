#!/bin/bash
# Hook installer: symlinks hooks to user or project hooks directory
# Usage: ./install.sh <hook-name> <scope>
#   <hook-name>: name of the hook to install (e.g., session-hygiene-check)
#   <scope>: "user" for ~/.claude/hooks/ or "project" for .claude/hooks/
#
# Examples:
#   ./install.sh session-hygiene-check user
#   ./install.sh session-hygiene-check project

set -euo pipefail

# Check for required dependencies
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    echo ""
    echo "The session-hygiene-check hook needs jq to:"
    echo "  • Parse JSON from Claude Code"
    echo "  • Read your transcript"
    echo "  • Extract token counts"
    echo "  • Parse configuration files"
    echo ""
    echo "Without jq, this hook will not work."
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
  echo "⚠️  Installation proceeding without jq. The hook may not work."
fi

# Validate arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <hook-name> <scope>"
  echo ""
  echo "Arguments:"
  echo "  <hook-name>: name of the hook (e.g., session-hygiene-check)"
  echo "  <scope>:     'user' for ~/.claude/hooks/ or 'project' for .claude/hooks/"
  echo ""
  echo "Examples:"
  echo "  $0 session-hygiene-check user"
  echo "  $0 session-hygiene-check project"
  exit 1
fi

HOOK_NAME="$1"
SCOPE="$2"

# Validate hook exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/claude/$HOOK_NAME/UserPromptSubmit"

if [ ! -f "$HOOK_SRC" ]; then
  echo "❌ Hook not found: $HOOK_NAME"
  echo "Available hooks in $SCRIPT_DIR/claude/:"
  ls -1 "$SCRIPT_DIR/claude/" 2>/dev/null || echo "  (none)"
  exit 1
fi

# Determine destination based on scope
case "$SCOPE" in
  user)
    HOOKS_DIR="$HOME/.claude/hooks"
    SCOPE_NAME="user-wide"
    ;;
  project)
    HOOKS_DIR=".claude/hooks"
    SCOPE_NAME="project-wide"
    ;;
  *)
    echo "❌ Invalid scope: $SCOPE"
    echo "Use 'user' or 'project'"
    exit 1
    ;;
esac

# Create hooks directory if it doesn't exist
if [ ! -d "$HOOKS_DIR" ]; then
  mkdir -p "$HOOKS_DIR"
  echo "📁 Created directory: $HOOKS_DIR"
fi

# Create symlink
HOOK_DST="$HOOKS_DIR/UserPromptSubmit"
if [ -e "$HOOK_DST" ] && [ ! -L "$HOOK_DST" ]; then
  echo "⚠️  File already exists (not a symlink): $HOOK_DST"
  echo "   Skipping installation to avoid overwriting"
  exit 1
fi

# Remove old symlink if it exists
if [ -L "$HOOK_DST" ]; then
  rm "$HOOK_DST"
fi

# Create new symlink with absolute path (more robust)
ln -s "$HOOK_SRC" "$HOOK_DST"

# Verify
if [ -L "$HOOK_DST" ]; then
  echo "✅ $HOOK_NAME installed ($SCOPE_NAME)"
  echo "   Symlink: $HOOK_DST → $HOOK_SRC"
else
  echo "❌ Installation failed"
  exit 1
fi
