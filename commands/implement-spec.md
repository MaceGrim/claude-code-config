# Implement Spec

Read a spec file, break it into tasks with dependencies, setup agents, and launch a swarm to implement it.

## Prerequisites

- TECH_SPEC.md (from `/adversarial-spec`) or SPEC.md (from `/seed`) exists in the current project
- MCP Agent Mail server running (`am`)
- Beads CLI installed (`bd`)

## Instructions

### Step 1: Check Prerequisites

1. Get current working directory with `pwd`
2. Check for spec files in this order:
   - **TECH_SPEC.md** (preferred - output from `/adversarial-spec`)
   - **SPEC.md** (fallback - output from `/seed`)
   - If neither exists, suggest running `/seed` → `/adversarial-spec`
3. Check Agent Mail server is running:
   ```bash
   curl -s http://127.0.0.1:8765/mcp/ -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}' 2>/dev/null || echo "NOT_RUNNING"
   ```
   If not running, tell user to run `am` in a separate terminal and wait for confirmation.
4. Check `bd` is available: `which bd`
5. Initialize beads if needed: `bd init` (if .beads/ doesn't exist)

### Step 2: Read and Analyze the Spec

1. Read the spec file (TECH_SPEC.md or SPEC.md)
2. Identify the major components/features described
3. Break down into implementable tasks

**Task breakdown guidelines:**
- Each task should be completable in one coding session
- Identify clear deliverables for each task
- Note which tasks depend on others
- Categorize by type: frontend, backend, cli, devops, testing, docs, etc.

### Step 3: Create Tasks in Beads

For each identified task, create it in Beads with appropriate labels and dependencies.

**Use these labels to categorize:**
- `frontend` - UI, components, styles
- `backend` - API, services, data, config
- `cli` - Command-line interfaces
- `devops` - CI/CD, deployment, infrastructure
- `testing` - Tests, fixtures, coverage
- `docs` - Documentation
- `security` - Security-related tasks

**Creating tasks (NOTE: use `--deps` not `--depends-on`):**
```bash
# Simple task
bd create "Task title" --label backend

# Task with dependency (use task ID or title)
bd create "Build user profile page" --label frontend --deps <dependency-task-id>

# Task with multiple labels
bd create "Add authentication API" --label backend --label security
```

**Dependency rules:**
- Setup/infrastructure tasks come first
- Config files before code that uses them
- Data models before API endpoints
- API endpoints before CLI/frontend that uses them
- Core features before enhancements
- Implementation before tests

### Step 4: Show Task Graph

After creating all tasks, show the user what was created:

```bash
bd list --status=open  # Show all open tasks
```

Present a summary:
```
Created X tasks from TECH_SPEC.md:

Backend (Y tasks):
  - task-id-1: Create config file
  - task-id-2: Implement API server

CLI (Z tasks):
  - task-id-3: Implement CLI client

Testing (W tasks):
  - task-id-4: Create pytest fixtures
  - task-id-5: Write integration tests

Dependencies identified:
  - task-id-2 depends on task-id-1 (config)
  - task-id-3 depends on task-id-1 (config)
  - task-id-4 depends on task-id-2 (server)
  - task-id-5 depends on task-id-3 (cli)
```

### Step 5: Determine Required Agent Personas

Based on the task labels, determine which agent personas are needed:

- If `frontend` tasks exist → need Frontend agent (Claude)
- If `backend` tasks exist → need Backend agent (Claude)
- If `cli` tasks exist → need CLI agent (Claude)
- If `testing` tasks exist → need Tester agent (Claude)
- If `devops` tasks exist → need DevOps agent (Claude)
- If `docs` tasks exist → need Docs agent (Claude)
- **Always include a Reviewer agent (Codex)** - uses different model for diversity

Ask user to confirm the agent lineup:
```
Based on your tasks, I recommend these agents:

| Persona  | Model  | Tasks Assigned |
|----------|--------|----------------|
| Backend  | claude | 3 tasks        |
| CLI      | claude | 1 task         |
| Tester   | claude | 2 tasks        |
| Reviewer | codex  | reviews all    |

Add or remove any agents? (or confirm to proceed)
```

Allow user to:
- Add more agents
- Remove suggested agents
- Change models (claude/codex/gemini)
- Add custom personas

### Step 8: Create Directory Structure

Create the launcher infrastructure:
```bash
mkdir -p .agent-prompts .agent-launchers
```

### Step 9: Create Prompt Files

For each agent, create `.agent-prompts/<agent-name-lowercase>.txt`:

**Example for a Worker agent (Backend, CLI, Tester, etc.):**
```
You are <AgentName>, the <ROLE> agent for <project-name>.

## Your Role
You handle all <role> tasks: <task types>.

## Your Tasks
Run: bd list --label <role>
Pick tasks in dependency order:
1. <task-id-1>: <task description>
2. <task-id-2>: <task description>

## Workflow
1. Run `pwd` to confirm your working directory
2. Check available tasks: bd list --label <role>
3. Implement the task following TECH_SPEC.md
4. When done, send message to <ReviewerName> requesting review via Agent Mail
5. **CHECK YOUR INBOX** for reviewer response (use fetch_inbox)
6. If changes requested: fix issues and request review again
7. If approved: bd close <task-id>
8. Move to next task

## Coordination
- <OtherAgent> (<role>) is waiting for your <dependency>
- <ReviewerName> reviews your code
- **After sending review request, check inbox every few minutes for response**

## Rules
- Only work on <role> tasks
- Follow TECH_SPEC.md exactly
- Request review before marking complete
- Always check inbox for reviewer feedback
```

**Example for Reviewer agent (Codex):**
```
You are <AgentName>, the REVIEWER for <project-name>.

## Your Role
You review all code. You NEVER write code directly.

## Workflow
1. Run `pwd` to confirm your working directory
2. Check your inbox using fetch_inbox
3. For each review request:
   - Read the files mentioned
   - Compare against TECH_SPEC.md
   - Send feedback via send_message to the requesting agent
   - If approved: "LGTM - you can close the task with: bd close <task-id>"
   - If changes needed: list specific issues to fix
4. After responding, check inbox AGAIN for new requests
5. Keep polling - new review requests may arrive anytime

## Rules
- NEVER write or modify code yourself
- Review against TECH_SPEC.md standards
- Be thorough but constructive
- Always respond to review requests promptly
```

### Step 10: Create Launcher Scripts

For each agent, create `.agent-launchers/<agent-name-lowercase>.sh`:

**For Claude agents:**
```bash
#!/bin/bash
cd <PROJECT_PATH>
echo 'Starting <Role> agent: <AgentName>'
echo ''

PROMPT=$(cat <PROJECT_PATH>/.agent-prompts/<agent-name-lowercase>.txt)

claude --dangerously-skip-permissions --system-prompt "$PROMPT" "<Initial task instruction>"
exec bash
```

**For Codex agents (must source NVM):**
```bash
#!/bin/bash
cd <PROJECT_PATH>

# Source NVM for codex
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

echo '═══════════════════════════════════════════════════════════'
echo '  REVIEWER AGENT: <AgentName> (Codex)'
echo '═══════════════════════════════════════════════════════════'
echo ''

codex --full-auto "<Initial task instruction with system context>"
exec bash
```

Make all launcher scripts executable:
```bash
chmod +x .agent-launchers/*.sh
```

### Step 11: Create Main Launcher Script

Create `./start-swarm.sh` in the project root:

```bash
#!/bin/bash
# Auto-generated by /implement-spec on <date>
# Launch agent swarm for <project-name>

set -e

PROJECT="<PROJECT_PATH>"
PROJECT_NAME="<PROJECT_NAME>"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Launching Agent Swarm: $PROJECT_NAME${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if Agent Mail server is running
if ! curl -s http://127.0.0.1:8765/mcp/ -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}' > /dev/null 2>&1; then
    echo -e "${RED}Agent Mail server not running. Start it with: am${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Agent Mail server running${NC}"

# Check beads
if ! command -v bd &> /dev/null; then
    echo -e "${RED}Beads CLI not found. Install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Beads CLI available${NC}"

# Show current task status
echo ""
echo -e "${BLUE}Current task status:${NC}"
cd "$PROJECT" && bd list --status=open 2>/dev/null || echo "No tasks found"

echo ""
echo -e "${BLUE}Launching agents...${NC}"

# Launch each agent in a new terminal tab
# CRITICAL: Use bash -l -c to get login shell with proper PATH
# CRITICAL: Call the launcher script directly, don't inline commands

echo -e "${YELLOW}Starting <AgentName> (<Role>)...${NC}"
wt.exe -w 0 new-tab --title "<ROLE> - <AgentName>" wsl.exe -- bash -l -c "$PROJECT/.agent-launchers/<agent-name-lowercase>.sh"

# Repeat for each agent...

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Swarm launched! <N> agents starting.${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Monitor activity: ${BLUE}http://127.0.0.1:8765/mail${NC}"
echo -e "View tasks:       ${BLUE}bd list --status=open${NC}"
echo ""
echo -e "${YELLOW}Agents:${NC}"
echo "  <AgentName>  [<ROLE>]  - <task summary>"
# Repeat for each agent...
```

Make executable: `chmod +x ./start-swarm.sh`

### Step 12: Create Agent Assignment Plan

Create `.agent-assignments.md` in the project root:

```markdown
# Agent Task Assignments

> Auto-generated by `/implement-spec` on <date>

## Overview

| Agent | Role | Model | Assigned Tasks |
|-------|------|-------|----------------|
| <AgentName> | <Role> | claude | <N> |
| <ReviewerName> | Reviewer | codex | reviews all |

## Task Assignments

### <AgentName> [<ROLE>]
- [ ] <task-id>: <task description>
- [ ] <task-id>: <task description>

### <ReviewerName> [REVIEWER]
- Reviews all code before completion
- Provides feedback via Agent Mail
- Never writes code directly

## Workflow

1. Agents check `bd list --label <their-label>` for available tasks
2. Implement following TECH_SPEC.md
3. When done, send message to <ReviewerName> requesting review
4. Reviewer sends feedback via Agent Mail
5. After approval, mark task complete: `bd close <task-id>`

## Dependency Order

```
<ASCII diagram showing task dependencies>
```

## Communication

- **Agent Mail Web UI:** http://127.0.0.1:8765/mail
- **Send review request:** Use `send_message` to <ReviewerName>
- **Check inbox:** Use `fetch_inbox` regularly
```

### Step 13: Output Final Summary

```
================================================================================
                         SPEC IMPLEMENTATION READY
================================================================================

Project: <project name>
Spec: TECH_SPEC.md

TASKS CREATED: <total>
├── Backend: <count> tasks
├── CLI: <count> tasks
├── Testing: <count> tasks
└── Blocked: <count> tasks (waiting on dependencies)

AGENTS CONFIGURED: <count>
┌────────────────┬──────────┬────────┬───────────────┐
│ Agent          │ Role     │ Model  │ Tasks         │
├────────────────┼──────────┼────────┼───────────────┤
│ <AgentName>    │ Backend  │ claude │ <count> tasks │
│ <AgentName>    │ CLI      │ claude │ <count> tasks │
│ <AgentName>    │ Tester   │ claude │ <count> tasks │
│ <ReviewerName> │ Reviewer │ codex  │ reviews all   │
└────────────────┴──────────┴────────┴───────────────┘

FILES CREATED:
  .agent-prompts/        - System prompts for each agent
  .agent-launchers/      - Executable launch scripts
  .agent-assignments.md  - Task assignments per agent
  start-swarm.sh         - Launch all agents

================================================================================
                              NEXT STEPS
================================================================================

1. Review task breakdown:
   $ bd list --status=open

2. Launch the swarm:
   $ ./start-swarm.sh

3. Monitor progress:
   - Web UI: http://127.0.0.1:8765/mail
   - Tasks:  bd list --status=open

================================================================================
```

### Step 14: Launch the Swarm

After showing the summary, automatically run the launcher script:

```bash
./start-swarm.sh
```

This opens terminal windows for each agent and they begin working immediately.

---

## Key Implementation Notes

**Shell Quoting Issues (CRITICAL):**
- NEVER try to inline complex shell commands in `wt.exe ... bash -c "..."`
- ALWAYS use separate launcher scripts in `.agent-launchers/`
- ALWAYS use separate prompt files in `.agent-prompts/`
- This avoids all nested quoting/escaping problems

**Claude CLI:**
- Takes the initial prompt as a **positional argument**, not stdin
- Format: `claude --dangerously-skip-permissions --system-prompt "$PROMPT" "Initial message"`
- Use `--dangerously-skip-permissions` for autonomous operation

**Codex CLI:**
- Requires NVM to be sourced (not in default PATH for nested shells)
- Format: `codex --full-auto "Initial message with context"`
- Does NOT have separate `--system-prompt` flag - include context in the message

**WSL Terminal Launch:**
- Use `bash -l -c` (login shell) to ensure PATH is correct
- Format: `wt.exe -w 0 new-tab --title "TITLE" wsl.exe -- bash -l -c "/path/to/launcher.sh"`

**Beads CLI:**
- Use `--deps` flag for dependencies, NOT `--depends-on`
- Use `--label` for categorization
- Use `bd close <task-id>` to complete tasks
