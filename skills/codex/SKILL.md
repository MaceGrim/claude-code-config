---
name: codex
description: Ask the OpenAI Codex CLI for a second opinion on anything — code review, design critique, fact-check, architecture decisions, plan sanity-check, verdict on a proposal. One skill, several modes. Triggers on `/codex`, `/codex <mode>`, or phrases like "ask codex what they think", "get a second opinion from codex", "have codex review/critique/fact-check this", "codex sanity check", "what does codex say". Delegates to the `codex-runner` subagent (which owns the call mechanics); this skill owns prompt construction per mode. Citations are always requested for external factual claims. No timeouts — codex runs to completion. Replaces the deprecated `/codex-review` skill.
---

# codex — ask Codex for a second opinion

`/codex` is the unified entry point for asking OpenAI's Codex CLI to weigh in on something. Code review is one use case; the skill covers any place an independent second-model perspective is useful.

Architecture:
- This skill owns **prompt construction** — mode dispatch, input handling, the prose templates.
- The `codex-runner` subagent owns **call mechanics** — invocation, JSONL streaming, parsing, error reporting.
- `/converge` is a separate skill that uses `codex-runner` directly for iterative review loops; it does NOT call `/codex`.

## When to use

- User invokes `/codex` (with or without a mode).
- User says "ask codex", "get a second opinion from codex", "have codex review/critique/factcheck this", "what does codex think", "codex sanity-check".
- A judgment call would benefit from an independent model. Examples: an architecture decision, a contested claim, a plan before commitment.

## When NOT to use

- The question is not load-bearing — overusing codex creates noise and notification fatigue.
- The user is iterating on a plan and wants a back-and-forth loop → use `/converge` instead.
- The user wants three models' opinions (Claude + Codex + Gemini) → use `/council`.
- The task is asking Claude itself (this session) for an answer — there's no need to involve codex.

## Modes

Four substantive modes (distinct prompt families) plus three preset aliases (framings over the general prose template):

| Mode | Output shape | Purpose |
|---|---|---|
| `general` (default) | prose | Generic second opinion — no specific framing |
| `review` | findings-first | Code/design review — issues by severity, with locations |
| `fact-check` | `true \| false \| uncertain` + evidence + citations | Verify a specific claim |
| `verdict` | **Line 1: `Verdict: proceed as-is` / `Verdict: proceed with these N changes` / `Verdict: rethink before proceeding`**, then rationale + citations | Structured go/no-go signal — same vocabulary as `/converge` |
| `critique` | prose (alias for general w/ critical framing) | "Where is this weak?" |
| `architecture` | prose w/ tradeoffs + recommendation (alias for general) | Architecture decision |
| `plan` | prose w/ risks + open questions (alias for general) | Plan sanity-check |

Mode is the **first positional arg** if present and matches the table:
`/codex review backend/auth.py`
`/codex fact-check "Postgres has SERIALIZABLE isolation by default"`
`/codex verdict --context current "Should we ship this behind a flag this week?"`
`/codex "Does this design make sense?"` ← no mode → general

## Input forms

Four explicit forms, in order of detection precedence:

