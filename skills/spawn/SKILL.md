---
name: spawn
description: Spin up a day's worth of git worktrees and Claude Code sessions in parallel — one per workstream. Two modes (a) **direct**: user provides slugs, skill creates worktrees + tmux session. (b) **discovery**: user describes a vague goal ("build a cribbage game"), skill asks 1-3 clarifying questions, proposes workstreams, has Codex sanity-check the decomposition, confirms, then spawns. Each spawned worktree gets a BRIEF.md with starter tasks (including a built-in /codex-review pass on initial design), and each tmux window auto-launches Claude with an initial prompt that reads BRIEF.md and proposes a task list before starting work. Supports greenfield (offers `git init`) and existing repos. Use when user says "spin up worktrees for X, Y, Z", "start my day with N tasks", "spawn tasks for [list]", "set up my parallel work", "build [vague-goal]", or invokes /spawn explicitly with anything resembling a goal description.
---

# spawn — set up a day of parallel work

The user wants to work on multiple things today, each in its own isolated git
worktree with its own Claude Code session. This skill creates the worktrees,
spins up a tmux session with one Claude per workstream, briefs each session
on what to work on, and gets out of the way.

Design principle this skill bakes in: **codex-review the plan up front,
not at the end.** That happens at two layers — once when proposing the
workstream decomposition, and again as the first task inside each worktree.

## When to use

- User invokes `/spawn` explicitly (with slugs, with a goal, or with no args).
- User says "spin up worktrees for [list]" or "start my day with these tasks".
- User says "build [vague goal]" — discovery mode.
- User wants parallel-task isolation.

## When NOT to use

- Single task — just work on it normally.
- User is asking *how* to do this (explain instead of executing).
- User explicitly says they want to drive the worktree creation themselves.

## Mode detection

Inspect the user's args:

- **Direct mode** — args are all valid slugs (`[a-z0-9-]+`, no spaces in
  individual args, looks like a list): `/spawn auth s3migrate chart-fix`.
  Skip discovery, go straight to spawn.
- **Discovery mode** — args contain natural language, or there are zero args:
  `/spawn build a cribbage game for my family`. Run the discovery flow.
- **Greenfield** — orthogonal to mode; detected by absence of a git repo at
  the working directory. Trigger the bootstrap flow before either mode
  proceeds.

## Greenfield bootstrap (only if not in a git repo)

If `git rev-parse --show-toplevel` fails:

1. Confirm with the user: "You're not in a git repo. Want me to create one
   here, or somewhere else?"
2. If yes: `mkdir <project>` (if needed), `cd <project>`, `git init`.
3. Write a minimal `README.md` capturing the project goal in 2-3 sentences
   (use the goal text the user provided).
4. `git add README.md && git commit -m "init"`.
5. Create a `dev` branch from this initial commit: `git checkout -b dev`.
6. Set the working directory to this new repo. Continue to discovery mode.

Do **not** scaffold a package.json / pyproject.toml / build tooling — let
each workstream's spawned Claude session pick the right scaffold for its
slice. The bootstrap is intentionally minimal: a git repo with one commit
that says what we're building.

## Discovery mode flow

Used when the user describes a goal rather than handing over slugs.

### Step 1 — Clarifying questions (max 3, ideally 1-2)

Ask only what's load-bearing for choosing workstreams. Common candidates:

- Platform: web / desktop / mobile / CLI / library?
- Audience: solo personal use / small group / general public?
- Tech preference: opinionated stack from user, or skill picks?
- Scope cutoff: MVP-only or full-featured?

**Skip questions whose answers are obvious from context.** If the user said
"build a cribbage game for my family", you already know audience is
small-group; don't ask. If they said "build a CLI tool to rename files",
you already know platform is CLI; don't ask.

### Step 2 — Propose workstreams (4-7 max)

For each workstream, name:

- **Slug** (1-2 word hyphenated, lowercase): `core-rules`, `ui-cards`, `ai-opponent`
- **Scope**: one sentence on what this workstream owns
- **Estimated task count**: rough number, helps user judge size
- **Dependencies**: which other workstreams (if any) must have a usable
  surface area before this one can make real progress

