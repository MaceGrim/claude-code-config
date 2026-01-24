---
allowed-tools: Bash(codex:*), Bash(gemini:*), Bash(git:*), Bash(cat:*), Read, Glob, Grep
description: Ask multiple AI models (Claude, Codex, Gemini) to weigh in on a question or review
argument-hint: <question or topic> [--files file1,file2] [--context "additional context"]
---

# AI Council

Gather perspectives from multiple AI models on a question, decision, or code review.

## Available Models

| Model | CLI | Status |
|-------|-----|--------|
| Claude | (this session) | Always available |
| Codex | `codex exec` | !`which codex > /dev/null && echo "✓ Installed" \|\| echo "✗ Not installed"` |
| Gemini | `gemini -p` | !`which gemini > /dev/null && echo "✓ Installed" \|\| echo "✗ Not installed (npm i -g @anthropic-ai/gemini-cli or pip install gemini-cli)"` |

## Instructions

### Step 1: Parse Arguments

Parse `$ARGUMENTS` to extract:
- **Question/Topic**: The main thing to get perspectives on
- **--files**: Optional comma-separated list of files to include as context
- **--context**: Optional additional context string

If no arguments provided, ask the user what they want the council to discuss.

### Step 2: Gather Context

Based on the question type, gather relevant context:

**For code questions:**
- Read specified files (--files) or detect relevant files
- Get git status if in a repo
- Include recent changes if relevant

**For architecture/design questions:**
- Read project structure
- Include relevant config files
- Note existing patterns

**For general questions:**
- Include any specified context
- Keep focused on what's relevant

Create a context summary (max ~2000 tokens) that will be passed to each model.

### Step 3: Formulate the Query

Create a structured query for each model:

```
CONTEXT:
[gathered context here]

QUESTION:
[user's question]

Please provide your perspective on this. Consider:
1. What are the key tradeoffs?
2. What would you recommend and why?
3. What risks or concerns do you see?
4. What alternatives should be considered?

Be specific and actionable in your response.
```

### Step 4: Query Each Available Model

**Claude (this session):**
You ARE Claude - provide your perspective directly in your response. Think through the question carefully.

**Codex (if available):**
```bash
codex exec --skip-git-repo-check "CONTEXT:
[context]

QUESTION:
[question]

Provide your perspective. Consider tradeoffs, recommendations, risks, and alternatives. Be specific and actionable."
```

**Gemini (if available):**
```bash
gemini -p "CONTEXT:
[context]

QUESTION:
[question]

Provide your perspective. Consider tradeoffs, recommendations, risks, and alternatives. Be specific and actionable."
```

Run available model queries in parallel if possible.

### Step 5: Present the Council's Perspectives

Format the output as:

```
================================================================================
                              AI COUNCIL RESULTS
================================================================================

QUESTION: [the question asked]

--------------------------------------------------------------------------------
                            CLAUDE (Opus 4.5)
--------------------------------------------------------------------------------

[Claude's perspective - your own analysis]

Key points:
- [bullet points]

Recommendation: [specific recommendation]

--------------------------------------------------------------------------------
                            CODEX (GPT-4)
--------------------------------------------------------------------------------

[Codex's response]

Key points:
- [bullet points]

Recommendation: [specific recommendation]

--------------------------------------------------------------------------------
                            GEMINI
--------------------------------------------------------------------------------

[Gemini's response, or "Not available - install with: npm i -g @google/gemini-cli"]

Key points:
- [bullet points]

Recommendation: [specific recommendation]

================================================================================
                              COUNCIL SUMMARY
================================================================================

CONSENSUS:
[Areas where models agree]

DIVERGENCE:
[Areas where models disagree and why]

SYNTHESIS:
[Your synthesis of the perspectives - what seems like the best path forward]

RECOMMENDED ACTION:
[Specific next steps based on council input]

================================================================================
```

## Examples

### Example 1: Architecture Question
```
/council Should we use microservices or a monolith for this project? --files package.json,README.md
```

### Example 2: Code Review
```
/council Review this implementation for potential issues --files src/auth/login.ts
```

### Example 3: Design Decision
```
/council What state management approach should we use? --context "React app, 50+ components, real-time updates needed"
```

### Example 4: General Question
```
/council What's the best way to handle rate limiting in our API?
```

## Installing Missing Models

**Gemini CLI:**
```bash
# Option 1: npm
npm install -g @google/gemini-cli

# Option 2: pip
pip install google-generativeai

# Then authenticate
gemini auth login
```

**Codex CLI:**
```bash
npm install -g @openai/codex
codex login
```

## Notes

- Each model may have different context limits; context is trimmed if needed
- Responses are gathered in parallel when possible
- If a model fails, the council continues with available models
- The synthesis section is Claude's job - combine perspectives into actionable guidance
