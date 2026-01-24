---
allowed-tools: Bash(git:*), Bash(codex:*), Task
description: Simplify and review code before committing
argument-hint: [--staged | --all]
---

# Prep for Commit

Prepare your changes for a clean commit by running simplification and review.

## Current git context

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Staged files: !`git diff --staged --name-only 2>/dev/null | head -10 || echo "none"`
- Unstaged files: !`git diff --name-only 2>/dev/null | head -10 || echo "none"`

## Instructions

Based on `$ARGUMENTS`, determine which changes to prep:
- `--staged` (default): Only staged changes
- `--all`: Both staged and unstaged changes

### Step 1: Identify changed files

```bash
# For --staged or default
git diff --staged --name-only

# For --all
git diff --name-only && git diff --staged --name-only
```

Get the list of changed files. Skip binary files and files over 500 lines changed.

### Step 2: Run Code Simplifier

Use the Task tool to launch the `code-simplifier:code-simplifier` agent:

```
Simplify and refine the following recently modified files for clarity, consistency, and maintainability while preserving all functionality:

[LIST OF CHANGED FILES]

Focus on:
- Removing unnecessary complexity
- Improving readability
- Consistent formatting
- Removing dead code
- Simplifying conditionals

Do NOT change functionality. Make minimal, targeted improvements.
```

Wait for the simplifier to complete and review its changes.

### Step 3: Stage simplifier changes (if any)

If the simplifier made changes, stage them:

```bash
git add -u  # Only previously tracked files
```

### Step 4: Run Codex Review

Run a pre-commit review on the staged changes:

```bash
codex -q "Review this staged diff for commit readiness. Be concise.

Focus on:
1. Bugs or logic errors
2. Security issues
3. Missing error handling
4. Incomplete changes

$(git diff --staged)

End with: READY TO COMMIT: YES/NO - [brief reason if no]"
```

### Step 5: Present Summary

Give the user a clear summary:

1. **Simplification changes**: What the code-simplifier improved (if anything)
2. **Review findings**: Critical issues from Codex (if any)
3. **Commit readiness**: YES/NO with explanation
4. **Suggested commit message**: Based on the changes

If there are issues, offer to fix them. If ready, ask if the user wants to proceed with the commit.
