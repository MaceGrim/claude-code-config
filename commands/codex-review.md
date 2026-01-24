---
allowed-tools: Task
description: Run OpenAI Codex to review a repo, file, or recent changes
argument-hint: <file-path> | --repo | --recent | --staged
---

# Codex Code Review (Subagent)

Delegate code review to the `codex-code-reviewer` subagent to keep the main context clean.

## Current git context

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Recent commits: !`git log --oneline -3 2>/dev/null || echo "no commits"`
- Working directory: !`pwd`

## Instructions

Use the **Task tool** with `subagent_type: "codex-code-reviewer"` to delegate the review.

Based on `$ARGUMENTS`, construct the appropriate prompt for the subagent:

### Mode 1: Review a specific file

If the argument is a file path (e.g., `src/main.js`, `./utils.py`):

```
Task(
  subagent_type: "codex-code-reviewer",
  description: "Codex review: $ARGUMENTS",
  prompt: "Review the file $ARGUMENTS using codex exec. Focus on:
    1. SECURITY (CRITICAL): Injection vulnerabilities, auth issues, data exposure, hardcoded secrets, OWASP top 10
    2. BUGS (HIGH): Null handling, race conditions, off-by-one, edge cases, error handling, resource leaks
    3. PERFORMANCE (MEDIUM): O(n²) algorithms, memory leaks, blocking I/O, missing caching
    4. MAINTAINABILITY (LOW): Dead code, duplication, unclear naming, complexity
    5. TESTING GAPS: Untested edge cases, missing error path coverage

    Return a structured report with:
    - Each finding rated CRITICAL/HIGH/MEDIUM/LOW with line numbers
    - Concrete code fixes for each issue
    - Summary: total issues by severity and code health score (1-10)"
)
```

### Mode 2: Review the entire repo

If the argument is `--repo` or empty:

```
Task(
  subagent_type: "codex-code-reviewer",
  description: "Codex repo review",
  prompt: "Analyze this repository using codex exec. Cover:
    1. PROJECT STRUCTURE: Organization, separation of concerns, dependency graph
    2. SECURITY AUDIT: Hardcoded secrets, exposed endpoints, auth gaps, vulnerable patterns
    3. DEPENDENCY HEALTH: Outdated packages, CVEs, unnecessary deps, version conflicts
    4. CODE PATTERNS: Design patterns, anti-patterns, god objects, circular deps
    5. DOCUMENTATION: Critical code docs, API clarity, README quality
    6. TECHNICAL DEBT: TODO/FIXME/HACK comments, deprecated code, refactoring needs

    Return a prioritized action plan with concrete next steps."
)
```

### Mode 3: Review recent changes

If the argument is `--recent`:

```
Task(
  subagent_type: "codex-code-reviewer",
  description: "Codex review: recent changes",
  prompt: "Review the most recent git changes (git diff HEAD~1) using codex exec:
    1. CORRECTNESS: Logic errors, edge cases, bugs introduced
    2. BREAKING CHANGES: Backwards compatibility issues
    3. SECURITY IMPLICATIONS: New vulnerabilities, input validation, sensitive data
    4. COMPLETENESS: Missing tests, migrations, config updates
    5. CONVENTIONS: Project patterns and style consistency
    6. REVIEW VERDICT: APPROVE, REQUEST CHANGES, or BLOCK?

    Return: 'X critical issues, Y improvements suggested, verdict: [APPROVE/CHANGES/BLOCK]'"
)
```

### Mode 4: Review staged changes

If the argument is `--staged`:

```
Task(
  subagent_type: "codex-code-reviewer",
  description: "Codex review: staged changes",
  prompt: "Review staged git changes (git diff --staged) using codex exec:
    1. CORRECTNESS: Logic errors, edge cases, bugs
    2. BREAKING CHANGES: Backwards compatibility
    3. SECURITY IMPLICATIONS: Vulnerabilities, validation, sensitive data
    4. COMPLETENESS: Missing pieces (tests, migrations, config)
    5. CONVENTIONS: Project patterns and style
    6. COMMIT READINESS: Ready to commit?

    Return: 'Ready to commit: YES/NO - [reason if no]' with specific fixes needed."
)
```

## After the subagent returns

Present the subagent's findings directly to the user. The subagent will have already structured the output, so just relay it with minimal reformatting.
