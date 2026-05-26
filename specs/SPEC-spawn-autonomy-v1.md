# SPEC — `/spawn --autonomy=auto` v1

**Status**: locked, ready to build. Converged with Codex over 4 rounds (2026-05-25).
**Owner**: Mason (skill author). **Audience**: any developer using `/spawn`.
**Author**: synthesized by Claude with grounding from Codex research + community sources.

## Motivation

`/spawn` already creates parallel git worktrees with one interactive Claude
session per workstream. It works, but each session pauses for permission on
most things, and the user has to actively tend N tmux windows.

Goal of `--autonomy=auto`: each spawned Claude works as independently as
safely possible and pings the user via ntfy push **only when human input is
genuinely needed**. The user should be able to set up their day in the morning,
go do something else, and trust that the loop will surface what matters and
ignore what doesn't.

The design grounding is independent research (see §References) plus two
rounds of Codex review during the design phase. This spec is what we
believe is *minimum-viable autonomy* — not a kitchen sink, not what the
ambitious version becomes in v2.

## Out of scope (defer to v2 unless v1 reveals need)

- MCP ntfy server (curl shell-out is fine)
- Bundling autonomous loop into `/spawn` itself
- Inter-agent direct messaging (file-based only)
- Docker / container isolation (worktrees are sufficient)
- ntfy typed replies (clunky on mobile)
- Cross-worktree memory symlinking
- More than 4 parallel agents (warn at 5, hard-cap at 7)
- Daily-summary in any form (deferred to v1.1 alongside watchdog — current workflow is augmented-with-ntfy, not unattended-overnight)
- Custom WorktreeCreate hooks for branch naming (manual `git worktree add` for v1)
- Native `claude --worktree` integration (worktree layout under `.claude/worktrees/` is fine for native, but the skill wants configurable branch naming off a configurable base — typically `feat/<slug>` off `origin/dev` or `origin/main` — which native doesn't give us cleanly; manual `git worktree add` keeps full control)

## The two autonomy levels

Not four. Not a spectrum. Two states:

| Flag | Behavior |
|---|---|
| `--autonomy=interactive` (default) | Today's `/spawn` behavior. Each spawned Claude asks before risky ops. the user watches tmux windows. |
| `--autonomy=auto` | Hooks armed, `--dangerously-skip-permissions` on the spawned `claude` invocation, ntfy push for escalations, polling for answers. `status/<slug>.md` mtime is the "alive" signal; the user watches ntfy. |

Once you've decided the agent can act unattended, what varies is **which
guardrails are armed** — and guardrails belong in config files, not flag
gradients.

## Directory layout

```
~/work/<project>/                # parent dir, NOT a git checkout
├── main/                        # canonical checkout, branch=dev (or main)
├── <repo>-<slug>/               # worktree per workstream, sibling of main
│   ├── BRIEF.md                 # workstream charter + decision policy
│   ├── .claude/
│   │   ├── settings.json        # hooks armed + deny list
│   │   └── hooks/               # the actual hook scripts
│   │       ├── enforce-isolation.sh
│   │       ├── ntfy-on-failure.sh
│   │       ├── cost-ceiling.sh
│   │       └── smoke-test.sh
│   ├── bin/
│   │   └── ntfy_send            # bash wrapper: curl against ntfy.sh/<topic>
│   ├── .agent_id                # agent_<ts>_<random4>
│   ├── .ntfy_topic              # <ntfy-prefix>-spawn-<agent_id>
│   ├── .ntfy_outbox/            # local queue if ntfy POST fails (network-down)
│   ├── BLOCKED.md               # written ONLY when agent escalates
│   └── (the actual code)
└── COORDINATION/                # shared state, gitignored at project level
    ├── PLAN.md                  # decomposition; written once by /spawn
    ├── MERGE_PLAN.md            # merge order + expected conflict surface
    ├── status/                  # one file per workstream, that workstream writes
    │   ├── 01-routing.md
    │   ├── 02-schema.md
    │   └── ...
    ├── decisions/               # timestamp-slug filenames, append-only
    ├── questions/               # outbound from agents, the user answers
    │   ├── 001-routing-auth-shape.md          # pending
    │   ├── 001-routing-auth-shape-ANSWERED.md # the user replies by writing this
    │   └── ...
    ├── events/                  # one file per significant event
    └── locks/                   # active_work_registry.json + per-agent tool-call counters
```

**Key invariants**:

- Each workstream writes to exactly one file in `status/` (its own slug).
  No race.
- `decisions/` and `questions/` use timestamp-slug filenames so concurrent
  writes create distinct files.
- `events/` is one-file-per-event (no flock).
- Branch naming: `<branch-prefix>/<slug>` (default `feat/`) off `<base-ref>`
  (default: `origin/dev` if exists, else `origin/main`, else `HEAD`). Both
  configurable via `~/.spawn-config.json` or `--base` / `--branch-prefix`
  flags. NOT the native `worktree-<slug>` off `origin/HEAD`.
- **No heartbeat/watchdog in v1.** At ≤4 worktrees on the user's laptop,
  eyeballs + `status/<slug>.md` mtimes substitute. Move to v1.1 when the user
  starts walking away overnight.

## Per-workstream setup (what `/spawn --autonomy=auto` actually does)

For each chosen slug, in order:

1. **Generate `agent_id`** = `agent_<unix-timestamp>_<4-random-chars>` and
   `ntfy_topic` = `<ntfy-prefix>-spawn-<agent_id>` (14+ chars, effectively
   unguessable). Hold in memory; written to disk after worktree creation.

2. **Create the worktree**:
   `git worktree add ../<repo>-<slug> -b <branch-prefix>/<slug> <base-ref>`
   
   Where `<branch-prefix>` (default `feat`) and `<base-ref>` (auto-detected: `origin/dev` if it exists, else `origin/main`, else `HEAD`) come from `~/.spawn-config.json` or `--base`/`--branch-prefix` flags.

3. **Write `.agent_id` and `.ntfy_topic`** to the new worktree root.

4. **Copy templates from skill into worktree**:
   - `.claude/settings.json` (hooks + deny list, paths anchored to `$CLAUDE_PROJECT_DIR`)
   - `.claude/hooks/enforce-isolation.sh` (reads stdin JSON, checks file_path under worktree root, exit 2 to block)
   - `.claude/hooks/ntfy-on-failure.sh` (reads stdin JSON, fires `ntfy_send` on non-zero exit for matching commands)
   - `.claude/hooks/cost-ceiling.sh` (reads stdin JSON, increments counter, warns at K1=80, blocks at K2=120, latches until git commit)
   - `.claude/hooks/smoke-test.sh` (runs on agent boot — see §Smoke-test below)
   - `bin/ntfy_send` (curl wrapper against `https://ntfy.sh/$NTFY_TOPIC`)

5. **Write `BRIEF.md`** (see §BRIEF.md schema below).

6. **Write the `COORDINATION/status/<slug>.md` seed file** with
   `phase: not-started`, `last_update: <iso-ts>`, `blocked_on: null`.

7. **Spawn the tmux window** running:
   ```
   claude --dangerously-skip-permissions "<initial prompt>"
   ```
   where `<initial prompt>` includes: read BRIEF.md, run smoke-test, propose
   task list via TaskCreate, run /codex-review on the plan, then start
   working autonomously per the BRIEF's decision policy.

## BRIEF.md schema

```markdown
# BRIEF — <NN-slug>: <one-line scope>

You are workstream **<NN-slug>**, one of **N** parallel workstreams executing
`COORDINATION/PLAN.md`. Read `../COORDINATION/PLAN.md` now.

**Agent ID**: <agent_id>
**ntfy topic**: $NTFY_TOPIC (set in env)

## Your scope
<paragraph>

## Sibling workstreams
- 01-<slug>: <scope> [depends_on: ...]
- 02-<slug>: <scope> [depends_on: ...]
- ...

## You depend on
- <slug>'s public surface in `<path>` (check `../COORDINATION/status/<slug>.md`
  for `public_surface:` before relying on it)

## Files Codex should be given for review
- `<entrypoint>`
- `<shared types>`
- `<cross-workstream contracts>`

## Decision policy (4 axes)

Decide alone if **all four** are true:
- **Confidence**: you're not uncertain about the right call
- **Permission**: action is reversible and inside this worktree
- **Conflict**: no contradictory signals from sibling workstreams
- **Capability**: task is inside your scope above

Otherwise, **escalate**:
1. Write `BLOCKED.md` in this worktree with the one-paragraph "why I'm stuck"
2. Write a question file at `../COORDINATION/questions/<NNN>-<slug>-<topic>.md`
3. `ntfy_send 4 "[<slug>] <one-line summary>" "$(cat BLOCKED.md | head -20)"`
4. Update `status/<slug>.md` with `blocked_on: <question-id>`
5. Continue any unblocked sub-task. If nothing → idle and poll for answer.

## Initial task list (Task 1 is non-negotiable)

1. **Run `/codex-review` on the initial design** before deep implementation work
2. Run `bash .claude/hooks/smoke-test.sh` to verify hooks fire (it should
   confirm a deny on a test out-of-scope write)
3. (workstream-specific tasks 3-7)

## Coordination cadence

- **Status updates**: write `../COORDINATION/status/<slug>.md` on phase
  transitions (scaffolding → first slice → tests → polish → ready-for-merge).
  Status file mtime is the user's "is this agent alive?" signal in v1.
- **Decisions**: when you commit to an architectural choice that affects
  siblings, write `../COORDINATION/decisions/<iso-ts>-<slug>-<topic>.md`
- **Events**: significant moments → `../COORDINATION/events/<iso-ts>-<slug>-<type>.md`
  (one file per event, no flock needed)

## How to check for answers

When blocked, run:
`/loop 2m --max-iterations=60 "ls ../COORDINATION/questions/*-ANSWERED.md 2>/dev/null"`

The 60-iter cap = 2 hours of polling. After that, escalate via ntfy with
priority 5 and stop.

## After your FIRST commit on the first vertical slice

Run `/codex-review` on the diff + a one-paragraph statement of which
architectural choice you actually made. This is the highest-signal
checkpoint — codex on real code, not on your plan.

## Definition of done
<criteria>

## Write-isolation reminder
You may NOT write outside this worktree EXCEPT:
- `../COORDINATION/status/<slug>.md` (only your own slug)
- new files under `../COORDINATION/{decisions,questions,events}/`
- counter file at `../COORDINATION/locks/<slug>-toolcount` (cost-ceiling hook writes this; you should not)

A PreToolUse hook enforces this. If the hook blocks you, the policy is
fail-loud: ntfy escalate, do NOT try to work around it.
```

## Safety mechanisms (all v1)

| Mechanism | What | Why |
|---|---|---|
| Write-isolation hook | `PreToolUse Write\|Edit\|MultiEdit` → reads stdin JSON, checks `file_path` under worktree root, exit 2 if not | Bounds blast radius even under `--dangerously-skip-permissions` |
| Deny list | `settings.json` permissions.deny: `Bash(rm -rf /*)`, `Bash(git push --force*)`, `Bash(git push *--force*)` | Catches the worst cases |
| ntfy-on-failure hook | `PostToolUse Bash` → check exit code + command match (pytest/npm test/tsc/alembic), fire `ntfy_send` if non-zero | Surface real failures, not every failed test |
| **Cost-ceiling hook** | `PostToolUse *` → increments counter in `COORDINATION/locks/<slug>-toolcount`. **Defaults: K1=80 (warn), K2=120 (block)** — measured in **tool calls between commits**, not tokens (tokens aren't observable from hook payloads). At K1: ntfy with priority 3. At K2: writes BLOCKED.md, exits 2 to block all subsequent tool calls, ntfy with priority 5 ONCE (latch — don't re-fire on every blocked call). **Reset**: the same hook inspects every `PostToolUse Bash` payload; if the just-completed command matches `git commit*` and exit code was 0, zero the counter and clear the latch. | **Real enforcement** of cost ceiling, not BRIEF prose. Prevents $70+ runaway loops that the agent might ignore under `--dangerously-skip-permissions`. |
| Smoke-test on boot | `.claude/hooks/smoke-test.sh` runs as agent's first action. Attempts forbidden write. If write succeeds (hook didn't fire), agent escalates immediately and pauses. | Hooks don't always fire (GH #6305); smoke-test catches that |
| `BLOCKED.md` before ntfy | Agent always writes `BLOCKED.md` in worktree BEFORE the ntfy fires. ntfy payload includes the one-line summary. | the user gets the "why" without context-switching into the worktree |
| ntfy outbox fallback | If `ntfy_send` curl fails (network down), record to `.ntfy_outbox/<iso-ts>.json` locally. Next successful `ntfy_send` flushes the outbox. | Don't lose escalations when wifi flakes |
| Stop hook (optional v1.1) | Auto-format / re-test on session end | Quality gate |

