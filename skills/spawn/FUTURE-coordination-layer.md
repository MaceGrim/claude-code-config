# Future extension — cross-session blocker coordination

> Status: **design note, not built.** Captured 2026-05-26 from a Claude + Codex
> review. This is a *future* layer for `/spawn`-style parallel worktree builds;
> none of it exists yet. The everyday `/spawn` case (independent, non-overlapping
> features) does **not** need any of this — it's the exception path for *coupled*
> or *greenfield* work where streams share a seam.

## The problem

Parallel build: one Claude Code session per git worktree, shown in tmux panes,
all branches fork from and merge back to a shared `dev` (hub-and-spoke; worktrees
never merge into each other). File isolation is enforced by git + a file-ownership
map (each stream owns its own subtree, e.g. `src/game`, `src/ui`, `src/ai`) + a
frozen shared contract (shared types + engine API) committed on `dev`.

**The gap:** independent sessions have no shared channel. When one agent is
blocked ("I need stream X to expose Y", "I need devDep Z added to dev"), there's
no way for it to signal, and no way for a resolver to notice — today it's done by
a human screen-scraping panes. Goal: agents resolve *mechanical* blockers
without us; we're pulled in only for direction / judgment.

## Why not the obvious options

- **Agent Teams** (native: shared task list + peer mailbox + idle/task hooks)
  solves it — but is experimental, env-gated (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`),
  and **does not isolate file edits** (two teammates editing one file overwrite
  each other), which is the whole reason we use worktrees. Re-evaluate when it
  leaves experimental AND fixes isolation; if so it may obsolete this whole doc.
- **Subagents** (Task/Agent tool) are ephemeral, hierarchical, one-shot,
  report-to-parent-only. No peer comms, no persistence. They don't address
  cross-session coordination at all.
- **Shared markdown file** (one per agent in a non-versioned dir): write-races,
  no schema, pull-cadence problems. Superseded by the design below.

## The design (Codex-reviewed; aligned recommendation)

**SQLite-backed thin MCP blackboard + disciplined polling + route-to-owner +
leases/TTLs/cycle-detection + human gate at the contract/semantic boundary.**

### Substrate: a thin MCP facade over SQLite
One local MCP server all N sessions connect to (`claude mcp add` / `--mcp-config`).
Worth choosing over a plain SQLite-CLI *only because* the consumers are
MCP-capable agents — typed tools, cleaner prompts, evolvable protocol. Keep it
**dumb and transactional**: blocker create / claim / resolve / dependency-request
/ contract-version / escalation status. **Never** natural-language negotiation
through it ("rots fast").

Tools (sketch): `report_blocker`, `list_blockers(updated_since=…)`, `claim`,
`resolve`, `escalate`, `contract_version`.

### Signaling: polling, NOT tmux pokes
MCP is pull-only (agent-initiated at checkpoints), so there's no native push.
**Resolved: just poll.** Each agent calls `list_blockers(updated_since=…)` at
every task boundary AND on a 2–5 min interval. "Boring wins." Lower latency, if
ever needed, comes from a real notifier daemon / Unix-socket event bus — built
separately, later. **Do NOT** fuse notification into `tmux send-keys`
automation: wrong pane / dead session / command-injected-mid-edit / lost/dup
pokes make it duct tape, best-effort at most.

### Topology: route-to-owner, no cross-stream edits
Don't let agent A edit into stream B's subtree. The coordinator **routes the
request to B's owner**, and B fixes its own subtree. Collapses the dangerous
"peer-resolve / cross-stream freelancing" failure mode out of existence and
preserves the isolation model worktrees exist to provide.

### Guardrails (from day one, not bolted on later)
- **Lease-based claims** + heartbeats + expiry (no permanent claims).
- **Atomic compare-and-swap** on `claim` (race-free).
- **Rigid blocker schema**, required fields, not free text: owner stream, exact
  artifact, requested change, acceptance condition, contract version, urgency.
- **Ownership enforced in the coordinator** (only owner resolves its classes).
- **Auto-expire** blockers on contract bump or branch divergence ("needs
  revalidation after contract change").
- **Cycle detection** → auto-escalate circular waits.
- **Mandatory `dev` rebase/merge check** before claim or resolve (kills silent
  drift).

### The human gate sits at the contract/semantic boundary
"Humans only for product calls" is too optimistic — current agents do narrow,
concrete unblockers fine but misread vague cross-stream intent and produce
confident-wrong edits. So:
- **No human gate:** dependency bumps, wiring an exported function, config /
  plumbing, exposing a type, test-fixture updates, trivial adapters.
- **Human gate:** shared-contract changes, semantic behavior changes, anything
  that broadens API surface, touches multiple ownership zones, or has >1
  plausible implementation.

## Contract rework propagation (related)

Reworking the frozen contract: land it on `dev` once → each worktree
`git rebase dev` → **TypeScript compile errors are the propagation mechanism**
(they light up exactly the consumers that must change; nothing drifts silently)
→ poke each agent with a one-line summary + pointer to a `CONTRACT-CHANGELOG.md`.
Breaking reworks are paid once per live stream, so **batch them to checkpoints**.
The blackboard's `contract_version` + auto-expire-on-bump enforces revalidation.

## Strategic note: build vs. wait

This design converges toward what Agent Teams *is* (shared task store + ownership
+ gates) minus the file-isolation flaw. So the real decision is **build this MCP
layer now, or wait for Agent Teams to leave experimental and fix isolation.**
Verify whether Agent Teams runs on the target install before committing to a
build.
