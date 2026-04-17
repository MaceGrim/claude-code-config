---
allowed-tools: Bash(codex:*), Bash(gemini:*), Read, Glob, Grep, WebSearch, WebFetch
description: Fact-check the most recent assistant statement using Codex and Gemini
argument-hint: [optional: specific claim to verify]
---

# Double-Check

Fact-check the most recent assistant statement by querying Codex and Gemini for independent verification.

## Available Models

| Model | CLI | Status |
|-------|-----|--------|
| Codex | `codex exec` | !`which codex > /dev/null && echo "Installed" || echo "Not installed"` |
| Gemini | `gemini -p` | !`which gemini > /dev/null && echo "Installed" || echo "Not installed"` |

## Instructions

### Step 1: Identify Claims to Verify

Look at your **most recent assistant message** in the conversation above this command invocation. Extract every factual claim that could be verified or refuted. If `$ARGUMENTS` specifies a particular claim, focus on that.

Examples of verifiable claims:
- Definitions (e.g., "AMI stands for Area Median Income")
- Numeric facts (e.g., "the 0-30% bracket means earning less than 30% of AMI")
- Technical claims about how datasets/APIs/tools work
- Attributions (e.g., "set annually by HUD")
- Behavioral claims about code or data

List each claim as a numbered item.

### Step 2: Query External Models

For each model that is available, send a single prompt asking it to verify all the claims at once.

**Codex:**
```bash
codex exec --skip-git-repo-check "FACT-CHECK REQUEST

The following claims were made. For each one, state whether it is TRUE, FALSE, PARTIALLY TRUE, or UNVERIFIABLE. Provide a brief correction or source for any that are not fully true.

CLAIMS:
[numbered list of claims]

For each claim respond in this format:
1. [TRUE/FALSE/PARTIALLY TRUE/UNVERIFIABLE] — [brief explanation or correction]"
```

**Gemini:**
```bash
gemini -m gemini-2.5-flash -p "FACT-CHECK REQUEST

The following claims were made. For each one, state whether it is TRUE, FALSE, PARTIALLY TRUE, or UNVERIFIABLE. Provide a brief correction or source for any that are not fully true.

CLAIMS:
[numbered list of claims]

For each claim respond in this format:
1. [TRUE/FALSE/PARTIALLY TRUE/UNVERIFIABLE] — [brief explanation or correction]"
```

Run both queries in parallel.

### Step 3: Your Own Verification

Use WebSearch to independently verify any claims that either model flagged as FALSE or PARTIALLY TRUE, or that seem potentially wrong to you.

### Step 4: Present Results

Format the output as:

```
================================================================================
                            DOUBLE-CHECK RESULTS
================================================================================

STATEMENT REVIEWED:
[brief summary or first few lines of the statement being checked]

CLAIMS EXTRACTED:
[numbered list]

--------------------------------------------------------------------------------
                          VERIFICATION RESULTS
--------------------------------------------------------------------------------

1. "[claim]"
   Codex:  [TRUE/FALSE/PARTIALLY TRUE]
   Gemini: [TRUE/FALSE/PARTIALLY TRUE]
   Verdict: [CONFIRMED / DISPUTED / NEEDS CORRECTION]
   [If disputed: correction or clarification]

2. "[claim]"
   ...

--------------------------------------------------------------------------------
                              SUMMARY
--------------------------------------------------------------------------------

Confirmed: X/Y claims verified as accurate
Disputed:  X/Y claims need correction
Uncertain: X/Y claims could not be verified

[If any corrections needed, provide the corrected version of the original statement]

================================================================================
```

## Notes

- Focus on factual claims, not opinions or recommendations
- If a model is unavailable, proceed with whichever model is available
- If both are unavailable, use WebSearch to verify claims directly
- Be honest — if Claude's original statement was wrong, say so clearly
