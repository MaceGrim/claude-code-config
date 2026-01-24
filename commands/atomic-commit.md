---
allowed-tools: Bash(git:*), Bash(git add:*), Bash(git reset:*), Bash(git diff:*), Bash(git status:*), Bash(git commit:*)
description: Create small, focused atomic commits. Use when committing changes.
argument-hint: [message]
---

# Atomic Commit Helper

Create small, focused commits that each address ONE logical change.

## Atomic Commit Standards

1. **One concern per commit** - Each commit should do exactly one thing
2. **Max 5 files** - If touching more, split into multiple commits
3. **Max 300 lines changed** - Large changes should be broken up
4. **Self-contained** - Each commit should leave the codebase working
5. **Clear message** - Describe the WHY, not just the WHAT

## Current State

- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Staged: !`git diff --cached --stat 2>/dev/null | tail -1 || echo "nothing staged"`
- Unstaged: !`git diff --stat 2>/dev/null | tail -1 || echo "nothing unstaged"`

## Process

### Step 1: Review all changes

```bash
git status
git diff --stat
```

### Step 2: Group changes by concern

Identify logical groupings:
- Feature additions
- Bug fixes
- Refactoring
- Tests
- Documentation
- Configuration

### Step 3: Stage incrementally

Use interactive staging for fine-grained control:

```bash
# Stage specific files
git add path/to/file.py

# Stage specific hunks within a file
git add --patch path/to/file.py
# (s)plit, (y)es, (n)o, (q)uit
```

### Step 4: Verify staged changes

```bash
git diff --cached --stat
git diff --cached  # Review actual changes
```

If more than 5 files or 300 lines, go back and split further.

### Step 5: Commit with clear message

Format: `type: brief description`

Types:
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code restructuring
- `test:` adding tests
- `docs:` documentation
- `chore:` maintenance

```bash
git commit -m "type: what this commit does"
```

### Step 6: Repeat for remaining changes

Continue staging and committing until all changes are committed.

## Example Workflow

```bash
# Bad: One giant commit
git add .
git commit -m "update everything"  # BLOCKED by hook

# Good: Multiple focused commits
git add src/auth/login.py
git commit -m "feat: add password validation"

git add src/auth/tests/test_login.py
git commit -m "test: add password validation tests"

git add README.md
git commit -m "docs: document new password requirements"
```

## If Blocked by Hook

The atomic commit guard will block commits that are too large. When blocked:

1. `git reset HEAD` - Unstage everything
2. `git add -p` - Interactively stage related changes
3. Commit smaller logical units
4. Repeat until done

## Argument Handling

If `$ARGUMENTS` is provided, use it as the commit message after staging appropriate changes.