### Hook input contract

**All hooks read input from stdin as JSON**, not from env vars. Per GH
#9567 and #16564, env vars are unreliable across configs. Document this
contract in every hook script header.

### Hook root resolution

Hook scripts need to know "what's this worktree's root?" to enforce
isolation and locate the COORDINATION dir. Resolution order (every hook
script must implement this preamble identically):

1. `$CLAUDE_PROJECT_DIR` — set by the Claude Code harness, reliable when
   present.
2. Fallback: `git rev-parse --show-toplevel` from the hook's cwd.
3. If both fail, exit 2 with a stderr message — fail loud, don't run
   blind.

Do NOT trust ad-hoc env vars like `$WORKTREE_ROOT` set from the launching
shell. Per GH #9567 they come through empty in many configs.

## ntfy topic security

- Topic: `<ntfy-prefix>-spawn-<agent_id>` where:
  - `<ntfy-prefix>` is a user-namespace string from `~/.spawn-config.json` (default: derived from `$USER`, e.g. `mgrim`)
  - `agent_id` is `agent_<ts>_<4-random-chars>`
- Length: 14+ chars after the prefix
- Stored: `.ntfy_topic` in each worktree (gitignored), exported as
  `NTFY_TOPIC` env in the spawning shell so hooks inherit it
