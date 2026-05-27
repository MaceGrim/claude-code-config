#!/bin/bash
# Claude Code Configuration Installer
#
# This script installs the Claude Code configuration from this repository.
# Run from the cloned repository directory.
#
# Usage: ./install.sh [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    log_warn "Dry run mode - no changes will be made"
fi

run_cmd() {
    if $DRY_RUN; then
        echo "  Would run: $*"
    else
        "$@"
    fi
}

# Check if Claude Code is installed
check_claude_code() {
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLI not found. Please install it first:"
        echo "  npm install -g @anthropic-ai/claude-code"
        exit 1
    fi
    log_success "Claude Code CLI found"
}

# Create necessary directories
create_directories() {
    log_info "Creating directory structure..."
    run_cmd mkdir -p "$CLAUDE_DIR/commands"
    run_cmd mkdir -p "$CLAUDE_DIR/skills"
    run_cmd mkdir -p "$CLAUDE_DIR/agents"
    run_cmd mkdir -p "$CLAUDE_DIR/hooks"
    log_success "Directories created"
}

# Install CLAUDE.md
install_claude_md() {
    log_info "Installing CLAUDE.md (global instructions)..."
    if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
        log_warn "CLAUDE.md already exists - backing up to CLAUDE.md.bak"
        run_cmd cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
    fi
    run_cmd cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    log_success "CLAUDE.md installed"
}

# Install commands
install_commands() {
    log_info "Installing custom commands..."
    for cmd in "$SCRIPT_DIR"/commands/*.md; do
        if [[ -f "$cmd" ]]; then
            local name=$(basename "$cmd")
            run_cmd cp "$cmd" "$CLAUDE_DIR/commands/$name"
            log_success "  Installed command: ${name%.md}"
        fi
    done
}

# Install skills
install_skills() {
    log_info "Installing skills..."
    for skill_dir in "$SCRIPT_DIR"/skills/*/; do
        if [[ -d "$skill_dir" ]]; then
            local name
            name=$(basename "$skill_dir")
            # Remove any existing copy so the install is clean and we don't
            # accumulate stale files removed upstream.
            if [[ -d "$CLAUDE_DIR/skills/$name" ]]; then
                run_cmd rm -rf "$CLAUDE_DIR/skills/$name"
            fi
            # Strip the trailing slash so macOS BSD cp creates a wrapping
            # subdir instead of dumping the source's contents at the top
            # level of the destination.
            run_cmd cp -r "${skill_dir%/}" "$CLAUDE_DIR/skills/"
            if compgen -G "$CLAUDE_DIR/skills/$name/scripts/*" > /dev/null; then
                run_cmd chmod +x "$CLAUDE_DIR/skills/$name/scripts/"*
            fi
            log_success "  Installed skill: $name"
        fi
    done
}

