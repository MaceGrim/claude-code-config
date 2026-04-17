---
allowed-tools: Bash(codex:*), Bash(gemini:*), Read, Write, Glob, Grep, AskUserQuestion, Skill
description: Create and refine specs through multi-model debate until Claude, Codex, and Gemini all agree
argument-hint: [prd|tech] <product/feature description>
---

# Adversarial Spec Development

Create specifications through iterative debate with multiple AI models until all reach consensus. Claude drafts, then Codex and Gemini critique until everyone agrees.

**Ralph Loop Compatible:** This command outputs `prd.json` alongside PRD.md. When you run `/ralph`, it reads prd.json and creates Claude Code native tasks (TaskCreate) from each user story, then spawns subagents to complete them. All user stories include testable acceptance criteria and verification commands.

## Process Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Interview  │────▶│ Claude      │────▶│ Codex +     │────▶│ Synthesize  │
│  (gather    │     │ drafts      │     │ Gemini      │     │ + revise    │
│  context)   │     │ spec        │     │ critique    │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                                              ┌────────────────────┘
                                              ▼
                                        ┌───────────┐
                                        │ All agree?│
                                        └─────┬─────┘
                                              │
                                    No ───────┴─────── Yes
                                    │                   │
                                    ▼                   ▼
                              [Loop back]         [Output final]
```

## Instructions

### Step 1: Check for SPEC.md (Source of Truth)

First, check if `SPEC.md` exists in the current directory:

```bash
ls SPEC.md 2>/dev/null
```

**If SPEC.md exists:**
- Read it completely - this is the user's true intent captured via `/seed`
- This document is the **source of truth** - the debate must align with it
- Models can clarify, harden, and add detail, but CANNOT contradict SPEC.md
- Skip the interview (Step 2) - SPEC.md already captures requirements
- Inform the user: "Found SPEC.md - using it as the source of truth for this spec."

**If SPEC.md does not exist:**
- Suggest running `/seed` first for best results
- Or proceed with interview (Step 2)

### Step 2: Parse Arguments and Determine Doc Type

Parse `$ARGUMENTS` to extract:
- **Doc type**: `prd` or `tech` or `both` (default: **both**)
- **Description**: What to build (only needed if no SPEC.md)

**Default behavior:** Create BOTH PRD and Tech Spec. This is the recommended flow:
1. PRD.md - for stakeholders, PMs, designers
2. TECH_SPEC.md - for developers and architects (used with `/implement-spec` or `bd`)

Only ask about doc type if user explicitly specifies `prd` or `tech` in arguments. Otherwise, proceed with both.

### Step 3: Interview to Gather Requirements (Skip if SPEC.md exists)

**If SPEC.md exists:** Skip this step entirely - SPEC.md is your input.

**If no SPEC.md:** Conduct a focused interview. Use AskUserQuestion for efficiency.

**For PRD, ask about:**
1. What problem does this solve? Who experiences this pain?
2. Who are the target users? What are their goals?
3. What does success look like? How will you measure it?
4. What's in scope? What's explicitly out of scope?
5. Any constraints (timeline, budget, tech, regulatory)?

**For Tech Spec, ask about:**
1. What systems does this integrate with?
2. What are the performance requirements (latency, throughput, scale)?
3. What are the security/auth requirements?
4. Any existing patterns or tech stack preferences?
5. What's the deployment environment?

Keep it focused - 3-5 questions max. Get enough to draft, then let the debate surface gaps.

### Step 3: Draft Initial Specification

Based on interview answers, draft a complete specification.

**PRD Structure:**
```markdown
# [Product Name] - PRD

## Executive Summary
[2-3 paragraphs]

## Problem Statement
[What problem, who has it, current pain]

## Target Users
[Personas with goals and pain points]

## User Stories

### US-001: [Story Title]
**As a** [user type] **I want to** [action] **so that** [benefit]

**Acceptance Criteria:**
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]

**Verification:**
```bash
[test command or verification steps - e.g., pytest tests/test_feature.py]
```

**Priority:** [P0/P1/P2]

---

### US-002: [Story Title]
[Same structure...]

## Functional Requirements
[What the system must do - reference user stories]

## Non-Functional Requirements
[Performance, security, scalability - with measurable targets]

## Success Metrics
[Specific, measurable targets]

## Scope
### In Scope
### Out of Scope

## Risks & Mitigations

## Open Questions
```

**CRITICAL: User Story Requirements for Ralph Compatibility**
Each user story MUST have:
1. **Testable acceptance criteria** - not vague ("works well") but specific ("returns 200 status code")
2. **Verification command** - a shell command that can verify the criteria (test suite, curl, type check, etc.)
3. **Priority** - P0 (must have), P1 (should have), P2 (nice to have)
4. **Small scope** - each story should be completable in a single coding session

Examples of GOOD acceptance criteria:
- "POST /api/users returns 201 with valid payload"
- "Login form shows error message when password is < 8 chars"
- "pytest tests/test_auth.py passes with 100% coverage"
- "Response time < 200ms for 95th percentile"

Examples of BAD acceptance criteria (too vague):
- "User experience is good"
- "System is fast"
- "Code is clean"
- "Works as expected"

**Tech Spec Structure:**
```markdown
# [System Name] - Technical Specification

