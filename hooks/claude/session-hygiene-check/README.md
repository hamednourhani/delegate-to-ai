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

## How it works

When the threshold is crossed:
1. **Hook runs** — reads your transcript, model, effort, and context size
2. **systemMessage injected** — Claude Code adds a summary line visible in chat
3. **additionalContext injected** — Claude Code adds detailed guidelines as a system prompt
4. **Claude responds** — reads both, evaluates your current setup, and gives a verdict

The LLM decides what to say based on the guidelines (switch to Haiku, raise effort, compact, etc.).

### Under the hood (for engineers)

The hook outputs JSON that Claude Code uses to inject the checkpoint:

```json
{
  "systemMessage": "🧭 Session hygiene check: 10 turns / 0m since last checkpoint (model=..., effort=low, context=~... tokens). See chat for a recommendation.",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "SESSION HYGIENE CHECKPOINT (auto-injected, not from the user): 10 turns / 0 min have passed since the last checkpoint...\n\nBefore responding to the latest user message, take one or two sentences to size up whether the current setup still fits the work..."
  }
}
```

**What Claude Code does:**
- `systemMessage` → shown in chat as a one-liner
- `additionalContext` → sent as a system prompt to guide Claude's response
- Claude reads both and decides what verdict to give based on the guidelines

## Example messages

**Scenario 1: Simple work on Opus**

```
🧭 Session hygiene check: 10 turns / 10m since last checkpoint (model=claude-opus-4-8, effort=low, context=~25000 tokens). See chat for a recommendation.
```

Claude's response:
```
You're doing mechanical reads and edits on Opus—that's overkill. Switch to Haiku (/model haiku) and save tokens.
```

**Scenario 2: Stuck in loops, context fine**

```
🧭 Session hygiene check: 15 turns / 8m since last checkpoint (model=claude-haiku-4-5, effort=low, context=~45000 tokens). See chat for a recommendation.
```

Claude's response:
```
You've re-explained the same error three times now. The model or effort might be underpowered. Try /effort high or switch to a stronger model.
```

**Scenario 3: Context creeping up**

```
🧭 Session hygiene check: 8 turns / 12m since last checkpoint (model=claude-opus-4-8, effort=medium, context=~125000 tokens). See chat for a recommendation.
```

Claude's response:
```
Context is over 120k tokens. Run /compact to summarize and move on faster.
```

**Scenario 4: All good**

```
🧭 Session hygiene check: 10 turns / 10m since last checkpoint (model=claude-opus-4-8, effort=medium, context=~55000 tokens). See chat for a recommendation.
```

Claude's response:
```
Setup is working well. Keep going.
```

## Testing

Test the hook directly without waiting for a real session:

```bash
# Simulate a checkpoint firing
echo '{"session_id": "test", "cwd": ".", "prompt": "test", "transcript_path": "/dev/null"}' | ~/.claude/hooks/UserPromptSubmit
```

Output shows the exact JSON the hook sends to Claude Code:

```json
{
  "systemMessage": "🧭 Session hygiene check: 10 turns / 0m since last checkpoint...",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "SESSION HYGIENE CHECKPOINT...\n\nBefore responding..."
  }
}
```

The `systemMessage` appears in your chat. The `additionalContext` guides Claude's response.

## What thresholds should I use?

- **Exploratory/research work**: Lower turn threshold (5–7), keeps you checking if the model fits
- **Implementation/coding**: Default (10) is fine, you probably want to stay focused
- **Chunky context jobs**: Higher context threshold (150k+) if you need to accumulate lots of context before compacting
- **Quick tasks**: Higher minute threshold (20+), don't nag as often

Experiment and see what keeps you sane without becoming noise.

## Troubleshooting

### Hook doesn't fire

- Check it's installed: `ls -la ~/.claude/hooks/UserPromptSubmit`
- Verify symlink is valid: `readlink ~/.claude/hooks/UserPromptSubmit`
- Check execute permissions: `chmod +x ~/.claude/hooks/UserPromptSubmit`
- Check Claude Code logs for hook errors

### Settings not being read

- Make sure `sessionHygiene` is at the top level of `~/.claude/settings.json`
- Verify JSON is valid: `jq . ~/.claude/settings.json`
- Restart Claude Code after changing settings

## Design notes

See `DESIGN.md` for why this hook works the way it does, trade-offs, and potential improvements.