# Install agents
install_agents() {
    log_info "Installing agents..."
    for agent in "$SCRIPT_DIR"/agents/*.md; do
        if [[ -f "$agent" ]]; then
            local name
            name=$(basename "$agent")
            run_cmd cp "$agent" "$CLAUDE_DIR/agents/$name"
            log_success "  Installed agent: ${name%.md}"
        fi
    done
}

# Install hooks
install_hooks() {
    log_info "Installing hooks..."
    # Install shell hooks
    for hook in "$SCRIPT_DIR"/hooks/*.sh; do
        if [[ -f "$hook" ]]; then
            local name=$(basename "$hook")
            run_cmd cp "$hook" "$CLAUDE_DIR/hooks/$name"
            run_cmd chmod +x "$CLAUDE_DIR/hooks/$name"
            log_success "  Installed hook: $name"
        fi
    done
    # Install Python hooks
    for hook in "$SCRIPT_DIR"/hooks/*.py; do
        if [[ -f "$hook" ]]; then
            local name=$(basename "$hook")
            run_cmd cp "$hook" "$CLAUDE_DIR/hooks/$name"
            run_cmd chmod +x "$CLAUDE_DIR/hooks/$name"
            log_success "  Installed hook: $name"
        fi
    done
}

# Install multi-account profile support (setup-profiles.sh + claude-profiles.sh)
install_profiles() {
    log_info "Installing multi-account profile scripts..."
    if [[ -f "$SCRIPT_DIR/setup-profiles.sh" ]]; then
        run_cmd cp "$SCRIPT_DIR/setup-profiles.sh" "$CLAUDE_DIR/setup-profiles.sh"
        run_cmd chmod +x "$CLAUDE_DIR/setup-profiles.sh"
        log_success "  Installed setup-profiles.sh"
    fi
    if [[ -f "$SCRIPT_DIR/claude-profiles.sh" ]]; then
        run_cmd cp "$SCRIPT_DIR/claude-profiles.sh" "$CLAUDE_DIR/claude-profiles.sh"
        log_success "  Installed claude-profiles.sh"
    fi
}

# Install sync/doctor tooling + machine-readable spec files
install_tooling() {
    log_info "Installing sync/doctor tooling..."
    if [[ -f "$SCRIPT_DIR/doctor.sh" ]]; then
        run_cmd cp "$SCRIPT_DIR/doctor.sh" "$CLAUDE_DIR/doctor.sh"
        run_cmd chmod +x "$CLAUDE_DIR/doctor.sh"
        log_success "  Installed: doctor.sh"
    fi
    for f in plugins.txt tool-versions.txt; do
        if [[ -f "$SCRIPT_DIR/$f" ]]; then
            run_cmd cp "$SCRIPT_DIR/$f" "$CLAUDE_DIR/$f"
            log_success "  Installed: $f"
        fi
    done
    # Stamp the repo commit so doctor.sh can detect install-vs-repo drift.
    if git -C "$SCRIPT_DIR" rev-parse HEAD >/dev/null 2>&1; then
        run_cmd bash -c "git -C '$SCRIPT_DIR' rev-parse HEAD > '$CLAUDE_DIR/.installed-commit'"
        log_success "  Stamped .installed-commit"
    fi
}

# Install settings
install_settings() {
    log_info "Installing settings..."

    if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
        log_warn "settings.json already exists - backing up to settings.json.bak"
        run_cmd cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
    fi

    if [[ -f "$CLAUDE_DIR/settings.local.json" ]]; then
        log_warn "settings.local.json already exists - backing up to settings.local.json.bak"
        run_cmd cp "$CLAUDE_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json.bak"
    fi

    run_cmd cp "$SCRIPT_DIR/settings.json.template" "$CLAUDE_DIR/settings.json"
    run_cmd cp "$SCRIPT_DIR/settings.local.json.template" "$CLAUDE_DIR/settings.local.json"
    log_success "Settings installed"
}

# Print plugin installation instructions
print_plugin_instructions() {
    log_info "Plugin installation requires manual steps in Claude Code:"
    echo ""
    echo "  1. Start Claude Code: claude"
    echo "  2. Add marketplaces:"
    echo "     /plugins marketplace add anthropics/claude-plugins-official"
    echo "     /plugins marketplace add jarrodwatts/claude-hud"
    echo "     /plugins marketplace add k-dense-ai/claude-scientific-writer"
    echo ""
    echo "  3. Install plugins:"
    echo "     /plugins install frontend-design"
    echo "     /plugins install github"
    echo "     /plugins install pr-review-toolkit"
    echo "     /plugins install pyright-lsp"
    echo "     /plugins install playwright"
    echo "     /plugins install code-simplifier"
    echo "     /plugins install claude-hud"
    echo ""
    echo "  4. Optional: /plugins install claude-scientific-writer"
    echo ""
}

# Print multi-account profile setup instructions
print_profile_instructions() {
    log_info "Multi-account profile setup (optional):"
    echo ""
    echo "  To isolate work and personal Claude Code accounts:"
    echo "    bash ~/.claude/setup-profiles.sh"
    echo ""
    echo "  Then source the profile aliases from your shell rc:"
    echo "    Linux/WSL:  echo 'source ~/.claude/claude-profiles.sh' >> ~/.bashrc"
    echo "    macOS:      echo 'source ~/.claude/claude-profiles.sh' >> ~/.zshrc"
    echo ""
    echo "  Log in per profile:"
    echo "    HOME=~/.claude-profiles/work claude login"
    echo "    HOME=~/.claude-profiles/personal claude login"
    echo ""
    echo "  Use:  claude-work, claude-personal, claude-work-dsp, claude-personal-dsp"
    echo ""
}

# Print skill prerequisites
print_skill_prerequisites() {
    log_info "Skill prerequisites:"
    echo ""
    echo "  gemini-image skill requires:"
    echo "    - Python packages: pip install google-genai pillow"
    echo "    - Environment variable: export GEMINI_API_KEY='your-api-key'"
    echo ""
    echo "  Multi-model debate (/adversarial-spec, /council) requires:"
    echo "    - OpenAI Codex: npm install -g @openai/codex && codex login"
    echo "    - Google Gemini: npm install -g @google/gemini-cli && gemini auth login"
    echo ""
    echo "  ntfy notifications (optional):"
    echo "    - Edit ~/.claude/settings.json"
    echo "    - Replace YOUR-TOPIC-HERE with your ntfy topic"
    echo "    - Install ntfy app on phone and subscribe to topic"
    echo ""
}

# Main installation
main() {
    echo ""
    echo "========================================"
    echo "  Claude Code Configuration Installer"
    echo "========================================"
    echo ""

    check_claude_code
    create_directories
    install_claude_md
    install_commands
    install_skills
    install_agents
    install_hooks
    install_profiles
    install_tooling
    install_settings

    echo ""
    echo "========================================"
    echo "  Installation Complete!"
    echo "========================================"
    echo ""

    print_plugin_instructions
    print_profile_instructions
    print_skill_prerequisites

    log_success "Configuration installed to $CLAUDE_DIR"
    echo ""
}

main
