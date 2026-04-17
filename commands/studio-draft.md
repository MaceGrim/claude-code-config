# Studio Draft — Claude Code Skill

Scaffold a new content project and draft content for Grimshaw Studio.

---

## Step 1: Select an Idea

Pull the target idea from `BACKLOG/ideas.yaml` and update its status to `in-progress`. If no specific idea is provided, present the top 3 candidates from ideas.yaml ranked by score and let Mason choose.

---

## Step 2: Create PROJECTS Folder Structure

Each piece of content gets its own directory under `PROJECTS/`. The directory name should be a slugified version of the title. Create the following structure:

```
PROJECTS/<slug>/
├── brief.md          # Content brief (scope, audience, key points, artifacts needed)
├── outline.md        # Structural outline (hook, main sections, takeaway)
├── draft.md          # The canonical written content
├── artifacts/        # Visualizations, diagrams, charts, screenshots, code samples
└── review/           # Review notes, feedback, revision history
```

### brief.md

The content brief frames the piece before writing begins. It must contain:

- **Scope** — What this piece covers and what it does not
- **Audience** — Who is reading this, matched to the pillar's audience from `BRAND/pillars.md`
- **Key Points** — The 3-5 things the reader must walk away understanding
- **Artifacts Needed** — What visuals, code samples, or diagrams are required

### outline.md

The structural outline maps the arc of the piece:

- **Hook** — The opening that earns attention. Lead with a real problem, a provocative observation, or a demo. Never lead with a definition or history lesson.
- **Main Sections** — Named sections with 1-2 sentence summaries. Each should advance the argument.
- **Takeaway** — Practical, actionable conclusion the reader can act on Monday morning.

### draft.md

The canonical written content. Write in the voice defined in `BRAND/voice.md`. Reference voice.md before every draft session to recalibrate tone. The draft follows the outline but can evolve as writing reveals new angles.

### artifacts/

All supporting visualizations, diagrams, charts, code samples, and screenshots. Name files descriptively. Reference from draft.md using relative paths.

### review/

Review notes, editorial feedback, and revision history. Populated during the review phase.

---

## Step 3: Write the Brief and Outline

Before drafting prose, complete brief.md and outline.md. These documents set the boundaries and structure for the draft.

Read `BRAND/voice.md` and `BRAND/pillars.md` before writing the brief to ensure pillar alignment and audience fit.

---

## Step 4: Draft the Content

With brief.md and outline.md in place, write the draft in draft.md. Follow the outline structure but allow the writing to evolve naturally.

**Voice calibration:** Re-read `BRAND/voice.md` before each drafting session. Match tone sliders for the target pillar. Use signature moves where appropriate. Avoid all taboos.

**Content modes:**

- **curiosity** — 500-1000 words, single artifact, for LinkedIn signal posts and quick takes
- **deep** — 2000+ words, multiple artifacts, for flagship blog posts and technical deep dives

---

## Step 5: Update Status

After completing the draft, update the idea's status in `BACKLOG/ideas.yaml` to `drafting`.

---

## Drafting Checklist

Before starting:
- [ ] Read BRAND/voice.md for tone calibration
- [ ] Read BRAND/pillars.md to confirm audience and pillar fit
- [ ] Set content mode (curiosity or deep)
- [ ] Update idea status to in-progress in ideas.yaml

Before finishing:
- [ ] Check against voice.md taboos
- [ ] Verify brief.md scope was honored (no scope creep)
- [ ] Ensure outline.md structure is reflected in draft.md
- [ ] All artifacts/ files are referenced from the draft
- [ ] Hook earns attention in the first two sentences
- [ ] Takeaway is concrete and actionable