1. **`--context current`** flag → include a **Claude-generated summary** of recent conversation turns (NOT raw transcript). The summary is labeled "Claude-generated summary, potentially incomplete or biased; verify against supplied artifacts and do not defer to its conclusions."
2. **File paths** (any arg that resolves to an existing file) → read the file contents and include them. Multiple paths allowed.
3. **Quoted/pasted text** (anything in `"..."` that isn't a path) → include verbatim.
4. **Bare question** (remaining unquoted args) → treat as the question.

If multiple forms are present, all are included. The skill does NOT magically infer "the whole conversation" — `--context current` must be explicit.

## Prompt construction (per mode)

Every prompt has three sections:

```
<SYSTEM PREAMBLE>
<MODE FRAMING>
<USER CONTENT>
```

### System preamble (constant across modes)

```
You are an independent reviewer. The user is asking for a second opinion
separate from Claude (the AI they're working with). Be candid, terse, and
opinionated. Do not pad with niceties.

For any external factual claim you make, include a source link or citation.
If no external sources are relevant, say "no sources used" rather than
inventing citations. Do not fabricate links.
```

### Mode framings

**general** (default — also used for critique/architecture/plan aliases):
```
Give a candid second-opinion response. Be specific about what you'd change
or push back on. If the question is genuinely fine, say so plainly.
```

**critique** (alias over general):
```
... above ... Specifically: lead with the strongest objections. What is
this missing or getting wrong? Where would it fail under load, scrutiny,
or edge cases?
```

**architecture** (alias over general):
```
... above ... Lay out the tradeoffs. Name at least one alternative the
user didn't mention. Recommend one path with reasoning.
```

**plan** (alias over general):
```
... above ... Identify the risks ranked by likelihood × impact. List the
open questions the plan hasn't answered. Note what you'd build first vs.
defer.
```

**review** (substantive — code/design):
```
Review the supplied material. Structure your response as:
- CRITICAL findings (must-fix before ship)
- HIGH findings (should-fix)
- MEDIUM findings (worth-fixing)
- LOW findings (nice-to-have)
Use file:line references where applicable. End with a one-line summary.
```

**fact-check** (substantive — verify a claim):
```
The user is asking you to verify a specific factual claim. Structure:
- LINE 1: VERDICT: true | false | uncertain
- Then: evidence supporting your verdict, with source links/citations
- If uncertain, explain what would resolve the uncertainty

Do not fabricate sources. If you can't find sources to verify, say so —
"uncertain" is a legitimate verdict.
```

**verdict** (substantive — structured go/no-go):
```
The user is asking for a go/no-go decision. Required output shape:

- LINE 1 (exact format): one of:
    Verdict: proceed as-is
    Verdict: proceed with these N changes
    Verdict: rethink before proceeding
- After line 1: rationale and any required changes/concerns. Citations
  for external claims if relevant. Use "no sources used" if there are
  none.

The line-1 format is parsed by automation (specifically /converge). Do
NOT add citations or qualifiers on line 1 — put them in the rationale
that follows.
```

### User content

Assembled from the input forms above. Sample structure:

```
<USER CONTENT>

--- Context (Claude-generated summary, potentially incomplete or biased;
    verify against supplied artifacts and do not defer to its conclusions) ---
<summary if --context current was used>

--- Files ---
<path 1>:
<contents>

<path 2>:
<contents>

--- Pasted text ---
<verbatim quoted text if any>

--- Question ---
<bare question if any>
```

Omit empty sections. Use plain `---` separators (no markdown table).

## Question sizing — favor small parallel calls

Codex hangs or times out empirically on prompts with **5+ cross-cutting
questions**. Three of four substantive multi-question runs in recent
practice either ran 30+ minutes or never returned. The fix is to keep
each codex call focused.

**Default: 1-4 focused questions per call.** This is the reliable sweet
spot. Calls of this size return within ~30 seconds to ~5 minutes
depending on depth.

**When the user's ask has multiple sub-questions, classify dependency
first**:

- **Independent** (each question's answer doesn't change the others) →
  **fire multiple parallel codex calls** via `Agent` with
  `run_in_background: true`. Each call gets:
  - The 1-3 specific questions it owns
  - Enough nearby-implication context to consider second-order effects —
    not just the question in isolation, but what else in the surrounding
    design or codebase the answer touches
  - Explicit note that sibling questions are being asked in parallel so
    codex doesn't try to answer everything

- **Cross-dependent** (e.g., Q2 assumes Q1's outcome) → batch in one
  call. Surface the dependency to codex explicitly: "Answer Q1 first;
  Q2's answer depends on it."

- **Mixed** → split into parallel calls along dependency lines. Two
  small dependent batches in parallel beats one large monolithic
  prompt.

**Heuristic table**:

| Questions | Recommendation |
|---|---|
| 1-4 | Single call |
| 5-8 | Split into 2-3 parallel calls along dependency lines |
| 9+ | Almost always wrong — re-scope the ask, or split aggressively |

**Token cost note**: N parallel calls pay system-prompt overhead N
times (~10-20K tokens per call before user content). For trivial
questions this is wasteful; default to single-call for one-shot
trivia. For substantive design questions where each independent answer
is 200+ words and reliability matters, the overhead is worth it.

**After parallel calls return**: synthesize the N answers into a single
response for the user. Don't dump raw outputs side-by-side. Flag any
contradictions between sibling answers — those signal that questions
weren't actually independent and might warrant a follow-up batched call.

**Worked example**: a /converge round on a 14-task spec has codex
review 8 specific concerns. Of those: Q1 (cost-ceiling) and Q2 (ntfy
helper format) are independent → parallel calls. Q3 (manifest URL
rewriting) and Q4 (docker-compose default) both depend on Q5's
answer about base-branch resolution → batched call. Three parallel
codex invocations instead of one monolithic 8-question prompt.

## Delegation to codex-runner

Once the prompt is constructed, delegate to the `codex-runner` subagent via the `Agent` tool:

```
Agent({
  description: "codex /<mode> on <subject>",
  subagent_type: "codex-runner",
  prompt: "<constructed prompt — the entire text codex should receive>"
})
```

The subagent returns a structured report (final answer + usage + any warnings). Format it for the user:

```
[codex /<mode>]

<the answer>

(tokens: <input>/<cached>/<output>, <wall-clock>s)
```

If warnings were reported (stale heartbeat, no-citations-despite-factual-claims, etc.), append:

```
⚠ Warnings:
- <warning 1>
- <warning 2>
```

If codex failed:

```
[codex failed — exit <code>]
last event: <event type>
stderr tail:
<...>
```

## Examples

```
/codex "Does this Postgres schema make sense for a multi-tenant SaaS?"
  → general prose answer

/codex review src/auth.ts tests/auth.test.ts
  → findings-first review of the two files

/codex fact-check "Postgres has SERIALIZABLE isolation by default"
  → verdict + evidence + citations (this would be: false; default is READ COMMITTED)

/codex verdict --context current "Are we ready to ship this branch?"
  → structured Verdict: line + rationale, using a Claude-generated
    summary of the recent conversation as the "what we're shipping"
    context

/codex critique docs/migration-plan.md
  → alias for general, framing emphasizes "where is this weak?"

/codex architecture "Split ingestion from retrieval into separate services?"
  → alias for general, framing emphasizes tradeoffs + alternative + recommendation
```

## Migration from `/codex-review`

The previous `/codex-review` skill is deprecated. It still works (as a thin wrapper that calls `/codex review ...`), but new uses should invoke `/codex review ...` directly.

Background: `/codex-review` was scoped only to code review. As Claude Code workflows expanded to design critique, fact-checking, and verdict-based loops, having one general skill (`/codex`) with explicit modes is cleaner than fragmenting into `/codex-review`, `/codex-critique`, `/codex-factcheck`.

## Failure modes to watch for

- **Prompt ambiguity** — "second opinion" requests are often underspecified. If the user's bare question is fewer than ~10 words and there are no files/context, ask the user one clarifying question before invoking codex.
- **Wrong mode chosen** — if the user said `/codex` without a mode and the request clearly wants a verdict, ask "did you want `/codex verdict` for a structured go/no-go?" before defaulting to general.
- **Context bloat** — `--context current` summaries can swamp the actual question. Keep summaries to ~10-15 sentences max.
- **Citation gaps on factual claims** — `codex-runner` flags this in its warnings. Surface to the user.
- **Output contract drift in verdict mode** — if codex's response doesn't have `Verdict: ...` on line 1, the run failed downstream parsing. Report to user, optionally re-ask codex with explicit "Line 1 must be exactly: Verdict: ..." reminder.
- **Prompt-size hangs** — large multi-question prompts (5+ cross-cutting questions) empirically hang or time out at high rate. See "Question sizing" above for the fix: split into smaller parallel calls along dependency lines. If you're about to send a prompt with 5+ questions, stop and re-scope first.

## Implementation notes

- **No timeouts.** Codex runs to completion. If it takes 20 minutes, that's fine. The runner emits heartbeats so the user sees progress.
- **Prompt content is sensitive.** Avoid embedding secrets, tokens, or live credentials in the constructed prompt — codex.openai.com sees this.
- **`--context current` requires a summary, not a dump.** If you don't have a way to summarize, ask the user what to include.
- **The skill never directly shells out to `codex`.** Always delegate to `codex-runner`. The runner is the only place that knows the validated invocation pattern; bypassing it reintroduces the stdin-hang bug.
