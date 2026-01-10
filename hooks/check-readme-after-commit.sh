#!/bin/bash
# Hook: Check if README needs updating after git commits

INPUT=$(cat)

# Extract command using grep/sed (no jq dependency)
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

# Only act on git commits
if [[ ! "$COMMAND" =~ git\ commit ]]; then
    exit 0
fi

# Get what changed in the commit (handles root commits too)
CHANGED=$(git show --name-only --format="" HEAD 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

# Skip if we couldn't get changes (not in a git repo, etc.)
if [[ -z "$CHANGED" ]]; then
    exit 0
fi

# Return context that prompts Claude to review
cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "A commit just completed. Files changed: ${CHANGED}\n\nPlease review: 1) Read README.md if it exists, 2) Check the committed changes with 'git show HEAD', 3) If the changes affect documented features, installation, usage, or API but README wasn't updated, tell me what specific sections need updating. If changes are trivial or README is already accurate, say nothing."
  }
}
EOF
