#!/bin/bash
# Hook: Load context files and repo orientation at session start

# Build context in a temp file to avoid string escaping issues
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

# Load global CLAUDE.md if exists
if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
    echo "=== GLOBAL CLAUDE.MD ===" >> "$TMPFILE"
    head -100 "$HOME/.claude/CLAUDE.md" >> "$TMPFILE"
    echo -e "\n" >> "$TMPFILE"
fi

# Load user profile if exists
if [[ -f "$HOME/.claude/USER_PROFILE.md" ]]; then
    echo "=== USER PROFILE ===" >> "$TMPFILE"
    head -100 "$HOME/.claude/USER_PROFILE.md" >> "$TMPFILE"
    echo -e "\n" >> "$TMPFILE"
fi

# Load project CLAUDE.md if exists (in current dir or .claude/)
if [[ -f "./CLAUDE.md" ]]; then
    echo "=== PROJECT CLAUDE.MD ===" >> "$TMPFILE"
    head -100 "./CLAUDE.md" >> "$TMPFILE"
    echo -e "\n" >> "$TMPFILE"
elif [[ -f "./.claude/CLAUDE.md" ]]; then
    echo "=== PROJECT CLAUDE.MD ===" >> "$TMPFILE"
    head -100 "./.claude/CLAUDE.md" >> "$TMPFILE"
    echo -e "\n" >> "$TMPFILE"
fi

# Load project README if exists
if [[ -f "./README.md" ]]; then
    echo "=== PROJECT README (first 80 lines) ===" >> "$TMPFILE"
    head -80 "./README.md" >> "$TMPFILE"
    echo -e "\n" >> "$TMPFILE"
fi

# Get repo structure (if in a git repo or has common project files)
if [[ -d ".git" ]] || [[ -f "package.json" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Cargo.toml" ]]; then
    echo "=== PROJECT STRUCTURE ===" >> "$TMPFILE"
    echo "Current directory: $(pwd)" >> "$TMPFILE"

    # Git info if available
    if [[ -d ".git" ]]; then
        BRANCH=$(git branch --show-current 2>/dev/null)
        echo "Git branch: ${BRANCH:-detached}" >> "$TMPFILE"
        echo "Recent commits:" >> "$TMPFILE"
        git log --oneline -5 2>/dev/null >> "$TMPFILE"
        echo "" >> "$TMPFILE"
    fi

    # Top-level structure
    echo "Top-level contents:" >> "$TMPFILE"
    ls -la --color=never 2>/dev/null | head -30 >> "$TMPFILE"
    echo "" >> "$TMPFILE"

    # Key directories
    for dir in src lib app components pages api tests test; do
        if [[ -d "./$dir" ]]; then
            echo "$dir/ contents:" >> "$TMPFILE"
            ls -la --color=never "./$dir" 2>/dev/null | head -20 >> "$TMPFILE"
            echo "" >> "$TMPFILE"
        fi
    done
fi

# Output plain text directly (matches bd prime output format)
echo "# Session Context"
echo ""
cat "$TMPFILE"
echo ""
echo "---"
echo "Take a moment to understand the project structure and any specific instructions before proceeding."

exit 0
