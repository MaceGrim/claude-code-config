---
allowed-tools: Bash(codex:*), Bash(git:*)
description: Run OpenAI Codex to review a repo, file, or recent changes
argument-hint: <file-path> | --repo | --recent | --staged
---

# Codex Code Review

Use OpenAI Codex CLI to perform a comprehensive code review.

## Current git context

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Recent commits: !`git log --oneline -3 2>/dev/null || echo "no commits"`

## Instructions

Based on `$ARGUMENTS`, determine the review mode and run the appropriate codex command.

### Mode 1: Review a specific file

If the argument is a file path (e.g., `src/main.js`, `./utils.py`):

```bash
codex exec "Review the file $ARGUMENTS with focus on:

1. SECURITY (CRITICAL): Check for injection vulnerabilities (SQL, command, XSS), authentication/authorization issues, data exposure, hardcoded secrets, OWASP top 10 violations.

2. BUGS (HIGH): Identify null/undefined handling issues, race conditions, off-by-one errors, unhandled edge cases, improper error handling, resource leaks.

3. PERFORMANCE (MEDIUM): Flag O(n²) or worse algorithms, potential memory leaks, unnecessary re-renders, blocking I/O in async contexts, missing caching opportunities.

4. MAINTAINABILITY (LOW): Note dead code, code duplication, unclear naming, missing type annotations, overly complex functions, magic numbers/strings.

5. TESTING GAPS: Identify untested edge cases, missing error path coverage, assertions that should exist.

Format your response as:
- Rate each finding as CRITICAL/HIGH/MEDIUM/LOW severity
- Provide specific line numbers
- Include concrete code fixes for each issue
- End with a summary: total issues by severity and overall code health score (1-10)"
```

### Mode 2: Review the entire repo

If the argument is `--repo` or empty:

```bash
codex exec "Analyze this repository's architecture and code quality:

1. PROJECT STRUCTURE: Is the codebase well-organized? Are concerns properly separated? Is the dependency graph clean or tangled?

2. SECURITY AUDIT: Scan for hardcoded secrets/API keys, exposed sensitive endpoints, missing authentication checks, vulnerable patterns, insecure dependencies.

3. DEPENDENCY HEALTH: Identify outdated packages, known vulnerabilities (CVEs), unnecessary dependencies, version conflicts, missing lock files.

4. CODE PATTERNS: Are design patterns used consistently? Identify anti-patterns, god objects, circular dependencies, tight coupling.

5. DOCUMENTATION: Is critical code documented? Are public APIs clear? Is there a README with setup instructions?

6. TECHNICAL DEBT: Identify TODO/FIXME/HACK comments, deprecated code still in use, areas needing refactoring.

Prioritize findings by impact and effort. Provide a prioritized action plan with concrete next steps for improving the codebase."
```

### Mode 3: Review recent changes

If the argument is `--recent`:

```bash
codex exec "Review the most recent git changes (run: git diff HEAD~1) as a thorough code reviewer:

1. CORRECTNESS: Does this change introduce bugs? Are there logic errors? Does it handle edge cases?

2. BREAKING CHANGES: Could this break existing functionality? Are there backwards compatibility issues?

3. SECURITY IMPLICATIONS: Does this change introduce vulnerabilities? Are inputs validated? Is sensitive data handled properly?

4. COMPLETENESS: Is the change complete? Are there missing pieces (tests, migrations, config updates)?

5. CONVENTIONS: Does it follow project patterns and style? Are names clear and consistent?

6. REVIEW VERDICT: Would you APPROVE, REQUEST CHANGES, or BLOCK this PR?

Be specific about what needs fixing. For each issue, provide the exact code change needed. Summarize as: 'X critical issues, Y improvements suggested, verdict: [APPROVE/CHANGES/BLOCK]'"
```

### Mode 4: Review staged changes

If the argument is `--staged`:

```bash
codex exec "Review the staged git changes (run: git diff --staged) before commit:

1. CORRECTNESS: Does this change introduce bugs? Are there logic errors? Does it handle edge cases?

2. BREAKING CHANGES: Could this break existing functionality? Are there backwards compatibility issues?

3. SECURITY IMPLICATIONS: Does this change introduce vulnerabilities? Are inputs validated? Is sensitive data handled properly?

4. COMPLETENESS: Is the change complete? Are there missing pieces (tests, migrations, config updates)?

5. CONVENTIONS: Does it follow project patterns and style? Are names clear and consistent?

6. COMMIT READINESS: Is this ready to commit or should changes be made first?

Be specific about what needs fixing. For each issue, provide the exact code change needed. End with: 'Ready to commit: YES/NO - [reason if no]'"
```

## After running codex

Present the findings to the user with:
1. Executive summary (1-2 sentences)
2. Critical issues requiring immediate attention
3. Recommended improvements by priority
4. Overall assessment and next steps