- Never use guessable names like `<prefix>-spawn-frontend` — on public ntfy.sh
  anyone can publish to a guessable topic and poison your alerts

## Composition with `/ralph`

`/spawn --autonomy=auto` sets up worktrees + autonomy guardrails. `/ralph`
is "what the agent does in the loop." These are orthogonal:

- After `/spawn --autonomy=auto` lands, the user can attach to a worktree
  window and type `/ralph` to start the autonomous task-loop within that
  worktree
- Each worktree's BRIEF.md mentions this as an option: "If the user wants you
  to ralph this, he'll tell you; otherwise work step-by-step with TaskCreate"
- We do **NOT** auto-invoke `/ralph` from the initial prompt — composition,
  not coupling

## What ships in the v1 build

Concretely the deliverables for the autonomy work session(s):

1. `/spawn` skill updates (`~/.claude/skills/spawn/SKILL.md`):
   - Add `--autonomy={interactive,auto}` flag
   - Add `--ntfy-topic <topic>` flag (or `~/.spawn-config.json` for default)
   - Discovery mode warns at 5+ slugs, hard-caps at 7
   - "Assign work by domain, not by file" added to decomposition prompt
2. `templates/.claude/settings.json` (copied into each worktree)
3. `templates/.claude/hooks/enforce-isolation.sh`
4. `templates/.claude/hooks/ntfy-on-failure.sh`
5. `templates/.claude/hooks/cost-ceiling.sh`
6. `templates/.claude/hooks/smoke-test.sh`
7. `templates/bin/ntfy_send`
8. `templates/BRIEF.md` (the schema above)
9. Documentation in `SKILL.md` describing the autonomy flow + setup notes
   (especially: don't echo from `.bashrc` because it breaks hook JSON parsing)
10. Sync to `claude-code-config/skills/spawn/` for Mac portability

### Build order

Build in this order. **First end-to-end testable artifact lands at step 5
(~90 min in), not at the end.**

| Step | Deliverable | Why this position |
|---|---|---|
| 1 | `templates/bin/ntfy_send` (curl-based) | Smallest, isolated, testable with a single curl call against your phone |
| 2 | `templates/.claude/hooks/enforce-isolation.sh` | The load-bearing safety primitive — get it right early |
| 3 | `templates/.claude/hooks/ntfy-on-failure.sh` | Uses `ntfy_send` from step 1; small enough to test in isolation |
| 4 | `templates/.claude/hooks/cost-ceiling.sh` | Same shape as failure hook; same test pattern |
| 5 | `templates/.claude/settings.json` + `templates/.claude/hooks/smoke-test.sh` | **First end-to-end testable artifact**: settings.json wires the three hooks together; smoke-test verifies they fire. Test by spawning a vanilla `claude --dangerously-skip-permissions` in a sandbox dir, watching smoke-test confirm isolation works. |
| 6 | `templates/BRIEF.md` | Now that hooks work, the prose layer becomes meaningful |
| 7 | `/spawn` skill updates (autonomy flag, ntfy topic config, slug caps) | Wires templates into the user-facing skill |
| 8 | End-to-end toy smoke: `/spawn --autonomy=auto build a tiny demo` | Real acceptance test against a throwaway project |
| 9 | Documentation in SKILL.md (setup notes, bashrc warning, etc.) | After build is proven, document what was learned |
| 10 | Sync to `claude-code-config/skills/spawn/` for Mac portability | Last — only sync proven code |

Estimated wall-clock: ~7-9 focused hours, including smoke-testing on a toy
project before declaring done.

## Acceptance criteria

`/spawn --autonomy=auto build a tiny demo project` should:

1. Run discovery, propose 3-4 workstreams, codex sanity-check, confirm.
2. Create N worktrees with hooks armed.
3. Spawn N tmux windows (no watchdog window in v1).
4. Each spawned Claude runs smoke-test, reads BRIEF, runs /codex-review,
   pauses for the user's go-ahead.
5. After go-ahead, each works autonomously, writing status updates,
   decisions.
6. When one needs input, it writes BLOCKED.md, fires ntfy with the summary,
   updates status to blocked_on, and polls for answer.
7. When the user writes `questions/<id>-ANSWERED.md`, the polling Claude reads
   it and unblocks.
8. If an agent exceeds the cost-ceiling threshold, the hook writes
   BLOCKED.md and fires ntfy automatically.
9. Each agent runs `/codex-review` after its first commit.
10. **Network-down ntfy fallback**: if curl fails on `ntfy_send`, the event
    lands in `.ntfy_outbox/`. Next successful send flushes the outbox.
    Verify by unplugging wifi during a forced escalation, then reconnecting.
11. **Bashrc pollution detection**: smoke-test detects if `~/.bashrc` is
    emitting stdout content that would break hook JSON parsing (e.g., an
    `echo "Shell ready"` on shell init). Fails loud with a fix message
    pointing at the offending line.
12. **Double-spawn idempotency**: re-running `/spawn --autonomy=auto` with
    a slug that already has a worktree aborts cleanly with a clear message
    and no partial mutations. Doesn't overwrite an in-flight worktree.

## Resolved decisions (was: open questions for the user)

1. **ntfy hosting**: Public `ntfy.sh` with random 14+ char topics. Self-hosted deferred until a client project's escalation messages would actually contain sensitive content (current messages are project shorthand like "[02-routing] auth shape question" — not secrets).
2. **Smoke-test failure mode**: Pause-and-ntfy. Agent writes BLOCKED.md, fires `ntfy_send` with priority 5 and a clear "hooks broken: <details>" message, stays in the tmux window for the user to inspect. Same behavior for bashrc pollution detection (acceptance criterion #11).

(Daily summary was a third resolved question — cut from v1, see Out of scope.)

## References

- [Dicklesworthstone/claude_code_agent_farm](https://github.com/Dicklesworthstone/claude_code_agent_farm)
- [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks)
- [disler/claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery)
- [Matt Brailsford — Replacing custom worktree skill with hooks](https://mattbrailsford.dev/replacing-my-custom-git-worktree-skill-with-claude-code-hooks)
- [Claude Code worktree docs](https://code.claude.com/docs/en/worktrees)
- [Claude Code hooks docs](https://code.claude.com/docs/en/hooks-guide)
- [ntfy publish docs](https://docs.ntfy.sh/publish/)
- [GH #9567 — hook env vars empty](https://github.com/anthropics/claude-code/issues/9567)
- [GH #6305 — hooks not firing](https://github.com/anthropics/claude-code/issues/6305)
- [GH #16564 — Windows hooks](https://github.com/anthropics/claude-code/issues/16564)
- [AI Escalation Pathways](https://www.aiuxdesign.guide/patterns/escalation-pathways)
- [AI Agent Circuit Breaker Pattern](https://cordum.io/blog/ai-agent-circuit-breaker-pattern)
- [Git Worktrees for AI Coding — MindStudio](https://www.mindstudio.ai/blog/git-worktrees-parallel-ai-coding-agents)
