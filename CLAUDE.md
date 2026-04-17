## About the User

See `~/.claude/USER_PROFILE.md` for information about who I am, my background, preferences, and how I like to work.

---

* Test every single script that you write.
* If any particular program or call to a program times out, ask if you should simplify the program or rerun with more time.
* For each project, create a test_scripts directory. This directory will hold one-off tests that wouldn't otherwise make it into a comprehensive testing of the projects, but are useful for quickly testing small bits of functionality.
* Don't mention Claude in your commit messages EVER
* Never editorialize data or analysis results. Only report what the data actually shows. If you haven't verified a claim numerically, don't make it.
* Before deleting files — whether via `rm`, `git filter-repo`, `git clean`, `git reset --hard`, `find -delete`, moving large directories, or any other destructive operation that could make files unrecoverable — ask whether a copy should be made first. This applies to working-tree files, tracked files, and anything reachable only through git history. "Ask first" is the default even when the user has asked for the deletion; confirm the backup decision specifically.

## Wiki Knowledge Base

When Mason asks a technical "how do I", "what's the best way to", or "how should I approach" question, check `/mnt/o/obsidian_vault/wiki/index.md` for relevant concept pages before answering from general knowledge. The wiki contains detailed, source-cited concept pages from decomposed books and other sources. Follow links into concept pages for code recipes and detailed explanations. Prefer wiki-sourced answers over general knowledge when available — they're more specific and cite exact sources.

When Mason is writing articles, blog posts, or visual essays, check the **Communication Lenses** section of the wiki index for lenses on explanation design, data visualization, and storytelling structure. The lens pages link to detailed raw analyses in `raw/reading-notes/` — read those when you need depth on a specific technique or practitioner. After applying any lens, increment its count and append a log entry in `/mnt/o/obsidian_vault/wiki/concepts/_usage-tracker.md`.

## Obsidian Vault

Mason's Obsidian vault is at `/mnt/o/obsidian_vault/` (WSL path for `O:\obsidian_vault`).

- **Read and write directly** — the vault is just markdown files, no MCP server needed
- **Use `[[wiki links]]`** to connect notes (e.g., `[[Project Name]]` links to `Project Name.md`)
- **Use `[[Note#Heading]]`** to link to specific sections
- **Use tags** like `#project` or `#project/subtype` for categorization
- **Use YAML frontmatter** at the top of notes for metadata (status, date, tags, etc.)
- If Mason asks you to "take notes" or "log this", write to the vault unless told otherwise
- **When to use Obsidian vs CLAUDE.md:** Obsidian is Mason's persistent knowledge base — write there for context he wants to keep long-term (client feedback, decisions, design principles, meeting notes, status). Project CLAUDE.md files are tactical instructions for the AI — write there for things that should shape how code gets built (data sources, file paths, editorial direction, build patterns). There's natural overlap, and that's fine. When in doubt, add to both.

## Autonomous Task Execution

For autonomous task execution, use the Ralph workflow with Claude Code's native task tools.

### Quick Task (simple projects)
```
/ralph "Build X that does Y. Done when Z. Verify: command"
```

### Full Pipeline (complex projects)
```
/seed   → Interviews you → writes SPEC.md → asks to continue
        ↓ (if yes)
        → /adversarial-spec → multi-model debate → PRD.md + prd.json → asks to implement
        ↓ (if yes)
        → /ralph → spawns subagents per task → autonomous until done
```

Just run `/seed "your project idea"` and it chains through the whole pipeline with confirmations at each step.

### Skill Reference

| Skill | Purpose | Output |
|-------|---------|--------|
| `/seed` | Deep interview to capture requirements | SPEC.md |
| `/adversarial-spec` | Multi-model debate (Claude, Codex, Gemini) | PRD.md, TECH_SPEC.md, prd.json |
| `/ralph` | Autonomous execution with fresh context per task | Completed code |
| `/ralph status` | Check task progress | TaskList + attempt history |
| `/council` | Ask Claude, Codex, and Gemini to weigh in on a question | Synthesized answer |

### How /ralph Works

1. **Creates tasks** - From prd.json, inline description, or interview
2. **Uses Claude Code native tools** - TaskCreate, TaskList, TaskUpdate
3. **Spawns subagents** - Each task gets a fresh context via Task tool
4. **Verifies results** - Runs test commands to confirm completion
5. **Retries with context** - Failed attempts inform future retries
6. **Saves progress** - ralph-progress.json survives session interruptions

### Ralph Features

| Feature | How it works |
|---------|--------------|
| Fresh context per task | Subagents don't accumulate context pollution |
| Retry with learning | Failed attempts logged with diagnosis, inform next retry |
| Session recovery | ralph-progress.json preserves state across sessions |
| Max 3 attempts | Stops after 3 failures, reports what went wrong |
| Parallel execution | Unblocked tasks can run simultaneously |

### Tips

- **Always include verification commands** - "Verify: pytest tests/" or "Verify: curl localhost:3000"
- **Break large tasks into subtasks** - Ralph works best with focused, single-purpose tasks
- **Use /seed for complex projects** - The interview captures requirements thoroughly
- **Check progress with `/ralph status`** - See what's done, in progress, or blocked
- **Recovery is automatic** - If session dies, just run `/ralph` again

### Key Files

- `~/.claude/commands/ralph.md` - Ralph loop skill
- `~/.claude/commands/adversarial-spec.md` - Multi-model spec debate
- `~/.claude/commands/seed.md` - Deep interview for SPEC.md
- `~/.claude/commands/council.md` - Multi-model consultation
- `ralph-progress.json` - Progress file (created per project)