Order workstreams so foundation ones (no deps) come first. Surface anything
that's *not* parallelizable today and recommend deferring it.

### Step 3 — Codex sanity-check the decomposition

Before spawning anything, run a single pass of `/codex review` (or use the
`codex-runner` agent directly) on the proposed workstream
decomposition. Ask Codex to flag:

- Workstreams that have hidden overlaps (will fight over the same files).
- Workstreams that are too vaguely scoped to fit in a session.
- Workstreams the user is missing entirely.
- Workstreams that should be combined.

Apply Codex's feedback to the proposal. If Codex pushes back hard on the
decomposition, surface that to the user and reach alignment before spawning.

**Why up front**: spawning 4 worktrees and 4 Claude sessions on a flawed
decomposition wastes 4 sessions, not 1. Codex's sanity-check at this layer
is the cheapest place to catch structural problems.

### Step 4 — Confirm with the user

Show the (Codex-refined) workstream list. Ask:

- Spawn all of these, or a subset?
- Any renames, scope changes, or additions?

Wait for explicit confirmation. **Don't spawn until the user says go.**

### Step 5 — Write BRIEF.md per worktree

Before spawning tmux, create each worktree (next section) and write a
`BRIEF.md` file at its root with:

- **Workstream name**: full sentence describing the scope.
- **Why this exists**: 1-2 sentences on how this fits the larger project.
- **Dependencies**: which other workstreams' surface area you'll consume.
- **Initial task list** (3-7 tasks), starting with:
  1. **`/codex-review the initial design before deep work`** — always task 1.
     Have Codex sanity-check whatever architecture decisions the session is
     about to commit to. Cheap, catches expensive mistakes.
  2. Set up scaffolding (deps, file structure) needed for this workstream.
  3. Implement first vertical slice.
  4. Tests for that slice.
  5. (Continue as makes sense.)
- **Definition of done**: how this Claude session knows it's complete and
  ready for PR.

Add `BRIEF.md` to `.gitignore` (or write a project-level `.gitignore` if
absent) — these are working notes, not committed artifacts.

## Direct mode flow

When the user provides slugs directly, skip the interview and codex-review
of decomposition. Don't write BRIEF.md — direct mode assumes the user
already knows what each slug means.

Optionally offer: "Want me to also write BRIEF.md scaffolds for these?
That'd take a sentence per slug from you on what each one is for." If they
say yes, drop into a mini-discovery for those slugs and produce briefs.

## Worktree creation (both modes)

Execute these in order. **Stop and surface any failure** — do not
partial-spawn.

### Validate environment

- `git rev-parse --show-toplevel` to get repo root.
- `basename` of root for the prefix used in worktree paths.
- Resolve the base branch in this order:
  1. `--base <ref>` flag from the command line if present
  2. `base_ref` in `~/.spawn-config.json` if set
  3. `git rev-parse --verify origin/dev` (try `dev` if no remote)
  4. `git rev-parse --verify origin/main` (try `main` if no remote)
  5. Current `HEAD`
  Abort and tell the user if none resolve to a valid ref.
- `which tmux` and `which claude` — if either missing, abort.

### Refresh remote refs

`git fetch origin` so each worktree starts from latest. Don't switch the
current branch. Skip silently if no `origin` remote exists.

### Create the worktrees

For each slug:
- Path: `../<repo>-<slug>`
- Branch: `<branch-prefix>/<slug>` (default `feat/`, overridable via `--branch-prefix` or config)
- Source: resolved `<base-ref>` (see above)
- Command: `git worktree add ../<repo>-<slug> -b <branch-prefix>/<slug> <base-ref>`

If a worktree already exists at the path, warn and skip — don't overwrite.
If the branch exists but no worktree, abort.

### Write BRIEF.md (discovery mode only)

For each worktree, write its BRIEF.md (per the schema in Step 5 above).

## Spawn tmux session with auto-started Claude sessions

The key: each window auto-launches `claude` with an initial prompt that
tells it what to do, so the user doesn't have to type anything when they
attach.

