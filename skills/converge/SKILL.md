---
name: converge
description: Iterate on a plan with the codex-runner subagent until both Claude and Codex agree it's ready. Use when the user has an in-progress operational plan, migration sequence, refactor strategy, or task list and wants a second opinion stress-tested against the actual code — not a one-shot review but a back-and-forth that ends in alignment. Lighter weight than /adversarial-spec: two voices (Claude + Codex), no written spec output, lives entirely in the conversation. Trigger on phrases like "iterate with codex until agreement", "converge on this plan", "codex and you keep going until aligned", or any explicit /converge invocation.
---

# converge — iterate with Codex until aligned

The user has a plan in the conversation. They want it stress-tested by Codex
through more than one pass: review → adjust → re-review, until both models
agree it's ready to execute. This is the operational analog of
`/adversarial-spec` for written specs.

## When to use

- The user explicitly invokes `/converge` or says something like "iterate with
  codex until you agree", "have codex review this and keep going until we're
  aligned", "converge on this plan with codex".
- A non-trivial plan exists in the live conversation — multiple steps, code
  changes, infra changes, anything where a missed dependency would cost time.

## When NOT to use

- One-shot reviews → use `/codex-review` instead.
- Written specs that need a permanent artifact → use `/adversarial-spec`.
- Trivial single-step changes → no review needed.

## Two modes

`/converge` runs in one of two modes. Detect which from the invocation:

| Mode | Default? | Trigger |
|---|---|---|
| **autonomous** | ✅ yes | Plain `/converge`, or text like "converge autonomously", "you and codex figure it out", "ship me the final plan" |
| **interactive** | no | Text like "step by step", "show me each round", "let me weigh in", "involve me", "ask me each round", or an explicit `--interactive` flag in args |

Both modes run the same loop. They differ only on whether Claude pauses
between rounds to surface findings + judgments to the user before applying.

## What the loop does

**Autonomous mode is the default.** The user delegates judgment to
Claude + Codex through all intermediate rounds. The user is presented with
the final converged plan at the end, not asked to bless each round.

**Interactive mode** uses the same loop but surfaces a structured per-round
report and pauses for user approval before applying changes. See the
"Interactive mode presentation" section below.

```
loop until agreement (or max 5 rounds, or user says stop):
  1. Snapshot the current plan (task list or numbered steps)
  2. Send Codex a focused review prompt — repo path, the plan, the
     specific concerns it should check
  3. Codex returns findings + verdict
  4. Claude (you) judges each finding: accept / modify / reject with reasoning
  5. Apply accepted changes to the plan/spec/task list immediately
  6. Briefly note progress to the user (1-2 lines: "Round N: X changes
     applied, firing Round N+1") — do NOT gate the next round on user reply
  7. If Codex's verdict was "proceed as-is" AND you accepted no new changes
     this round → AGREEMENT REACHED. Exit loop, write final report.
  8. Otherwise go to step 1 with the updated plan.
```

### Exception: pause for user input only when

- A finding raises a question only the user can answer (preference, scope,
  external constraint). In that case, ask the user, then resume the loop.
- A finding proposes a fundamental rethink Claude can't unilaterally apply
  (e.g., "abandon this architecture for X"). Surface and ask.
- The user explicitly said "show me each round" in their /converge invocation.

Otherwise: judge, apply, move on.

## How to call Codex

Use the `Agent` tool with `subagent_type: "codex-runner"`. Construct
prompts that:

- State the repo path explicitly.
- Embed the **current** plan (full task list, including changes from previous
  rounds — Codex has no memory of prior rounds).
- List the specific concerns to check. Don't ask for a generic "look
  for bugs" — be surgical. Reuse the targeted-question pattern from round 1
  unless something new is in question.

### Per-round question sizing — favor small parallel calls

**Don't stuff every round into one 6-8 question monolithic prompt.** Codex
empirically hangs or times out at high rate (3-of-4 substantive runs in
recent practice) when given 5+ cross-cutting questions. Each round, classify
the concerns first:

