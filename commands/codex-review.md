---
allowed-tools: Skill
description: "[DEPRECATED] Forwards to /codex review. Use /codex (with optional mode) directly going forward."
argument-hint: <file-path> | --repo | --recent | --staged
---

# /codex-review (deprecated)

This command is a thin compatibility wrapper. Use **`/codex review`** going forward — same behavior, plus the rest of `/codex`'s modes (`fact-check`, `verdict`, `critique`, etc.).

## What this does

Invoke the `/codex` Skill in `review` mode, forwarding `$ARGUMENTS`. Mode dispatch (file path vs. `--repo` / `--recent` / `--staged`) is now `/codex`'s responsibility.

Translate `$ARGUMENTS`:
- empty or `--repo` → `/codex review` (the skill will detect "no file paths" and review the repo)
- `--recent` → `/codex review --recent`
- `--staged` → `/codex review --staged`
- file path(s) → `/codex review <paths>`

## Why deprecated

The old `/codex-review` was scoped only to code review. The new `/codex` is a unified second-opinion entry point with explicit modes built on a clean `codex-runner` subagent that fixes the [openai/codex #20919](https://github.com/openai/codex/issues/20919) stdin-hang bug. Code review is now just one mode (`/codex review`) alongside `/codex critique`, `/codex fact-check`, `/codex verdict`, etc.

If you're reading this file: prefer `/codex review` in new uses. This wrapper exists for muscle memory and existing invocations.
