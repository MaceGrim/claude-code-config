# TODO

Deferred work captured from design sessions. Strike through and wrap `~~ ~~` when done.

## v1 (next build)

- [ ] Build `/spawn --autonomy=auto` per `specs/SPEC-spawn-autonomy-v1.md`. 10-step build order in the spec. First testable artifact at step 5 (~90 min). Total ~7-9 focused hours.

## v1.5 (post-dogfooding, after v1 ships and gets ~2 weeks of real use)

- [ ] Expand `/spawn` discovery branches to handle workflow modes beyond features-in-existing-repo:
  - Greenfield walking-skeleton (default for day-1 greenfield with vision)
  - Greenfield role-parallel scaffolding (fallback when boundaries are obvious)
  - Greenfield exploratory — REFUSE and force one-sentence thesis + success path first
  - Cross-cutting maintenance (upgrade React, replace auth lib, add tracing)
  - Polish/review sweep (test debt, docs, a11y, perf)
  - Bug triage burst (one workstream per bug, each isolated)
- [ ] Personas as a discovery branch (NOT a separate skill) if dogfooding shows you reach for them ≥5 times. Config at `~/.claude/personas.json`, consumed by /spawn's role-parallel branch only.
- [ ] Add watchdog + heartbeat to `/spawn --autonomy=auto` if you start walking away overnight (deferred from v1 with daily-summary).
- [ ] Add daily-summary via `/schedule` if v1 reveals you can't tell whether autonomy mode is alive without it.

## v2 (separate skills, evidence-driven)

- [ ] **`/spike`** — separate skill for the "N candidate prototypes, one wins, rest discard" pattern. Different output topology from `/spawn`. Build when you actually want to compare 2-3 technical approaches. Pre-build spec deferred — write SPEC-spike-v0.md when you're ready to scope.
- [ ] **`/day`** — cross-repo morning orchestration. One tmux window per client/project, each Claude given that project's todos. `/spawn` nests within. Pending codex's read in the current session; SPEC-day-v0.md to follow.

## Operational

- [ ] Commit + push claude-code-config to GitHub when current session work is settled.
- [ ] Sync `sentinel-hero` skill into claude-code-config/skills/ for Mac portability (currently on this machine only).

## Dropped (don't revisit without new evidence)

- ~~`/workspace` skill for single persona-scoped sessions~~ — interactive prompt-level scoping is sufficient; the hook-based allowlist only matters in autonomy mode, which is already covered by /spawn.
- ~~Hybrid `@persona:feature` invocation syntax~~ — encodes a matrix nobody populates per Codex; the case it solves is what feature workstreams already do.
- ~~Four-tier autonomy spectrum~~ — collapsed to two (interactive/auto). Guardrails are config, not flag gradients.
- ~~MCP ntfy server~~ — curl shell-out is sufficient.
- ~~Bundle /ralph into /spawn~~ — compose, don't couple.
