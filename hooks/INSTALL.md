# Hook Installation Guide

Install Claude Code hooks with the provided `install.sh` script. Each hook can be installed **user-wide** (all projects) or **project-wide** (this project only).

## Requirements

### jq (required)

Most hooks in this collection require **jq** (JSON query tool) to function. This is especially true for hooks that need to:
- Parse hook input from Claude Code
- Read your transcript file
- Extract token counts and model information
- Parse configuration files

**Install jq:**

```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt-get install jq

# Fedora / RHEL
sudo dnf install jq

# Alpine
apk add jq
```

**Verify installation:**
```bash
jq --version
```

The installer checks for jq and warns if it's missing. Hooks may not function correctly without jq.

## Quick start

```bash
cd hooks/

# Install to user-wide hooks (~/.claude/hooks/)
./install.sh session-hygiene-check user

# Or install to project-wide hooks (.claude/hooks/)
./install.sh session-hygiene-check project
```

## How it works

The installer:
1. Validates the hook exists
2. Creates `~/.claude/hooks/` or `.claude/hooks/` if missing
3. Creates a **symlink** to the hook (not a copy)
4. Symlinks auto-update when you `git pull` the repo

## Usage

```bash
./install.sh <hook-name> <scope>
```

**Arguments:**
- `<hook-name>`: Name of the hook (e.g., `session-hygiene-check`)
- `<scope>`: `user` for user-wide, `project` for project-wide

## Available hooks

- `session-hygiene-check` — Auto-checkpoint every N turns to keep your model/effort/context in sync

## Examples

### User-wide installation (recommended for individuals)

```bash
./install.sh session-hygiene-check user
```

The hook runs for **all your Claude Code sessions**, across all projects.

**Uninstall**: `rm ~/.claude/hooks/UserPromptSubmit`

### Project-wide installation (for team projects)

```bash
./install.sh session-hygiene-check project
```

The hook runs **only for this project** (overrides user-wide if both exist).

**Uninstall**: `rm .claude/hooks/UserPromptSubmit`

## Troubleshooting

### Hook file already exists (not a symlink)

```
⚠️  File already exists (not a symlink): ~/.claude/hooks/UserPromptSubmit
```

You have a regular file, not a symlink. Remove it and reinstall:

```bash
rm ~/.claude/hooks/UserPromptSubmit
./install.sh session-hygiene-check user
```

### Symlink broken after moving the repo

If you move or rename the repo, symlinks break. Reinstall:

```bash
./install.sh session-hygiene-check user
```

The script uses absolute paths, so moving the repo requires a reinstall.

### Hook not firing

1. Verify it's installed: `ls -la ~/.claude/hooks/UserPromptSubmit`
2. Check permissions: `chmod +x ~/.claude/hooks/UserPromptSubmit`
3. Verify path: `readlink ~/.claude/hooks/UserPromptSubmit` (should point to this repo)
4. Check Claude Code logs for hook errors

## Per-hook configuration

Each hook has its own README with configuration options:

- [session-hygiene-check](claude/session-hygiene-check/README.md) — Thresholds, settings, troubleshooting

## Adding new hooks

To add a new hook to this repo:

1. Create a folder under `hooks/claude/<hook-name>/`
2. Add your hook script as `UserPromptSubmit`
3. Add `README.md` and `DESIGN.md` documentation
4. Run: `./install.sh <hook-name> user` to test

The installer auto-discovers new hooks.
