# Hook Installation Guide

Install Claude Code hooks with the provided `install.sh` script. Each hook can be installed **user-wide** (all projects) or **project-wide** (this project only).

## Requirements

Most hooks require **jq** to parse JSON and read configuration files. The installer will warn you if jq is missing.

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

## Installation

```bash
cd hooks/
./install.sh <hook-name> <scope>
```

**Arguments:**
- `<hook-name>`: Hook to install (e.g., `session-hygiene-check`)
- `<scope>`: `user` for `~/.claude/hooks/` or `project` for `.claude/hooks/`

**Examples:**
```bash
# Install to user-wide hooks (all projects)
./install.sh session-hygiene-check user

# Install to project-wide hooks (this project only)
./install.sh session-hygiene-check project
```

## How it works

The installer:
1. **Checks for jq** — warns if missing
2. **Validates the hook** — checks if it exists
3. **Creates hooks directory** — `~/.claude/hooks/` or `.claude/hooks/` if needed
4. **Symlinks the hook** — creates a symlink (not a copy)
5. **Auto-updates** — hook updates when you `git pull` this repo

## Available hooks

- `session-hygiene-check` — Auto-checkpoint every N turns to keep your model/effort/context in sync
  - [Configuration →](claude/session-hygiene-check/README.md)
  - [Design rationale →](claude/session-hygiene-check/DESIGN.md)

## Scope: User-wide vs Project-wide

### User-wide (`user`)
```bash
./install.sh session-hygiene-check user
```
- Hook runs for **all your Claude Code sessions**, across all projects
- Installed at `~/.claude/hooks/UserPromptSubmit`
- One install, used everywhere

### Project-wide (`project`)
```bash
./install.sh session-hygiene-check project
```
- Hook runs **only for this project** (overrides user-wide if both exist)
- Installed at `.claude/hooks/UserPromptSubmit`
- Project-specific configuration

## Configuration

Each hook may have its own configuration via `.claude/settings.json`. See the hook's README for details.

Example:
```json
{
  "sessionHygiene": {
    "turnThreshold": 10,
    "minuteThreshold": 10,
    "contextTokenThreshold": 120000
  }
}
```

## Uninstall

```bash
# User-wide
rm ~/.claude/hooks/UserPromptSubmit

# Project-wide
rm .claude/hooks/UserPromptSubmit
```

## Troubleshooting

### "Hook not found"
Available hooks are listed in `hooks/claude/`. Add new hooks in that directory.

### "File already exists (not a symlink)"
You have a regular file, not a symlink. Remove it and reinstall:
```bash
rm ~/.claude/hooks/UserPromptSubmit
./install.sh session-hygiene-check user
```

### "Symlink broken after moving the repo"
Symlinks use absolute paths. After moving the repo, reinstall:
```bash
./install.sh session-hygiene-check user
```

### "Hook not firing"
1. Verify installation: `ls -la ~/.claude/hooks/UserPromptSubmit`
2. Check permissions: `chmod +x ~/.claude/hooks/UserPromptSubmit`
3. Verify symlink target: `readlink ~/.claude/hooks/UserPromptSubmit`
4. Check Claude Code logs for errors
