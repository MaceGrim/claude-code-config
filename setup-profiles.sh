#!/bin/bash
# Setup Claude Code multi-account profiles
# Creates isolated profile directories for work (Team) and personal accounts.
# Shared config (commands, skills, hooks) is symlinked from canonical ~/.claude/.
# Credentials and session state are per-profile.
#
# Works on WSL/Linux and macOS. REAL_HOME defaults to $HOME; override by
# exporting REAL_HOME before running.

set -euo pipefail

REAL_HOME="${REAL_HOME:-$HOME}"
PROFILES_DIR="$REAL_HOME/.claude-profiles"

# Shared Claude config (symlinked into each profile's .claude/)
# These are read-mostly resources that should be the same across accounts.
SHARED_CLAUDE_ITEMS=(
    "commands"
    "skills"
    "hooks"
    "plugins"
    "agents"
    "chrome"
    "settings.json"
    "settings.local.json"
    "CLAUDE.md"
    "USER_PROFILE.md"
    "AI_WORKFLOW.md"
    "agent-personas.md"
    "doc_map.md"
    "claude-profiles.sh"
    "setup-profiles.sh"
)

# Home-level dotfiles/dirs to symlink back to real HOME.
# These ensure tools like git, nvm, conda, ssh etc. work with the HOME override.
# Missing entries are skipped, so this list is safe across platforms.
HOME_DOTFILES=(
    ".gitconfig"
    ".ssh"
    ".nvm"
    ".bashrc"
    ".bash_logout"
    ".bash_profile"
    ".profile"
    ".zshrc"
    ".zprofile"
    ".zshenv"
    ".local"
    ".config"
    ".npm"
    ".netrc"
    ".aws"
    ".azure"
    ".codex"
    ".gemini"
    ".conda"
    ".docker"
    ".ipython"
    ".jupyter"
    "bin"
    "miniconda3"
    "anaconda3"
    "mcp_agent_mail"
)

# Per-profile directories (created fresh, NOT symlinked)
PROFILE_CLAUDE_DIRS=(
    "projects"
    "session-env"
    "tasks"
    "debug"
    "todos"
    "cache"
    "file-history"
    "shell-snapshots"
    "plans"
    "statsig"
    "telemetry"
    "ide"
    "paste-cache"
    "downloads"
)

setup_profile() {
    local profile_name="$1"
    local profile_dir="$PROFILES_DIR/$profile_name"
    local claude_dir="$profile_dir/.claude"

    echo "=== Setting up profile: $profile_name ==="

    mkdir -p "$claude_dir"

    for dir in "${PROFILE_CLAUDE_DIRS[@]}"; do
        mkdir -p "$claude_dir/$dir"
    done

    echo "  Linking shared Claude config..."
    for item in "${SHARED_CLAUDE_ITEMS[@]}"; do
        local source="$REAL_HOME/.claude/$item"
        local target="$claude_dir/$item"
        if [ -e "$source" ] && [ ! -e "$target" ]; then
            ln -s "$source" "$target"
            echo "    .claude/$item -> canonical"
        elif [ ! -e "$source" ]; then
            echo "    .claude/$item (skipped, source doesn't exist)"
        elif [ -e "$target" ]; then
            echo "    .claude/$item (already exists, skipping)"
        fi
    done

    echo "  Linking HOME dotfiles..."
    for item in "${HOME_DOTFILES[@]}"; do
        local source="$REAL_HOME/$item"
        local target="$profile_dir/$item"
        if [ -e "$source" ] && [ ! -e "$target" ]; then
            ln -s "$source" "$target"
            echo "    $item -> real HOME"
        elif [ ! -e "$source" ]; then
            echo "    $item (skipped, source doesn't exist)"
        elif [ -e "$target" ]; then
            echo "    $item (already exists, skipping)"
        fi
    done

    echo ""
    echo "  Profile '$profile_name' ready at: $profile_dir"
    echo "  Login with: HOME=$profile_dir claude login"
    echo ""
}

echo "Creating Claude Code multi-account profiles..."
echo "REAL_HOME:       $REAL_HOME"
echo "Profiles dir:    $PROFILES_DIR"
echo ""

mkdir -p "$PROFILES_DIR"

setup_profile "work"
setup_profile "personal"

echo "========================================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Login to each profile:"
echo "     HOME=$PROFILES_DIR/work claude login"
echo "     HOME=$PROFILES_DIR/personal claude login"
echo ""
echo "  2. Source the profile aliases from your shell rc:"
echo "     echo 'source ~/.claude/claude-profiles.sh' >> ~/.bashrc  # or ~/.zshrc on macOS"
echo "     source ~/.bashrc  # or ~/.zshrc"
echo ""
echo "  3. Use the new commands:"
echo "     claude-work          # Team account"
echo "     claude-personal      # Personal account"
echo "     claude-work-dsp      # Team + skip permissions"
echo "     claude-personal-dsp  # Personal + skip permissions"
echo "     (all support -c for continue, -r for resume)"
echo "========================================="
