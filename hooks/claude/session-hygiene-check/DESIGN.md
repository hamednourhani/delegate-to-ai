# Design: Session Hygiene Hook

## Problem statement

Sessions drift. A developer starts with Haiku on low effort, but an hour later—after pivoting 3 times and adding context—they're still on Haiku even though the work now needs Sonnet. Or they've accumulated 100k+ tokens in context and don't realize it's slowing them down.

These aren't errors; they're drift. The setup was right at turn 1, but it's not right at turn 47.

**Current solution**: Manual (`/model`, `/effort`, `/compact` commands). Works, but requires the developer to notice and act.

## Solution: Automated periodic checkpoint

Fire a UserPromptSubmit hook every N turns or M minutes. The hook:
1. Reads the transcript to get **actual model used** and **actual token count**
2. Compares against thresholds
3. Injects a verdict suggesting what to do (or nothing, if all is well)

## Why this design?

### Why periodic, not on-demand?

Drift is **silent**. You won't call `/advisor` if you don't realize the setup is stale. Periodic nags catch things you'd miss.

### Why these thresholds?

- **10 turns**: ~5–10 minutes of typical work. Often enough to catch pivots, infrequent enough not to be noise.
- **10 minutes**: Fallback if you're in a very focused session (few turns per minute). Ensures the hook fires at least every 20 min.
- **120k tokens**: Point at which context starts noticeably slowing down Claude's reasoning. Below that, you're usually fine.

Teams with different workflows can tune these (see CONFIG.md).

### Why read from transcript, not settings?

Settings carry what you *configured*. The transcript carries what *actually happened*. They can differ:
- You set `model: sonnet` but Claude Code selected Haiku due to your session config
- Token count is live; context-token threshold is static

The transcript is the source of truth.

### Why UserPromptSubmit (not other hooks)?

- Fires just before you submit a message → checkpoint is fresh
- Doesn't spam your stdout (silent unless it needs to talk)
- Can inject a system message into the chat without disrupting your flow

Alternative: SystemStart (once per session) — too infrequent. Alternative: OnToolCall (every tool) — too noisy.

## Trade-offs

### Pro: Catches drift automatically
- You don't have to remember to check
- Works across all projects equally

### Con: Adds latency to the hook chain
- Hook does jq parsing, reads transcript, resolves settings
- ~100–200ms per check (negligible, but measurable)

### Con: Settings can lag live `/effort` switch
- You run `/effort high` but settings haven't persisted yet
- Hook reads the *persisted* effort level, not the live one
- Workaround: The hook acknowledges this in its message ("effort level may lag")

### Con: May feel like noise if thresholds aren't tuned
- If you check often and the work is always right, it's a nag
- Solution: Team documents good threshold defaults per task type

## Future improvements

- [ ] Read *live* effort level from the session (not just persisted settings)
- [ ] Suggest context-splitting strategies ("your context is 150k; consider /compact")
- [ ] Track model history ("you've switched models 4 times in 30 min; consider a pause")
- [ ] Let teams define custom verdicts (e.g., "escalate to Opus if context > 80k and error rate > 5%")

## Why not just use `/advisor`?

**advisor**: Deep, manual, thorough. You call it before major decisions.

**session-hygiene-check**: Shallow, automatic, frequent. Catches small drifts before they compound.

They're complementary, not competing.
