# Studio Review — Claude Code Skill

Review a content draft against Grimshaw Studio's quality standards. Produce structured feedback without touching the draft itself.

**CRITICAL RULE: do NOT modify or change the draft.md directly.** All feedback goes into checklist.md and edits.md in the project's review/ directory.

---

## Inputs

- `draft.md` — The content draft to review
- `BRAND/voice.md` — Voice guidelines, signature moves, taboos
- `BRAND/pillars.md` — Content pillar definitions
- `BRAND/voice-samples.md` — Real examples for comparison
- Any artifacts referenced in the draft (code, scripts, configs)

---

## Review Checklist

Evaluate the draft against each of the following criteria. For each item, mark it as passing or failing with a brief explanation.

### voice_consistency

Compare the draft against `BRAND/voice.md` and `BRAND/voice-samples.md`:

- Does the tone match the appropriate pillar?
- Are signature moves present where appropriate?
- Does the draft avoid all taboos (no AI hype, no savior framing, no generic advice, no vendor pitches)?
- Read three sentences aloud. Do they sound like Mason or like generic AI content?

If tone drifts or any taboo is violated, this check fails.

### technical_accuracy

Verify every factual claim, statistic, and technical assertion:

- Are cited numbers accurate and sourced?
- Do technical explanations hold up under scrutiny?
- If code snippets exist, run them. Do they produce expected output?
- If tools, libraries, or APIs are referenced, confirm they exist and behave as described.

If any claim cannot be verified or is demonstrably wrong, this check fails.

### artifacts_work

If the draft references supporting artifacts (scripts, demos, visualizations, code samples):

- Run `test-artifact` scripts or commands to execute automated artifact tests.
- Confirm each artifact produces expected output.
- Confirm screenshots or visual references match the current state.
- Confirm any linked resources (URLs, repos, datasets) are accessible.

If any artifact fails its test or is broken, this check fails.

### has_hook

Evaluate the opening of the draft:

- Does the first sentence or paragraph create genuine interest?
- Does it use one of the signature moves?
- Would a busy reader stop scrolling?
- Does it avoid generic openings?
- Is the hook honest and specific, not clickbait?

If the opening is weak or generic, this check fails.

---

## Output Files

### checklist.md

Write review results to `checklist.md` in the project's review/ directory:

```markdown
# Review Checklist

Date: YYYY-MM-DD
Reviewer: [agent or human]
Draft: draft.md

## Results

- [x] voice_consistency — [explanation]
- [ ] technical_accuracy — [explanation of failure]
- [x] artifacts_work — [explanation]
- [x] has_hook — [explanation]

## Summary

N/4 checks passed. [Status: ready for publish | blocked on X]
```

### edits.md

Write all suggested changes to `edits.md` in the project's review/ directory:

```markdown
# Suggested Edits

## Critical (must fix before publish)
1. [Specific issue with line reference and fix]

## Recommended (improves quality)
1. [Suggestion with rationale]

## Minor (optional polish)
1. [Small fix]
```

---

## Rules

1. You must never modify draft.md directly. All feedback goes into checklist.md and edits.md.
2. If any check fails, do not proceed to publish. The draft must go back to revision.
3. Be specific. "The tone feels off" is not useful. "Paragraph 3 uses 'revolutionary' which violates the AI hype taboo" is useful.
4. Run all code. Do not assume it works. If you cannot run it, mark technical_accuracy as failed and explain why.
5. Compare against actual voice samples, do not guess.
