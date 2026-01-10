# Claude Code Configuration

This repository contains my complete Claude Code setup, including commands, skills, hooks, plugins, and settings. Use this to replicate my configuration on new machines.

## Quick Start (For Claude Code)

If you're a Claude Code instance reading this to install the configuration, follow these exact steps:

### Step 1: Run the Installation Script

```bash
cd ~/claude-code-config  # or wherever this repo was cloned
chmod +x install.sh
./install.sh
```

This will install:
- `CLAUDE.md` - Global instructions
- Custom commands (dayprep, done, seed, codex-review)
- Skills (gemini-image)
- Hooks (check-readme-after-commit.sh)
- Settings templates

### Step 2: Install Plugin Marketplaces

Run these commands in Claude Code:

```
/plugins marketplace add anthropics/claude-plugins-official
/plugins marketplace add jarrodwatts/claude-hud
/plugins marketplace add k-dense-ai/claude-scientific-writer
```

### Step 3: Install Plugins

Install each plugin (run in Claude Code):

```
/plugins install frontend-design
/plugins install github
/plugins install pr-review-toolkit
/plugins install pyright-lsp
/plugins install ralph-wiggum
/plugins install playwright
/plugins install code-simplifier
/plugins install claude-hud
```

Optional (disabled by default):
```
/plugins install claude-scientific-writer
```

### Step 4: Install Beads (bd)

The hooks use `bd` (Beads) for task tracking. Install it:

```bash
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

Or via npm:
```bash
npm install -g @beads/bd
```

Verify installation:
```bash
bd --version
```

### Step 5: Install Skill Prerequisites

For the **gemini-image** skill:
```bash
pip install google-genai pillow
```

Then add to your shell profile (~/.bashrc or ~/.zshrc):
```bash
export GEMINI_API_KEY='your-api-key-here'
```

### Step 6: Verify Installation

Restart Claude Code and verify:
1. Run `/dayprep` to test the dayprep command
2. Run `/plugins list` to see installed plugins
3. The status line should show the claude-hud output

---

## Configuration Details

### Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/dayprep` | Plan your day - fetches todos, checks calendars, prioritizes, and schedules | `/dayprep` |
| `/done` | Mark a task complete in Todoist and remove from calendar | `/done <task name>` |
| `/seed` | Deep project interview to create SPEC.md with zero ambiguity | `/seed <project idea>` |
| `/codex-review` | Run OpenAI Codex to review code | `/codex-review <file>\|--repo\|--recent\|--staged` |

### Skills

| Skill | Description | Prerequisites |
|-------|-------------|---------------|
| gemini-image | Generate images using Google Gemini/Imagen API | `pip install google-genai pillow`, `GEMINI_API_KEY` env var |

### Hooks

| Hook | Trigger | Description |
|------|---------|-------------|
| check-readme-after-commit.sh | PostToolUse (Bash) | After git commits, prompts to check if README needs updating |
| bd prime | SessionStart, PreCompact | Loads Beads issue context into session (requires `bd` installed) |

### Plugins

**From claude-plugins-official:**
- `frontend-design` - Create distinctive, production-grade frontend interfaces
- `github` - GitHub integration for PR management
- `pr-review-toolkit` - Comprehensive PR review tools (code-reviewer, pr-test-analyzer, silent-failure-hunter, etc.)
- `pyright-lsp` - Python type checking via Pyright LSP
- `ralph-wiggum` - Ralph Wiggum quotes
- `playwright` - Browser automation and testing
- `code-simplifier` - Simplify and refine code for clarity

**From claude-hud:**
- `claude-hud` - Status line display with context info

**From claude-scientific-writer (disabled by default):**
- `claude-scientific-writer` - Scientific writing assistance

### Settings

#### settings.json
- Hooks configuration (PostToolUse, PreCompact, SessionStart)
- Status line using claude-hud
- Enabled plugins list
- Base permissions for BuildEngine commands

#### settings.local.json
- Additional permissions (powershell, docker, web search/fetch)
- Machine-specific overrides

#### CLAUDE.md (Global Instructions)
- Always test scripts
- Create test_scripts directories for projects
- Maintain doc_map.md for documentation references
- Never mention AI in commit messages

---

## File Structure

```
claude-code-config/
├── README.md                      # This file
├── install.sh                     # Installation script
├── CLAUDE.md                      # Global instructions
├── settings.json.template         # Main settings template
├── settings.local.json.template   # Local settings template
├── plugins.json                   # Plugin/marketplace reference
├── commands/
│   ├── codex-review.md            # OpenAI Codex code review
│   ├── dayprep.md                 # Daily planning assistant
│   ├── done.md                    # Task completion helper
│   └── seed.md                    # Project spec interviewer
├── skills/
│   └── gemini-image/
│       ├── SKILL.md               # Skill definition
│       └── scripts/
│           └── generate.py        # Image generation script
└── hooks/
    └── check-readme-after-commit.sh  # README update checker
```

---

## Manual Installation (Alternative)

If the install script doesn't work, manually copy files:

```bash
# Create directories
mkdir -p ~/.claude/{commands,skills/gemini-image/scripts,hooks}

# Copy files
cp CLAUDE.md ~/.claude/
cp commands/*.md ~/.claude/commands/
cp skills/gemini-image/SKILL.md ~/.claude/skills/gemini-image/
cp skills/gemini-image/scripts/generate.py ~/.claude/skills/gemini-image/scripts/
cp hooks/*.sh ~/.claude/hooks/
cp settings.json.template ~/.claude/settings.json
cp settings.local.json.template ~/.claude/settings.local.json

# Make executable
chmod +x ~/.claude/hooks/*.sh
chmod +x ~/.claude/skills/gemini-image/scripts/generate.py
```

---

## External Dependencies

These integrations are assumed but require separate setup:

### Required Tools

1. **Beads (bd)** - Distributed issue tracker for session hooks
   - Repo: https://github.com/steveyegge/beads
   - Install: `curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash`
   - Or: `npm install -g @beads/bd`
   - Used by: SessionStart hook, PreCompact hook (`bd prime`)

2. **OpenAI Codex CLI** - For codex-review command
   - Install: `npm install -g @openai/codex`

### MCP Servers (configure separately)

3. **Todoist MCP Server** - For dayprep and done commands
   - Requires Todoist API token

4. **Google Calendar MCP Server** - For dayprep command
   - Requires Google OAuth setup

Configure MCP servers in Claude Code settings based on your accounts.

---

## Notes

- Settings templates use `$HOME` paths that should work cross-platform
- The statusLine command dynamically finds the claude-hud installation path
- Permissions in settings.local.json may need adjustment for your specific use cases
- Plugin versions may differ; the install commands will get the latest versions