## Overview
[Context and goals]

## Architecture
[Components, interactions, diagrams if helpful]

## API Design
[Endpoints, request/response schemas]

## Data Models
[Schemas, relationships, constraints]

## Security
[Auth, authorization, encryption, validation]

## Error Handling
[Error scenarios and handling strategies]

## Performance
[Targets: latency, throughput, availability]

## Observability
[Logging, metrics, alerting]

## Deployment
[How to deploy, rollback, scale]

## Open Questions
```

Present the draft to the user:
> "Here's the initial draft. Review it quickly - the debate will surface issues, but flag anything fundamentally wrong now."

### Step 4: Send to Opponent Models for Critique

Run critiques in parallel:

**Codex critique:**
```bash
codex exec --skip-git-repo-check "You are reviewing a specification document. Your job is to find problems, gaps, ambiguities, and risks.

DOCUMENT TYPE: [prd|tech]

IMPORTANT: Read the specification from the file [PRD.md or TECH_SPEC.md] on disk. Do NOT repeat or echo the file contents back in your response — only provide your critique.

CRITIQUE INSTRUCTIONS:
1. Read the ENTIRE document carefully from the file
2. Identify specific issues:
   - Missing information
   - Ambiguous requirements
   - Unrealistic assumptions
   - Security concerns
   - Scalability issues
   - Edge cases not handled
3. **TESTABILITY CHECK (CRITICAL):**
   - Does EVERY user story have specific, testable acceptance criteria?
   - Can each criterion be verified with a command or automated test?
   - Are criteria binary (pass/fail) not subjective (good/bad)?
   - Is there a verification command for each story?
   - Flag ANY vague criteria like 'works well', 'is fast', 'user-friendly'
4. For each issue:
   - Quote the problematic section
   - Explain the problem
   - Suggest a fix
5. If you find NO issues, respond with exactly: [AGREE]
6. Be thorough - do not agree prematurely
7. Keep your response concise — critique only, no echoing the spec

Provide your critique:" 2>&1
```

**Gemini critique:**
```bash
gemini -p "You are reviewing a specification document. Your job is to find problems, gaps, ambiguities, and risks.

DOCUMENT TYPE: [prd|tech]

IMPORTANT: Read the specification from the file [PRD.md or TECH_SPEC.md] on disk. Do NOT repeat or echo the file contents back in your response — only provide your critique.

CRITIQUE INSTRUCTIONS:
1. Read the ENTIRE document carefully from the file
2. Identify specific issues:
   - Missing information
   - Ambiguous requirements
   - Unrealistic assumptions
   - Security concerns
   - Scalability issues
   - Edge cases not handled
3. **TESTABILITY CHECK (CRITICAL):**
   - Does EVERY user story have specific, testable acceptance criteria?
   - Can each criterion be verified with a command or automated test?
   - Are criteria binary (pass/fail) not subjective (good/bad)?
   - Is there a verification command for each story?
   - Flag ANY vague criteria like 'works well', 'is fast', 'user-friendly'
4. For each issue:
   - Quote the problematic section
   - Explain the problem
   - Suggest a fix
5. If you find NO issues, respond with exactly: [AGREE]
6. Be thorough - do not agree prematurely
7. Keep your response concise — critique only, no echoing the spec

Provide your critique:" 2>&1
```

### Step 5: Claude's Independent Critique

You (Claude) also critique the spec independently. Don't just echo what Codex and Gemini said - add your own perspective:
- What did you notice that they missed?
- Do you agree or disagree with their critiques?
- What would you add or change?

**TESTABILITY CHECK (you must verify):**
- Every user story has testable acceptance criteria (not vague)
- Every story has a verification command
- Criteria are binary pass/fail, not subjective
- Stories are small enough to complete in one session
- Priorities are assigned (P0/P1/P2)

### Step 6: Synthesize and Revise

Display the round summary:
```
═══════════════════════════════════════════════════════════════
                         ROUND [N]
═══════════════════════════════════════════════════════════════

CODEX CRITIQUE:
[summary - agreed or list of issues]

GEMINI CRITIQUE:
[summary - agreed or list of issues]

CLAUDE CRITIQUE:
[your own analysis]

───────────────────────────────────────────────────────────────
                       SYNTHESIS
───────────────────────────────────────────────────────────────

