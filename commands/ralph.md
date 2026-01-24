---
allowed-tools: Bash, Read, Write, Glob, Grep, Edit, Task, TaskCreate, TaskUpdate, TaskList, TaskGet, AskUserQuestion
description: Run autonomous Ralph loop using Claude Code native task tools - fresh context each iteration until all tasks pass
argument-hint: [task description] or [status|reset]
---

# Ralph Loop - Native Claude Code Task Orchestrator

Run an autonomous agent loop that works through tasks until all pass. Uses Claude Code's native TaskCreate/TaskList/TaskUpdate tools for tracking, and spawns fresh subagents via the Task tool.

**Key features:**
- Fresh context per task (subagents)
- Progress file (`ralph-progress.json`) for recovery
- Retry with context - failed attempts inform future retries
- Automatic verification after each task

```
+----------------------------------------------------------------------+
|                     THE RALPH LOOP (Native)                          |
|                                                                      |
|   orchestrator:                                                      |
|       tasks = TaskCreate(from prd.json or inline)                    |
|       save_progress()  # ralph-progress.json                         |
|       while pending_tasks:                                           |
|           task = find_unblocked_pending()                            |
|           previous_attempts = get_attempts(task)                     |
|           result = Task(subagent, prompt + previous_attempts)        |
|           verify(result)                                             |
|           record_attempt(task, result)                               |
|           save_progress()                                            |
|                                                                      |
+----------------------------------------------------------------------+
```

## Commands

```bash
/ralph                            # Run tasks from prd.json or continue existing
/ralph "Build X that does Y"      # Quick task with inline description
/ralph status                     # Show current task progress
/ralph reset                      # Clear all tasks and start fresh
```

## Progress File: ralph-progress.json

Ralph maintains a progress file for:
- **Recovery** - Resume after session interruption
- **Attempt history** - Track what was tried and why it failed
- **Context for retries** - Subagents learn from previous failures

```json
{
  "project": "Project Name",
  "started": "2024-01-23T10:00:00Z",
  "lastUpdated": "2024-01-23T11:30:00Z",
  "source": "prd.json | inline | interview",
  "tasks": {
    "1": {
      "subject": "Initialize project structure",
      "status": "completed",
      "verify": "npm run build",
      "attempts": [
        {
          "timestamp": "2024-01-23T10:05:00Z",
          "result": "success",
          "filesModified": ["package.json", "tsconfig.json"]
        }
      ]
    },
    "2": {
      "subject": "Implement scoring engine",
      "status": "failed",
      "verify": "npm test -- --grep scoring",
      "attempts": [
        {
          "timestamp": "2024-01-23T10:15:00Z",
          "result": "failed",
          "error": "TypeError: Cannot read property 'rank' of undefined",
          "diagnosis": "Function called with empty array, no null check",
          "filesModified": ["src/scoring.ts"],
          "approachTaken": "Created basic function but missed empty input edge case"
        },
        {
          "timestamp": "2024-01-23T10:25:00Z",
          "result": "failed",
          "error": "Expected 2 but got 0",
          "diagnosis": "Pair detection only checks adjacent cards",
          "filesModified": ["src/scoring.ts"],
          "approachTaken": "Added null check but pair logic needs all combinations"
        }
      ]
    }
  }
}
```

**When to read:** At startup, check for `ralph-progress.json` to resume
**When to write:** After each task attempt (success or failure)

## Task Sources (Priority Order)

1. **Existing Claude Code tasks** - Check TaskList first, continue if tasks exist
2. **prd.json** - From `/adversarial-spec` (convert stories to TaskCreate)
3. **Inline task** - `/ralph "description"` → break into subtasks → TaskCreate
4. **Interview** - If nothing found and no description, ask what to build

## Instructions

### Step 1: Parse Arguments

Parse `$ARGUMENTS`:
- `status` → Show TaskList and exit
- `reset` → Clear tasks and exit
- Other text → Task description
- Empty → Check for existing tasks or prd.json

### Step 2: Check Current State

Check both TaskList AND progress file:

```
tasks = TaskList()
progress = Read("ralph-progress.json") if exists
```

**If ralph-progress.json exists:**
- This is a resume - sync TaskList with progress file
- Load attempt history for failed tasks
- Show: "Resuming from ralph-progress.json..."
- Skip to Step 5 (Run Loop)

**If tasks exist in TaskList (no progress file):**
- Create ralph-progress.json from TaskList state
- Continue with pending unblocked tasks
- Skip to Step 5 (Run Loop)

**If no tasks exist:**
- Check for prd.json → Step 3a
- Check for inline description → Step 3b
- Neither → Step 3c (Interview)

### Step 3: Create Tasks

#### 3a: From prd.json (adversarial-spec output)

Read prd.json and convert each story to a task:

```
For each story in prd.json.stories:
    TaskCreate(
        subject=story.title,
        description="""
Story: {story.description}

Acceptance Criteria:
{story.acceptance_criteria}

Verification Command: {story.test_command}
""",
        activeForm="Working on {story.title}"
    )
```

Set up dependencies based on priority (P0 first, then P1, then P2):
- P1 tasks blocked by all P0 tasks
- P2 tasks blocked by all P1 tasks

#### 3b: From Inline Description

Analyze the task description. If it's complex, break it into subtasks.

**For each subtask:**
```
TaskCreate(
    subject="[Subtask title]",
    description="""
[What to build]

Acceptance Criteria:
- [Criterion 1]
- [Criterion 2]

Verification Command: [command to verify]
""",
    activeForm="[Present participle form]"
)
```

Set up dependencies with TaskUpdate(addBlockedBy=[...]) where appropriate.

#### 3c: Interview Mode

If no tasks and no description provided:

```
AskUserQuestion:
1. What do you want to build?
2. How will you know it's done? (specific, testable criteria)
3. What command verifies success?
```

Then create tasks from responses.

### Step 4: Display Task Plan

After creating tasks, show the plan:

```
+----------------------------------------------------------------------+
                         RALPH TASK PLAN
+----------------------------------------------------------------------+

Tasks created:
  #1 [pending] Task title
  #2 [pending] Task title [blocked by #1]
  #3 [pending] Task title [blocked by #1, #2]
  ...

Ready to start orchestration loop.
+----------------------------------------------------------------------+
```

### Step 5: Run the Orchestration Loop

This is the core Ralph loop using native Claude Code tools:

```
MAX_ATTEMPTS_PER_TASK = 3
MAX_ITERATIONS = 50
iteration = 0

while iteration < MAX_ITERATIONS:
    # Get current task state
    tasks = TaskList()
    progress = load_progress()

    # Find pending/failed unblocked tasks that haven't exceeded max attempts
    ready_tasks = [t for t in tasks
                   if (t.status == 'pending' or t.status == 'in_progress')
                   and not t.blockedBy
                   and get_attempt_count(progress, t.id) < MAX_ATTEMPTS_PER_TASK]

    if not ready_tasks:
        if all_completed(tasks):
            # SUCCESS - all done
            break
        elif any_exceeded_attempts(progress):
            # STUCK - some tasks failed too many times
            output "Some tasks failed after max attempts. See ralph-progress.json"
            break
        else:
            # BLOCKED - waiting on something
            output "All remaining tasks are blocked. Check dependencies."
            break

    iteration += 1

    for task in ready_tasks:
        # Mark as in progress
        TaskUpdate(task.id, status="in_progress")

        # Get full task details + previous attempts
        task_details = TaskGet(task.id)
        previous_attempts = get_attempts(progress, task.id)

        # Spawn subagent with fresh context + attempt history
        result = Task(
            description="Ralph: {task.subject}",
            prompt=generate_subagent_prompt(task_details, previous_attempts),
            subagent_type="general-purpose"
        )

        # Parse subagent result
        parsed = parse_subagent_result(result)

        # Verify the result
        verification = extract_verification_command(task_details)
        if verification:
            verify_result = Bash(verification)
            success = verify_result.exit_code == 0
        else:
            success = parsed.result == "SUCCESS"

        # Record the attempt
        attempt = {
            "timestamp": now(),
            "result": "success" if success else "failed",
            "error": parsed.error if not success else null,
            "diagnosis": parsed.diagnosis if not success else null,
            "filesModified": parsed.files_changed,
            "approachTaken": parsed.approach
        }
        record_attempt(progress, task.id, attempt)
        save_progress(progress)

        if success:
            TaskUpdate(task.id, status="completed")
            output "✓ Task #{task.id} completed"
        else:
            attempts_left = MAX_ATTEMPTS_PER_TASK - get_attempt_count(progress, task.id)
            if attempts_left > 0:
                output "✗ Task #{task.id} failed - {attempts_left} retries remaining"
            else:
                output "✗ Task #{task.id} failed after {MAX_ATTEMPTS_PER_TASK} attempts"

    # Brief status update
    show_progress_summary(progress)
```

### Subagent Prompt Template

For each task, spawn a subagent with this prompt:

