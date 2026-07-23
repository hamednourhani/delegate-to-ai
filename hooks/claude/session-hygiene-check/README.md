# Session Hygiene Hook

Auto-checkpoint every N turns/M minutes to keep your model, effort level, and context size in sync with the work you're doing.

## What it does

Fires periodically (every 10 turns or 10 minutes by default) and injects a quick verdict:
- **Switch to Haiku?** If you're doing simple/mechanical work on a big model
- **Raise effort?** If you're stuck in loops and underpowered
- **Compact context?** If context size is creeping up
- **All good?** If setup still fits, move on

Reads live from your transcript: actual model used, actual token count. No guessing.

## Why this exists

Sessions drift. You stay on Sonnet when Haiku would do. You keep a bloated context when it's slowing you down. You don't notice you're stuck in a loop until much later.

This hook catches drift by asking periodically: "Is your current setup still right?"

## Installation

From the `hooks/` directory, run:

```bash
./install.sh session-hygiene-check
```

This installs to `~/.claude/hooks/UserPromptSubmit` and runs for all your Claude Code sessions.

See [../INSTALL.md](../INSTALL.md) for detailed instructions and troubleshooting.

## Configuration

### Default thresholds

```
TURN_THRESHOLD=10          # Fire every N turns
MINUTES_THRESHOLD=10       # Or every M minutes (whichever comes first)
CONTEXT_TOKEN_THRESHOLD=120000  # Recommend /compact if over this
```

### Change thresholds

Add to `~/.claude/settings.json`:

```json
{
  "sessionHygiene": {
    "turnThreshold": 10,
    "minuteThreshold": 10,
    "contextTokenThreshold": 120000
  }
}
```

## How to read the checkpoint

When the hook fires, you'll see something like:

```
🧭 Session hygiene check: 10 turns / 10m since last checkpoint (model=claude-sonnet-4, effort=low, context=~85000 tokens). See chat for a recommendation.
```

Then in the chat, a longer verdict explaining what to do (if anything).

## What thresholds should I use?

- **Exploratory/research work**: Lower turn threshold (5–7), keeps you checking if the model fits
- **Implementation/coding**: Default (10) is fine, you probably want to stay focused
- **Chunky context jobs**: Higher context threshold (150k+) if you need to accumulate lots of context before compacting
- **Quick tasks**: Higher minute threshold (20+), don't nag as often

Experiment and see what keeps you sane without becoming noise.

## Troubleshooting

### Hook doesn't fire

- Check it's copied to `~/.claude/hooks/UserPromptSubmit` (user-wide) or `.claude/hooks/UserPromptSubmit` (project)
- Verify it has execute permissions: `chmod +x ~/.claude/hooks/UserPromptSubmit`
- Check Claude Code logs for hook errors

### Settings not being read

- Make sure `sessionHygiene` is at the top level of `.claude/settings.json`, not nested under something else
- Project settings (`.claude/settings.json`) override user settings (`~/.claude/settings.json`)
- Restart Claude Code after changing settings

## Design notes

See `DESIGN.md` for why this hook works the way it does, trade-offs, and potential improvements.
