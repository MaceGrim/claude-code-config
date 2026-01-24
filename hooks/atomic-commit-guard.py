#!/usr/bin/env python3
"""
PreToolUse hook: Block commits that are too large for atomic commit standards.

Exit codes:
  0 = Allow (pass through)
  2 = Block (reject the command)

Override: Include "[bulk]" in commit message to bypass for legitimate bulk operations
"""
import json
import sys
import subprocess

# Configuration
MAX_FILES = 5          # Max files per commit
MAX_INSERTIONS = 300   # Max lines added
MAX_DELETIONS = 300    # Max lines removed

def get_staged_stats():
    """Get statistics about staged changes."""
    result = subprocess.run(
        ["git", "diff", "--cached", "--numstat"],
        capture_output=True,
        text=True,
        timeout=5
    )

    files = 0
    insertions = 0
    deletions = 0

    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        parts = line.split('\t')
        if len(parts) >= 3:
            files += 1
            # Handle binary files (shown as '-')
            ins = int(parts[0]) if parts[0] != '-' else 0
            dels = int(parts[1]) if parts[1] != '-' else 0
            insertions += ins
            deletions += dels

    return files, insertions, deletions

def get_staged_files():
    """Get list of staged files for the error message."""
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        capture_output=True,
        text=True,
        timeout=5
    )
    return [f for f in result.stdout.strip().split('\n') if f]

def main():
    try:
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    command = tool_input.get("command", "")

    # Only validate git commit commands
    if tool_name != "Bash" or "git commit" not in command:
        sys.exit(0)

    # Skip if it's an amend (might be fixing a previous commit)
    if "--amend" in command:
        sys.exit(0)

    # Allow bulk operations when explicitly marked
    if "[bulk]" in command:
        sys.exit(0)

    try:
        files, insertions, deletions = get_staged_stats()
    except Exception:
        sys.exit(0)  # Don't block on errors

    # Check thresholds
    violations = []

    if files > MAX_FILES:
        violations.append(f"  - {files} files staged (max {MAX_FILES})")

    if insertions > MAX_INSERTIONS:
        violations.append(f"  - {insertions} lines added (max {MAX_INSERTIONS})")

    if deletions > MAX_DELETIONS:
        violations.append(f"  - {deletions} lines removed (max {MAX_DELETIONS})")

    if violations:
        staged_files = get_staged_files()

        error_msg = f"""
ATOMIC COMMIT GUARD: Commit blocked

This commit is too large for atomic commit standards:
{chr(10).join(violations)}

Staged files:
{chr(10).join(f'  - {f}' for f in staged_files[:10])}
{'  ... and more' if len(staged_files) > 10 else ''}

To fix this:
1. Use `git reset HEAD` to unstage all files
2. Use `git add --patch` or `git add -p` for interactive staging
3. Group related changes into focused commits
4. Each commit should address ONE logical change

To override for bulk operations (like client handoff cleanup):
  Include [bulk] in your commit message

Example workflow:
  git reset HEAD
  git add -p src/feature.py  # Stage only related hunks
  git commit -m "feat: add validation logic"
  git add -p src/feature.py  # Stage remaining hunks
  git commit -m "feat: add error handling"
"""
        sys.stderr.write(error_msg)
        sys.exit(2)  # Block the commit

    sys.exit(0)  # Allow the commit

if __name__ == "__main__":
    main()
