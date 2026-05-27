# /spawn — learnings from a greenfield stress-test

> Captured 2026-05-26, from running `/spawn` on a from-scratch build ("make a
> cribbage game") to see where it holds and where it breaks. The cribbage repo
> was disposable; these conclusions are the keep. Reviewed with Codex throughout.

## 1. Scope — what `/spawn` is actually for

`/spawn`'s core assumption is **independent worktrees**: N branches that don't
fight over the same files. Its real sweet spot is **an existing repo with
scaffolding already in place + several file-disjoint features/fixes** — "5 things
to push today, work each individually." Isolation is free because the work is
disjoint; merge-back is conflict-free.

**A vague greenfield goal violates that assumption.** Decomposing "build a
cribbage game" produced streams that all wanted to share one scaffold, one
`package.json`/lockfile, one set of domain types, the same `App.tsx`. Codex
flagged it on the first review: those weren't 5 parallel streams, they were a
dependency graph. We folded 5 → 3 and hand-built a scaffold + contract before
anything could run in parallel. **Greenfield is a planning problem first; the
worktree+tmux machinery only earns its keep once streams are genuinely
independent.** `/spawn`'s discovery mode papers over this — it'll decompose any
goal, but for greenfield the decomposition is almost always coupled.

## 2. The greenfield front-end pipeline (use before `/spawn`, not instead of it)

```
/seed                   -> SPEC.md (what, rules, scope)
converge (Claude+Codex) -> ONE hard pass on decomposition + ownership map +
                           frozen shared contract. NOT per-workstream converge —
                           coupling lives in the SEAM between streams, so
                           reviewing isolated stream plans is false comfort.
prove the seam          -> real shared types + a MINIMAL REAL foundation slice +
                           contract tests + fixtures, committed to the base
                           branch. A frozen DOC is weak; executable examples stop
                           N agents each drifting a slightly-different-wrong way.
spawn                   -> the now-genuinely-independent streams, against a REAL
                           seam (not stubbed throws).
```

The highest-leverage place to spend up-front review is the **architecture**
(decomposition, contracts, ownership, integration order), proven executably.
This pipeline ends by *calling* the spawn step — it doesn't replace `/spawn`.

## 3. Vertical slices beat layer decomposition for greenfield

Splitting by layer (`core` / `ui` / `ai`) maximizes *simultaneous live seams* —
every stream needs the engine contract at once. Splitting by **playable
capability** (deal+render+discard → pegging → show → game-to-121) keeps one
seam open at a time; each slice closes end-to-end before the next opens. Fewer
concurrent seams → less coordination → the isolation-vs-coordination tension
mostly dissolves. Sacrifices clean subtree purity, usually wins on greenfield.

## 4. Worktrees, not Agent Teams, for shared-file work

- **Subagents** (Task/Agent tool): ephemeral, hierarchical, one-shot,
  report-to-parent-only. No peer comms, no persistence. Don't address
  cross-session coordination.
- **Agent Teams** (experimental, env-gated): persistent peers, shared task list
  + mailbox + idle/task hooks. Would solve coordination — but **does NOT isolate
  file edits** (two teammates editing one file clobber each other), which is the
  whole reason to use worktrees.
- **Worktree + tmux** (what `/spawn` does): peer-like with the *strongest*
  isolation (separate git checkouts), but **zero shared state** — the
  coordination gap.

Right trade: keep worktree isolation; borrow Team *ideas* (a coordinating lead /
"steward", a shared task board, an escalation channel) via a contract + a
human-ish steward, not by adopting Teams. Re-evaluate when Teams leaves
experimental AND fixes file isolation. See `FUTURE-coordination-layer.md`.

## 5. Portability (Mason runs Mac zsh + Windows-via-WSL bash)

- **Prefer the native primitive `claude --worktree [name] [--tmux]`** (verified
  on `claude 2.1.150`; `--tmux` uses iTerm2 native panes when available,
  `--tmux=classic` otherwise). It abstracts per-OS pane mechanics and is the
  portable replacement for hand-rolled `git worktree add` + tmux splits.
- The **`osascript` auto-open-a-Terminal-window trick is Mac-only** — do NOT
  bake it into reusable tooling. Native `--tmux` supersedes it for reuse.
- Both machines are POSIX, so bash + git worktrees + tmux + the profile
  functions behave identically; no platform branching needed in the tooling.

## 6. Crossover / shared-config discipline (the coupled case)

- Topology: **`dev` is the hub.** Every worktree forks from and merges back to
  `dev`; worktrees never merge into each other. One integration trunk, not a mesh.
- File-ownership map partitions streams into their own subtrees → merge-back
  conflicts are rare by construction. The only real conflict surface is shared
  config.
- **Don't let a branch edit shared config** (root `package.json`/lockfile/
  `tsconfig`/`vite.config`) — "additive" edits are how worktrees rot into
  lockfile roulette. A blocked stream **escalates**; a steward lands the change
  on `dev`; everyone rebases at checkpoints (batched, not continuous).
- **Contract rework propagation**: land it on `dev` once → `git rebase dev` in
  each worktree → **TypeScript compile errors are the propagation mechanism**
  (they light up exactly the consumers that must change; nothing drifts
  silently) → poke each agent with a one-line summary. Breaking reworks are paid
  once per live stream, so batch them to checkpoints.

## Operational notes that worked

- **codex-review the decomposition UP FRONT**, before spawning — a flawed cut
  wastes N sessions, not 1. (Already in SKILL.md; the test confirmed its value —
  it's what caught the 5→3 fold.)
- Launch each pane with `claude '<initial prompt>'` (positional prompt works on
  2.1.150) so sessions self-brief on attach.
- Confirm panes actually launched with `tmux capture-pane -p` before reporting
  success — and you can *track* a pane's progress the same way (it screen-scrapes
  the rendered text; it's a pull snapshot, not a live feed).
- `tmux send-keys -t <session>:<pane> "<msg>" Enter` injects a message into a
  running pane's Claude — usable as a manual lead→stream poke, but see the FUTURE
  doc: do NOT build signaling on it (fragile: wrong pane / dead session /
  injected mid-edit). Poll a shared board instead.
