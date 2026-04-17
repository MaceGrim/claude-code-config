# Log Vibe Code Failure

Log a vibe code failure to today's Obsidian daily note under the **## Vibe Code** section.

If the user provided arguments (e.g., `/log-failure it hallucinated a pandas method`), use that as additional context for what went wrong.

## Step 1: Gather Context Automatically

Before asking the user anything, collect from the current conversation:

- **What happened**: Write a 1-3 sentence description of the failure from your (Claude's) perspective. You were there — describe what went wrong honestly.
- **The prompt**: Find the actual user message(s) that led to the failure. Copy them **verbatim and in full** — do NOT truncate, paraphrase, or summarize. Include all code, context, everything. If the failure spanned multiple messages, include all relevant ones.
- **Resolution**: If the failure has been resolved, note how. If not, write "Unresolved".
- **Working directory**: The current working directory (project context).
- **Session depth**: Rough estimate of how many turns into the conversation you are.
- **Timestamp**: Get the current time via `date +%H:%M`.

## Step 2: Ask the User 4 Questions

Use the AskUserQuestion tool with exactly these 4 questions in a single call:

**Question 1** — "What type of failure?"
- Header: "Type"
- multiSelect: false
- Options:
  1. Label: "Hallucination" — Description: "Invented an API, method, or library that doesn't exist"
  2. Label: "Misunderstanding" — Description: "Requirement interpreted wrong by either side"
  3. Label: "Debugging spiral" — Description: "Fix → break → fix cycle that couldn't converge"
  4. Label: "Overbuilt" — Description: "Way more complex than what was needed"
- (The automatic "Other" option covers: context-loss, vague-spec, moved-goalposts, wrong-approach, silent-bug, scope-creep, or anything else)

**Question 2** — "Who's at fault?"
- Header: "Fault"
- multiSelect: false
- Options:
  1. Label: "LLM" — Description: "The model screwed up"
  2. Label: "Human" — Description: "Vague prompt, changed requirements, skipped verification"
  3. Label: "Miscommunication" — Description: "Neither side wrong — just talked past each other"
  4. Label: "Tooling" — Description: "Context window limit, dependency issue, platform gotcha"

**Question 3** — "How bad was it?"
- Header: "Severity"
- multiSelect: false
- Options:
  1. Label: "Shrug (<2 min)" — Description: "Caught it fast, no real cost"
  2. Label: "Annoying (2-15 min)" — Description: "Cost some real time, had to redirect"
  3. Label: "Painful (15+ min)" — Description: "Significant derail, lost real momentum"
  4. Label: "Session killer" — Description: "Blew up the session, had to start over"

**Question 4** — "What did you actually want to happen?"
- Header: "Expected"
- multiSelect: false
- Options:
  1. Label: "I'll type it" — Description: "Let me describe what I expected in my own words"
- NOTE: This question exists so the user can describe their intent via the "Other" free-text option. The single option is just a placeholder — the user will almost always type a custom response. Include their verbatim answer in the log entry as the **Expected:** field.

## Step 3: Map Answers to Tags

**Type mapping:**
- Hallucination → `#fail/hallucination`
- Misunderstanding → `#fail/misunderstand`
- Debugging spiral → `#fail/spiral`
- Overbuilt → `#fail/overbuilt`
- If "Other": pick the closest from `#fail/context-loss`, `#fail/vague-spec`, `#fail/moved-goalposts`, `#fail/wrong-approach`, `#fail/silent-bug`, `#fail/scope-creep`, or create a new `#fail/[descriptive-slug]`

**Fault mapping:**
- LLM → `#fault/llm`
- Human → `#fault/human`
- Miscommunication → `#fault/comms`
- Tooling → `#fault/tooling`
- If "Other": `#fault/hard-problem` or `#fault/[descriptive-slug]`

**Severity mapping:**
- Shrug (<2 min) → `#sev/shrug`
- Annoying (2-15 min) → `#sev/annoying`
- Painful (15+ min) → `#sev/painful`
- Session killer → `#sev/session-killer`

## Step 4: Find or Create Today's Daily Note

The daily note lives at:
```
/mnt/o/obsidian_vault/Daily/YYYY/MM-MonthName/YYYY-MM-DD.md
```

Use bash to compute the path:
```bash
YEAR=$(date +%Y)
MONTH_FOLDER=$(date +%m-%B)
FILENAME=$(date +%Y-%m-%d)
DAILY_PATH="/mnt/o/obsidian_vault/Daily/${YEAR}/${MONTH_FOLDER}/${FILENAME}.md"
```

If the directory doesn't exist, create it with `mkdir -p`.

If the file doesn't exist, create it with this structure:
```markdown
---
created: YYYY-MM-DD
tags:
  - daily
energy:
---
# DayOfWeek, Month DD, YYYY

<< [[YYYY-MM-DD|Yesterday]] | [[YYYY-MM-DD|Tomorrow]] >>

---

## Work Log


## Vibe Code
```

(Fill in actual dates. Use `date` commands to compute yesterday/tomorrow.)

## Step 5: Append the Entry

Read today's daily note. Append the entry at the **end of the file** (all Vibe Code entries accumulate at the bottom).

If the file exists but has no `## Vibe Code` section, add one before appending.

**Entry format:**

```markdown
- HH:MM — [Your description of what happened, 1-3 sentences, from Claude's perspective]
  #fail/[type] #fault/[fault] #sev/[severity]
  [project: basename_of_cwd | depth: ~N turns | cwd: /full/path]

  **Prompt:**
  > [Full verbatim user prompt in blockquote format]
  > [Every single line — code blocks, context, everything]
  > [Do NOT truncate]

  **Expected:** [What the user actually wanted, in their own words from Question 4]

  **Resolution:** [How it was fixed, or "Unresolved"]
```

Use the Edit tool to append. Make sure there's a blank line before the new entry if there are existing entries.

## Step 6: Confirm

After writing, tell the user:
- A brief summary of what was logged
- The file path
- Remind them that `/log-failure` entries are auto-surfaced in weekly reviews via Dataview
