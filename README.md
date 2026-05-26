# Claude Code Configuration

This repository contains my complete Claude Code setup, including commands, skills, hooks, plugins, and settings. Use this to replicate my configuration on new machines.

## Autonomous Workflow

The core workflow for autonomous task execution:

```
/seed   --> Interviews you --> writes SPEC.md --> asks to continue
        |
        v (if yes)
/adversarial-spec --> multi-model debate --> PRD.md + prd.json --> asks to implement
        |
        v (if yes)
/ralph  --> spawns subagents per task --> autonomous until done
```

Just run `/seed "your project idea"` and it chains through the whole pipeline with confirmations at each step.

### Quick Task (simple projects)
```
/ralph "Build X that does Y. Done when Z. Verify: command"
```

### Skill Reference

| Skill | Purpose | Output |
|-------|---------|--------|
| `/seed` | Deep interview to capture requirements | SPEC.md |
| `/adversarial-spec` | Multi-model debate (Claude, Codex, Gemini) | PRD.md, TECH_SPEC.md, prd.json |
| `/ralph` | Autonomous execution with fresh context per task | Completed code |
| `/ralph status` | Check task progress | TaskList + attempt history |
| `/council` | Ask Claude, Codex, and Gemini to weigh in on a question | Synthesized answer |

---

## Quick Start (For Claude Code)

**Setting up on macOS?** Read [`MAC_MIGRATION.md`](./MAC_MIGRATION.md) instead — it handles the WSL-specific paths in `CLAUDE.md` and the zsh/bashrc differences.

If you're a Claude Code instance reading this to install the configuration, follow these exact steps:

### Step 1: Run the Installation Script

```bash
cd ~/claude-code-config  # or wherever this repo was cloned
chmod +x install.sh
./install.sh
```

This will install:
- `CLAUDE.md` - Global instructions
- Custom commands (ralph, adversarial-spec, seed, council, etc.)
- Skills (gemini-image)
- Hooks (atomic-commit-guard, session-context, ntfy notifications, etc.)
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
/plugins install playwright
/plugins install code-simplifier
/plugins install claude-hud
```

Optional (disabled by default):
```
/plugins install claude-scientific-writer
```

### Step 4: Configure ntfy Notifications (Optional)

For push notifications when Claude finishes long-running tasks:

1. Pick a topic name at [ntfy.sh](https://ntfy.sh) (e.g., `my-claude-notifications`)
2. Subscribe on your phone via the ntfy app
3. Edit `~/.claude/settings.json` and replace `YOUR-TOPIC-HERE` with your topic name

### Step 5: Install Skill Prerequisites

For the **gemini-image** skill:
```bash
pip install google-genai pillow
```

Then add to your shell profile (~/.bashrc or ~/.zshrc):
```bash
export GEMINI_API_KEY='your-api-key-here'
```

For **multi-model debate** (/adversarial-spec, /council):
```bash
# OpenAI Codex CLI
npm install -g @openai/codex
codex login

# Google Gemini CLI
npm install -g @google/gemini-cli
gemini auth login
```

### Step 6: Verify Installation

Restart Claude Code and verify:
1. Run `/ralph status` to test the ralph command
2. Run `/plugins list` to see installed plugins
3. The status line should show the claude-hud output

---

## Configuration Details

### Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/ralph` | Autonomous execution loop with fresh context per task | `/ralph` or `/ralph "task"` |
| `/adversarial-spec` | Multi-model debate to create PRD + Tech Spec | `/adversarial-spec` |
| `/seed` | Deep project interview to create SPEC.md | `/seed <project idea>` |
| `/council` | Ask Claude, Codex, and Gemini for perspectives | `/council <question>` |
| `/atomic-commit` | Create small, focused atomic commits | `/atomic-commit` |
| `/prep-for-commit` | Simplify and review code before committing | `/prep-for-commit` |
| `/implement-spec` | Implement from TECH_SPEC.md with parallel agents | `/implement-spec` |
| `/setup-agents` | Setup multi-agent project structure | `/setup-agents` |
| `/dayprep` | Plan your day - fetches todos, checks calendars | `/dayprep` |
| `/done` | Mark a task complete in Todoist and remove from calendar | `/done <task name>` |
| `/codex-review` | Run OpenAI Codex to review code | `/codex-review <file>` |

