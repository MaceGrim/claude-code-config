# Studio Ideate — Claude Code Skill

Generate new content ideas for Grimshaw Studio by researching current trends and updating the backlog.

---

## Step 1: Load BRAND Context

Before generating any ideas, read the following files to internalize Mason's voice, audience, and content lanes:

1. `BRAND/voice.md` — Tone, signature moves, taboos
2. `BRAND/pillars.md` — The four content lanes and their audiences
3. `BRAND/voice-samples.md` — Real examples to calibrate against
4. `BRAND/do-dont.md` — Explicit guardrails
5. `BRAND/audience.md` — Who we're writing for

Also read the current backlog to avoid duplicates:

6. `BACKLOG/ideas.yaml` — Existing ideas and their statuses

---

## Step 2: Research Trends via Web Search

Use web search to scan for current AI zeitgeist across categories:

- **Enterprise AI** — Production deployments, vendor announcements, CTO perspectives
- **Tribal / Indigenous AI** — Sovereignty initiatives, language preservation tech, tribal data governance
- **Technical** — New architectures, papers, open-source releases
- **Culture & Fun** — Viral AI projects, creative experiments, debates

Suggested search queries:

- `AI enterprise production deployment this week`
- `Indigenous AI data sovereignty`
- `AI agent production failures lessons`
- `creative AI projects experiments`

Look for ideas with a **contrarian angle** or **experience-grounded take** — not just "X happened" but "X happened, and here's what everyone is missing."

If web search is unavailable, fall back to:

- Personal experience from consulting engagements
- Evergreen patterns in AI adoption
- Gaps in the current backlog across pillars
- Contrarian takes on conventional AI wisdom

---

## Step 3: Generate and Score Ideas

For each idea, develop:

- **Title** — Specific, opinionated, not generic
- **Pillar** — One of: `enterprise`, `tribal`, `deep-dive`, `experiments`
- **Hook** — One sentence that makes someone stop scrolling
- **Notes** — Supporting context, sources, connections

Score each idea on four criteria (1-5):

| Criterion | 5 = Best |
|-----------|----------|
| **brand_fit** | Perfect alignment with voice + pillar + audience |
| **novelty** | Genuinely new perspective or contrarian take |
| **artifact_potential** | Rich artifact opportunity (visualization, interactive, live demo) |
| **effort** | Quick to produce, high impact |

Only promote ideas scoring **3+ on brand_fit** and **3+ on novelty**.

---

## Step 4: Update ideas.yaml

Append qualifying ideas to `BACKLOG/ideas.yaml` using this schema:

```yaml
- title: "The Title Goes Here"
  pillar: enterprise
  status: seed
  hook: "One compelling sentence."
  notes: "Supporting context, sources, series potential."
  added: 2026-01-15
```

Ensure no duplicates exist in the current backlog before adding.

Keep the active backlog between 10-25 ideas. Move overflow to `BACKLOG/parking-lot.md`.

---

## Completion Checklist

- [ ] Read BRAND files first
- [ ] Used web search (or fallback) to source raw material
- [ ] Generated ideas across multiple pillars
- [ ] Scored each idea on all four criteria
- [ ] Added qualifying ideas to ideas.yaml with correct schema
- [ ] Active backlog is between 10-25 ideas
- [ ] No duplicate ideas in the backlog
