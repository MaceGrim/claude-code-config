#!/bin/bash
# Hook: Run Codex review after git commits

INPUT=$(cat)

# Extract command
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

# Only act on git commits
if [[ ! "$COMMAND" =~ git\ commit ]]; then
    exit 0
fi

# Source NVM for codex
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Check if codex is available
if ! command -v codex &> /dev/null; then
    exit 0
fi

# Get the diff from the commit
DIFF=$(git show HEAD --stat --patch 2>/dev/null)

# Skip if empty or too large (>200KB)
if [[ -z "$DIFF" ]] || [[ ${#DIFF} -gt 204800 ]]; then
    exit 0
fi

# Run Codex review (quiet mode, capture output)
REVIEW=$(codex -q "You are reviewing a git commit. Be concise and actionable. Focus on:
1. Bugs or logic errors
2. Security issues
3. Missing error handling
4. Code that contradicts the commit message

If everything looks good, just say 'LGTM'. Otherwise list specific issues.

COMMIT DIFF:
$DIFF" 2>&1)

# Return the review as context
cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "CODEX REVIEW OF COMMIT:\n\n${REVIEW//\"/\\\"}\n\nIf Codex found issues, consider addressing them or explain why they're not concerns."
  }
}
EOF