- **Independent concerns** (each finding's answer doesn't change the
  others' answer) → fire **multiple parallel codex calls** in one message
  via `Agent` with `run_in_background: true`. Each call asks about 1-3
  concerns, with enough nearby-context for second-order implications.
- **Cross-dependent concerns** (e.g., "is the API shape right" depends
  on "should we even have this service?") → batch in one call. State the
  dependency: "answer Q1 first; Q2 builds on it."
- **Mixed** → split parallel along dependency lines. Two small dependent
  batches in parallel beats one large monolithic prompt.

**Verdict consolidation across parallel calls**: each parallel call ends
with its own per-batch verdict. You (Claude) synthesize across them into
a single round-level verdict for the user.

Heuristic per round: 1-4 concerns = single call. 5+ concerns = split.

### Closing verdict shape

Each codex call (single or parallel batch) ends with one of:
- `proceed as-is` — no further changes needed
- `proceed with these N changes` — list them
- `rethink before proceeding` — fundamental issues

The verdict phrasing is the loop's termination signal. Tell each codex
call explicitly: "End your report with one of: `Verdict: proceed as-is`,
`Verdict: proceed with these N changes`, or `Verdict: rethink before
proceeding`."

When parallel calls return, the **round-level verdict** is the strictest
of the per-batch verdicts:
- Any `rethink` → round verdict is `rethink`
- Otherwise any `proceed with changes` → round verdict is `proceed with
  combined changes` (concat the change lists)
- All `proceed as-is` → round verdict is `proceed as-is`

## How to judge Codex's findings

For each finding Codex raises, decide:

- **Accept** — Codex is right, apply the fix. Adjust the task list.
- **Modify** — directionally right but the fix is wrong. Propose a better fix.
- **Reject** — disagree, with reasoning. Explain why in plain language so the
  user (and the next Codex pass, if any) can see the argument.

Don't accept findings just because Codex flagged them. Don't reject findings
just because they're inconvenient. The point of this skill is independent
judgment — if you and Codex don't actually disagree, the loop wasn't needed.

## Autonomous mode: per-round progress note

Keep it short — 1-2 lines per round so the user knows the loop is running
and where it stands. Example:

```
Round 1: 6 codex findings, accepted all 6 (cost-ceiling hook, ntfy via
curl, hook root resolution, +3 acceptance criteria, watchdog cut to v1.1,
explicit build order). Applied to spec. Firing Round 2.
```

Do NOT format every round as a structured table. Do NOT ask the user to
approve. The user can interject at any time to override or stop the loop.

The final converged report at the end of the loop IS structured (see Final
report section).

## Interactive mode presentation

When the user opted into interactive mode, present each round in this
structured format and pause for response before applying:

```
## Round N

**Codex findings**:
- [SEVERITY] finding 1 ... → [accept | modify | reject]: reasoning
- [SEVERITY] finding 2 ... → [accept | modify | reject]: reasoning
...

**Plan changes I'd apply**:
- Add task: ...
- Modify task #X: ...
- Remove task #Y: ...

**Verdict from Codex**: <quoted verdict line>

**Approve all, override on any, or stop?**
```

In interactive mode, wait for the user's response. They can override
Claude's accept/reject on any finding, ask Codex to dig deeper on
something, or call the loop early.

## Termination

Agreement is reached when:
- Codex's verdict is `Verdict: proceed as-is`, AND
- You proposed no plan changes this round (no findings accepted)

Other valid exits:
- User interjects "good enough" / "stop" / "ship it" — record any open
  Codex findings as unresolved, list them in the final summary
- Max 5 rounds reached — surface the residual disagreement to the user
  and ask them to break the tie

## Final report

When the loop exits with agreement, write a short summary:
- Rounds taken
- Net plan changes from start to end
- Findings that were debated and resolved
- Findings (if any) that were rejected on principle and why

Then ask the user if they're ready to execute, or if they want to step
through the updated tasks one at a time.

## Implementation notes

- Use `TaskList` / `TaskGet` to snapshot the current plan before each Codex
  pass. If the plan lives only in conversation text, snapshot that text
  verbatim into the Codex prompt instead.
- After applying changes, use `TaskUpdate` to amend tasks and `TaskCreate`
  for new ones — keep the task list as the source of truth.
- Don't loop silently. The user should see each round's findings and your
  judgments — they're the tiebreaker.
- Don't have Codex review the *same* findings round after round. If Codex
  re-raises something you've already considered and rejected, explain to
  Codex in the next round's prompt *why* you rejected it so it doesn't
  re-raise.