### Skills

| Skill | Description | Prerequisites |
|-------|-------------|---------------|
| gemini-image | Generate images using Google Gemini/Imagen API | `pip install google-genai pillow`, `GEMINI_API_KEY` env var |

### Hooks

| Hook | Trigger | Description |
|------|---------|-------------|
| session-context.sh | SessionStart | Loads project context (CLAUDE.md, README, structure) into session |
| atomic-commit-guard.py | PreToolUse (Bash) | Blocks oversized commits, enforces atomic commit standards |
| check-readme-after-commit.sh | PostToolUse (Bash) | After git commits, prompts to check if README needs updating |
| codex-review-after-commit.sh | PostToolUse (Bash) | Optionally triggers Codex review after commits |
| notify-job-done.py | Notification | Sends push notification via ntfy when Claude finishes |

### Plugins

**From claude-plugins-official:**
- `frontend-design` - Create distinctive, production-grade frontend interfaces
- `github` - GitHub integration for PR management
- `pr-review-toolkit` - Comprehensive PR review tools (code-reviewer, pr-test-analyzer, silent-failure-hunter, etc.)
- `pyright-lsp` - Python type checking via Pyright LSP
- `playwright` - Browser automation and testing
- `code-simplifier` - Simplify and refine code for clarity

**From claude-hud:**
- `claude-hud` - Status line display with context info

**Optional:**
- `claude-scientific-writer` - Scientific writing assistance (disabled by default)

### Settings

#### settings.json
- Hooks configuration (PreToolUse, PostToolUse, SessionStart, Notification)
- Status line using claude-hud
- Enabled plugins list

#### settings.local.json
- Additional permissions (powershell, docker, web search/fetch)
- Codex/Gemini CLI permissions for multi-model debate
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
│   ├── adversarial-spec.md        # Multi-model spec debate
│   ├── atomic-commit.md           # Atomic commit workflow
│   ├── codex-review.md            # OpenAI Codex code review
│   ├── council.md                 # Multi-model consultation
│   ├── dayprep.md                 # Daily planning assistant
│   ├── done.md                    # Task completion helper
│   ├── implement-spec.md          # Spec implementation
│   ├── prep-for-commit.md         # Pre-commit review
│   ├── ralph.md                   # Autonomous task executor
│   ├── seed.md                    # Project spec interviewer
│   └── setup-agents.md            # Multi-agent setup
├── skills/
│   └── gemini-image/
│       ├── SKILL.md               # Skill definition
│       └── scripts/
│           └── generate.py        # Image generation script
└── hooks/
    ├── atomic-commit-guard.py     # Commit size guard
    ├── check-readme-after-commit.sh  # README update checker
    ├── codex-review-after-commit.sh  # Post-commit Codex review
    ├── notify-job-done.py         # ntfy push notifications
    └── session-context.sh         # Session context loader
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
cp hooks/*.sh hooks/*.py ~/.claude/hooks/
cp settings.json.template ~/.claude/settings.json
cp settings.local.json.template ~/.claude/settings.local.json

# Make executable
chmod +x ~/.claude/hooks/*.sh
chmod +x ~/.claude/hooks/*.py
chmod +x ~/.claude/skills/gemini-image/scripts/generate.py
```

---

## External Dependencies

These integrations are assumed but require separate setup:

### Required Tools

1. **OpenAI Codex CLI** - For multi-model debate and codex-review
   - Install: `npm install -g @openai/codex`
   - Auth: `codex login`

2. **Google Gemini CLI** - For multi-model debate
   - Install: `npm install -g @google/gemini-cli`
   - Auth: `gemini auth login`

### Optional: ntfy Push Notifications

[ntfy.sh](https://ntfy.sh) provides free push notifications. When Claude finishes a task, you get notified on your phone.

1. Install the ntfy app on your phone
2. Subscribe to a topic (e.g., `my-claude-notifications`)
3. Edit `~/.claude/settings.json`:
   - Find `ntfy.sh/YOUR-TOPIC-HERE`
   - Replace `YOUR-TOPIC-HERE` with your topic name

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
- The atomic commit guard blocks commits with >5 files or >300 lines changed (use `[bulk]` to override)