```
You are a Ralph subagent working on a single task. You have fresh context.

## Your Task
{task.subject}

{task.description}

## Verification Command
{task.verify_command}

{if previous_attempts}
## Previous Attempts (IMPORTANT - Learn from these!)

This task has been attempted before. DO NOT repeat the same mistakes.

{for attempt in previous_attempts}
### Attempt {attempt.number} - {attempt.result}
- **Error:** {attempt.error}
- **Diagnosis:** {attempt.diagnosis}
- **Approach taken:** {attempt.approachTaken}
- **Files modified:** {attempt.filesModified}
{endfor}

**Your job:** Fix what previous attempts got wrong. The diagnosis above tells you what needs to change.
{endif}

## Your Mission
1. Implement what's needed to complete this task
2. Run the verification command to confirm it works
3. If verification passes, report SUCCESS
4. If verification fails, diagnose WHY and report clearly
5. Commit your changes with a descriptive message

## Rules
- Focus ONLY on this one task
- If retrying, address the diagnosed issues from previous attempts
- Test before claiming done
- Commit your changes
- Report back with structured output below

## Output Format (REQUIRED)
When done, output exactly this format:

RESULT: [SUCCESS|FAILURE]
VERIFICATION_OUTPUT: [full output of verification command]
FILES_CHANGED: [comma-separated list of files]
APPROACH: [1-2 sentence description of what you did]
{if failure}
ERROR: [the error message]
DIAGNOSIS: [why it failed - be specific, this helps the next retry]
{endif}
```

### Step 6: Completion

When all tasks are completed:

```
+----------------------------------------------------------------------+
                         RALPH LOOP COMPLETE
+----------------------------------------------------------------------+

All tasks completed!
Iterations: [N]
Total attempts: [M] (across all tasks)

Final task status:
  [x] #1: Task title (1 attempt)
  [x] #2: Task title (3 attempts)
  ...

Progress saved to: ralph-progress.json
+----------------------------------------------------------------------+
```

**On failure (max attempts exceeded):**

```
+----------------------------------------------------------------------+
                         RALPH LOOP PAUSED
+----------------------------------------------------------------------+

Some tasks failed after maximum attempts.

Failed tasks:
  [!] #2: Task title (3 attempts - see history below)

Last attempt for #2:
  Error: [error message]
  Diagnosis: [what went wrong]
  Approach: [what was tried]

To retry with fresh approach:
  1. Review ralph-progress.json for attempt history
  2. Manually fix the issue OR
  3. Run /ralph to continue (will retry failed tasks)

+----------------------------------------------------------------------+
```

### Step 7: Recovery (After Session Interruption)

If a session ends mid-execution, ralph-progress.json preserves state:

```bash
/ralph              # Detects ralph-progress.json, resumes automatically
/ralph status       # Shows progress including attempt history
```

Recovery process:
1. Read ralph-progress.json
2. Sync TaskList with saved state
3. Resume from first incomplete task
4. Retain attempt history for context

## Handling `status` Command

```
TaskList()
```

Display formatted:
```
+----------------------------------------------------------------------+
                         RALPH STATUS
+----------------------------------------------------------------------+

[x] #1: Completed task
[>] #2: In progress task
[ ] #3: Pending task
[ ] #4: Pending task [blocked by #3]

Progress: 1/4 completed, 1 in progress, 2 pending
+----------------------------------------------------------------------+
```

## Handling `reset` Command

Ask for confirmation, then:
```
Clear all tasks from TaskList (note: Claude Code tasks auto-clear on completion)
```

Output:
```
Tasks cleared. Run /ralph again to start fresh.
```

## Architecture

| Component | Purpose |
|-----------|---------|
| TaskList | Active task state (Claude Code native) |
| ralph-progress.json | Persistent progress + attempt history |
| Subagents | Fresh context per task execution |
| Orchestrator | Coordinates loop, doesn't accumulate context |

**Why both TaskList and ralph-progress.json?**
- TaskList: Native UI integration, real-time status
- ralph-progress.json: Survives sessions, stores attempt history for retry context

## Examples

```bash
# Full pipeline (recommended)
/seed                    # Create SPEC.md
/adversarial-spec        # Create PRD.md + prd.json
/ralph                   # Execute tasks from prd.json

# Quick task
/ralph "Build a REST API with /users endpoint. Done when curl localhost:3000/users returns 200."

# Check progress
/ralph status

# Start over
/ralph reset
```

## Tips

- **Parallel execution**: Unblocked tasks can run simultaneously
- **Fresh context**: Each subagent starts clean, no pollution from failures
- **Retry with learning**: Failed attempts inform future retries via attempt history
- **Recovery**: ralph-progress.json survives session interruptions
- **Orchestrator stays lean**: Only tracks progress, doesn't accumulate implementation details
- **Dependencies matter**: Set them up correctly so tasks run in the right order
- **Verification is key**: Always include a test command so success is objective
- **Diagnosis matters**: When subagents fail, their diagnosis helps the next attempt succeed

## Troubleshooting

**Task keeps failing after 3 attempts:**
- Check ralph-progress.json for attempt history
- The diagnosis field shows what went wrong each time
- Consider simplifying the task or breaking it into subtasks

**Session interrupted:**
- Just run `/ralph` again - it resumes from ralph-progress.json
- TaskList will be synced with saved progress

**Want to retry a failed task with fresh history:**
- Edit ralph-progress.json to remove attempts for that task
- Or run `/ralph reset` to start completely fresh