```bash
# Kill any previous session named the same thing
tmux kill-session -t <session-name> 2>/dev/null

# Pick session name: "day" by default, or the project name in greenfield mode
SESSION="day"

# First window
tmux new-session -d -s "$SESSION" -n "<first-slug>" -c "../<repo>-<first-slug>" \
  "claude 'Read BRIEF.md in the current directory. Propose a task list using TaskCreate that matches the BRIEF, then run /codex-review on your proposed plan before doing any implementation work. Pause for my approval after Codex returns.'"

# Remaining windows
for slug in <remaining-slugs>; do
  tmux new-window -t "$SESSION" -n "$slug" -c "../<repo>-$slug" \
    "claude 'Read BRIEF.md in the current directory. Propose a task list using TaskCreate that matches the BRIEF, then run /codex-review on your proposed plan before doing any implementation work. Pause for my approval after Codex returns.'"
done
```

The `-d` flag is critical — keeps the session detached so this Claude
session (the one running /spawn) doesn't get hijacked.

**Direct mode without BRIEF.md**: drop the "Read BRIEF.md" instruction. The
initial prompt becomes just `claude "I'm working on <slug>. Wait for me to brief you."`

**Verify `claude` accepts a positional initial prompt**: if it doesn't on
the user's version, fall back to the tmux send-keys approach:
```bash
tmux new-window -t "$SESSION" -n "$slug" -c "../<repo>-$slug" claude
sleep 3
tmux send-keys -t "$SESSION:$slug" "Read BRIEF.md..." Enter
```
The sleep is fragile; test first. Prefer the positional-arg form when
available.

## Report to user

After spawning, output a single block:

1. List of worktrees created (path + branch + brief status). For each, note
   whether BRIEF.md was written.
2. The attach command on its own line: `tmux attach -t <session-name>`
3. A one-line summary of what each Claude session will do when attached
   (e.g., "auth: will read BRIEF.md, propose tasks, run /codex-review, pause
   for your approval.")
4. The tmux cheat sheet below.
5. The memory-isolation caveat below.

## tmux cheat sheet to print

```
=== tmux quickref ===
tmux attach -t <session>      attach to the session
Ctrl-b n / p                  next / previous window
Ctrl-b <0-9>                  jump to window N
Ctrl-b d                      detach (session keeps running)
Ctrl-b ,                      rename current window
Ctrl-b w                      list windows (arrow keys + enter)
tmux kill-session -t <session>  end the session

Ctrl-b means "press and release Ctrl-b, THEN the next key" —
it's a two-key sequence, not a chord.
```

## Memory-isolation caveat to print

```
Each worktree has a different absolute path, so Claude's auto-memory keys
them as separate projects. Memories from the main repo session won't
auto-load in worktree sessions — they'll build their own context. If you
want shared memory across worktrees, symlink the memory dir; ask Claude
when you're ready.
```

## Cleanup (separate concern)

This skill does NOT clean up. To remove worktrees:
- `git worktree list` to see what's live
- `git worktree remove <path>` for each one done
- `git worktree prune` to tidy stale entries
- Or ask Claude to "clean up merged worktrees"

## Edge cases

- **Dirty working tree in the main repo**: worktrees don't care — they're independent checkouts. Spawn anyway.
- **Slug collision with existing branch**: abort and tell user. Don't auto-rename.
- **Spaces in slugs (direct mode)**: reject — slugs must be `[a-z0-9-]+` only.
- **Repo not on a remote**: fall back to local `dev`; skip `fetch`.
- **Already inside a worktree**: still works — `git worktree add` uses the main repo by default.
- **`claude` not on PATH inside the worktree shell**: tmux will spawn a window that immediately exits. Check `which claude` before spawning. If missing, abort.
- **User declines codex-review of decomposition** ("just spawn it"): respect that, but flag once: "OK, skipping codex sanity-check on the decomposition. Each worktree's BRIEF.md will still include /codex-review as task 1." If they decline that too, drop it entirely.

## Quality checks before reporting success

- `git worktree list` shows each new worktree.
- `tmux ls` shows the session with the expected number of windows.
- Each window name matches its slug.
- BRIEF.md exists in each worktree (discovery mode only).

If any check fails, surface the discrepancy — don't silently report
success.