Issues to address:
1. [issue] - raised by [who] - action: [what you'll do]
2. [issue] - raised by [who] - action: [what you'll do]
...

Rejected critiques (with reasoning):
- [critique] - rejected because [why]

Questions for user (if any product decisions needed):
- [question]
```

**If any critique requires user input** (product decisions, priority calls, constraint clarifications), ask before revising.

**Revise the spec** incorporating valid feedback. Be thorough - address every accepted issue.

### Step 7: Check for Consensus

**If ALL models agreed ([AGREE]):**
- Proceed to Step 8 (Finalize)

**If ANY model had critiques:**
- Go back to Step 4 with revised spec
- Maximum 10 rounds (ask user to continue if reached)

**Anti-laziness check:** If a model agrees in rounds 1-2, be skeptical. They may not have read carefully. In your next critique prompt, add:
```
Note: Please confirm you read the ENTIRE document. List 3 specific sections you reviewed and explain why you agree.
```

### Step 8: Finalize and Output

When all models agree:

1. **Final quality check** - verify completeness, consistency, clarity

2. **Final testability check** - ensure EVERY user story has:
   - Testable acceptance criteria
   - Verification command
   - Priority assigned

3. **Write to files:**
   - PRD → `PRD.md`
   - Tech Spec → `TECH_SPEC.md`
   - **Ralph-compatible JSON → `prd.json`**

**When creating both (default):**
- First complete the PRD debate cycle
- Then use PRD + SPEC.md as context for Tech Spec debate
- Write all files when complete

4. **Generate prd.json for Ralph compatibility:**

```json
{
  "project": "[Project Name]",
  "generated_from": "PRD.md",
  "generated_at": "[ISO timestamp]",
  "stories": [
    {
      "id": "US-001",
      "title": "[Story Title]",
      "description": "As a [user] I want to [action] so that [benefit]",
      "acceptance_criteria": [
        "[Criterion 1]",
        "[Criterion 2]"
      ],
      "test_command": "[verification command]",
      "priority": "P0",
      "passes": false
    }
  ]
}
```

Extract all user stories from PRD.md into this structured format. Set all `passes` to `false` initially.

5. **Display summary:**
```
═══════════════════════════════════════════════════════════════
                    SPECIFICATION COMPLETE
═══════════════════════════════════════════════════════════════

Documents created:
- PRD.md (for stakeholders)
- TECH_SPEC.md (for implementation)
- prd.json (for Ralph loop automation)

Rounds: [N] (PRD) + [M] (Tech Spec)
Models: Claude, Codex, Gemini

User Stories: [X] total ([Y] P0, [Z] P1, [W] P2)
All stories have testable criteria: ✓

Key refinements made:
- [bullet points of major changes from initial to final]

───────────────────────────────────────────────────────────────

Ready to implement?
```

6. **Ask if user wants to implement:**
   ```
   AskUserQuestion:
   question: "Would you like to implement this spec now using /ralph?"
   options:
     - label: "Yes, run /ralph"
       description: "Create tasks from prd.json and execute with fresh-context subagents"
     - label: "No, I'll review first"
       description: "Stop here so you can review PRD.md and prd.json"
   ```

7. **If user chooses to implement:**
   ```
   Skill(skill="ralph")
   ```

   This will run /ralph which reads prd.json, creates native Claude Code tasks, and spawns subagents to complete them.

### Step 9: Post-Finalization Options

**If user requests changes:**
- Make modifications
- Optionally run another debate cycle
- Regenerate prd.json to reflect changes

**Ready to implement - three options:**

1. **`/ralph`** (Recommended for autonomous work)
   - Uses prd.json directly
   - Fresh context each iteration (no context pollution)
   - Works through stories sequentially until all pass
   - Best for: overnight runs, well-defined tasks

2. **`/implement-spec`** (For parallel work)
   - Breaks TECH_SPEC.md into tasks
   - Sets up multi-agent swarm
   - Agents coordinate via agent mail
   - Best for: complex interdependent work, human supervision

3. **`bd`** (For manual control)
   - Manual task management
   - Full human control over execution
   - Best for: exploratory work, learning codebase

## Convergence Rules

- ALL models must agree for convergence (Claude + Codex + Gemini)
- Maximum 10 rounds per cycle
- Quality over speed - don't rush to consensus
- If critiques conflict, evaluate on merit; ask user for product decisions
- Only agree when you'd confidently hand this to an implementation team

## Tips

- Keep specs focused - better to have a tight spec than a sprawling one
- Use the Open Questions section liberally - it's honest about unknowns
- If debate stalls, ask user to make a decision
- Each round should make meaningful progress

**For Ralph compatibility:**
- Every acceptance criterion should be verifiable with a command
- Prefer `pytest`, `curl`, type checkers, linters as verification methods
- Keep stories small - if a story feels big, split it
- P0 stories should be tackled first (Ralph prioritizes by priority)
- Avoid subjective criteria - "fast" → "< 200ms p95", "clean" → "passes lint"
