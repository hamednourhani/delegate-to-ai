# Hook Installation Guide

Install Claude Code hooks to `~/.claude/hooks/` with the provided `install.sh` script. Each user installs once on their machine.

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
./install.sh <hook-name>
```

**Arguments:**
- `<hook-name>`: Hook to install (e.g., `session-hygiene-check`)

**Example:**
```bash
./install.sh session-hygiene-check
```

## How it works

The installer:
1. **Checks for jq** — warns if missing
2. **Validates the hook** — checks if it exists
3. **Creates `~/.claude/hooks/`** — if it doesn't exist
4. **Symlinks the hook** — creates a symlink (not a copy)
5. **Registers it in `~/.claude/settings.json`** — adds a `UserPromptSubmit` entry pointing at the symlink; without this, Claude Code never invokes the hook, even though the file exists
6. **Auto-updates** — hook updates when you `git pull` this repo

## Available hooks

- `session-hygiene-check` — Auto-checkpoint every N turns to keep your model/effort/context in sync
  - [Configuration →](claude/session-hygiene-check/README.md)
  - [Design rationale →](claude/session-hygiene-check/DESIGN.md)

## Configuration

Each hook reads configuration from `~/.claude/settings.json`. See the hook's README for available settings.

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
rm ~/.claude/hooks/UserPromptSubmit
```

## Troubleshooting

### "Hook not found"
Available hooks are listed in `hooks/claude/`. Add new hooks in that directory.

### "File already exists (not a symlink)"
You have a regular file, not a symlink. Remove it and reinstall:
```bash
rm ~/.claude/hooks/UserPromptSubmit
./install.sh session-hygiene-check
```

### "Symlink broken after moving the repo"
Symlinks use absolute paths. After moving the repo, reinstall:
```bash
./install.sh session-hygiene-check
```

### "Hook not firing"
1. Verify installation: `ls -la ~/.claude/hooks/UserPromptSubmit`
2. Check permissions: `chmod +x ~/.claude/hooks/UserPromptSubmit`
3. Verify symlink target: `readlink ~/.claude/hooks/UserPromptSubmit`
4. Check Claude Code logs for errors
