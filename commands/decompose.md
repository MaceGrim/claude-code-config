---
allowed-tools: Bash, Read, Write, Glob, Grep, Edit, Agent, TaskCreate, TaskUpdate, TaskList, TaskGet
description: Decompose a folder of reading-note chunks into interconnected wiki concept pages
argument-hint: <slug> (directory name under raw/reading-notes/)
---

# Decompose — Reading Notes → Wiki Concepts

Turn a folder of pre-extracted reading-note section files into
interconnected wiki concept pages. Designed for books, papers, and other
large sources that have already been split into section-level chunks
(typically via `schema/scripts/pdf-textbook.py`).

## Prerequisites

- Section files must exist at `raw/reading-notes/<slug>/ch*/` with
  `type: reading-note` frontmatter.
- The vault schema is at `schema/CLAUDE.md` — read it for entity types,
  frontmatter conventions, and naming rules.

## Input

The argument is a slug — the directory name under `raw/reading-notes/`.

Example: `/decompose geoai-python`

If no argument is given, list available slugs and ask which one.

## Three Phases

### Phase 1: Generate manifest

**Goal:** Scan all section files and produce a concept mapping.

1. Read `schema/CLAUDE.md` for wiki conventions.
2. Read `wiki/index.md` to know what concept pages already exist.
3. Read `raw/reading-notes/<slug>/_extraction-report.md` for the full
   section listing.
4. Read all `*-key-takeaways.md` files — the author's own summary of
   what matters per chapter.
5. Skim a representative sample of section files (read the first ~20
   lines of each to understand what it covers).

From this, produce `raw/reading-notes/<slug>/manifest.json`:

```json
{
  "source": "GeoAI with Python — Qiusheng Wu (2026)",
  "slug": "geoai-python",
  "generated": "2026-04-11",
  "concepts": [
    {
      "slug": "semantic-segmentation",
      "aliases": ["pixel-level classification", "dense prediction"],
      "kind": "technique",
      "description": "Pixel-level classification of satellite/aerial imagery",
      "sections": [
        "ch09/09-03-foundations-of-semantic-segmentation.md",
        "ch09/09-10-key-takeaways.md"
      ],
      "connects_to": ["building-detection", "land-cover-classification"],
      "updates_existing": false
    }
  ],
  "people": [
    {"slug": "qiusheng-wu", "role": "Author", "org": null}
  ],
  "orgs": [],
  "progress": {}
}
```

**Concept identification rules:**
- A concept is worth a page if it represents a **technique, tool, dataset,
  architecture, or workflow** that Mason might ask about in the future.
- Prefer **task-oriented** names: `building-detection` not `chapter-9-section-5`.
- Merge sections that cover the same concept across chapters (e.g.,
  "Publish and Reuse Models" appears in Ch 7, 8, 9 — one concept page).
- Don't create concepts for boilerplate (setup, imports, how to use conda).
- DO create concepts for:
  - AI task types (classification, detection, segmentation, etc.)
  - Specific techniques (U-Net, Mask R-CNN, SAM, ChangeStar, etc.)
  - Tools and libraries (leafmap, torchgeo, geoai, samgeo, etc.)
  - Datasets (EuroSAT, NWPU-VHR-10, FTW, Inria, etc.)
  - Data concepts (STAC, COG, image tiling, annotation formats, etc.)
  - Evaluation methods (COCO metrics, confusion matrices, IoU, etc.)
  - Cross-cutting workflows (training data pipelines, model publishing,
    batch inference, tiled inference, etc.)
- Check existing wiki concepts before creating duplicates. If a concept
  already exists (e.g., `clay`), mark `updates_existing: true` and list
  the sections that add new information.

### Phase 2: Synthesize concept pages

**Goal:** For each concept in the manifest, create or update a wiki page.

Process concepts in batches. For each concept, spawn a subagent
(Agent tool) with this prompt pattern:

```
You are synthesizing a wiki concept page for Mason's Obsidian vault.

CONCEPT: <slug>
ALIASES: <aliases>
KIND: <kind>
DESCRIPTION: <description>

Read these section files from the book:
<list of section file paths>

Read these existing wiki pages for context on how to link:
<list of connects_to concept paths, if they exist>

Then write the concept page to: wiki/concepts/<slug>.md

Follow this structure:

---
type: concept
aliases: [<aliases>]
kind: <kind>
last_updated: <today>
---

# <Title>

<2-3 sentence explanation of what this is and why it matters for
geospatial AI work.>

## Key content

<Preserve the actual explanatory text from the source sections. Include:
- The author's definitions and explanations (quote or closely preserve
  the key passages — do not lossy-summarize)
- Important code snippets (the essential function calls, model
  definitions, key parameters — not every import or print statement)
- Concrete details: model architectures, dataset specs, hyperparameters,
  evaluation results, gotchas the author calls out

The goal is that reading this concept page gives you the real substance
of what the book says, not a watered-down summary. Someone should be
able to use this page as a working reference without needing to go back
to the section file for basic details.

Organize with subheadings if the concept draws from multiple sections
or covers multiple sub-topics.>

## Recipes

<Task-oriented "how to do X" entries. Each recipe has:
- A short heading describing the task
- The key function call(s) with important parameters
- A pointer to the source section file for the full walkthrough
Keep recipes action-oriented — what you'd actually type to get started.>

## Where it shows up

<Link to any existing wiki projects or concepts where this is relevant.
If nothing in the wiki connects yet, omit this section.>

## Sources

<List the source section files with section numbers and page ranges.
Format: - §N.M: raw/reading-notes/<slug>/chNN/<filename> (pp. X-Y)>

IMPORTANT:
- Use [[wiki-links]] for all cross-references to other concepts, people, orgs.
- Use filename-only wiki links, not path-style.
- PRESERVE key text and code from the source. The concept page should
  be a self-contained reference, not a pointer to "go read the section
  file." Include the substance. The section files are for full context
  and complete code walkthroughs.
- If updating an existing concept page, PRESERVE all existing content
  and ADD new sections/information from the book. Do not overwrite
  project-specific context that came from meetings.
```

**Track progress** in the manifest's `progress` field:
```json
"progress": {
  "semantic-segmentation": "done",
  "building-detection": "done",
  "object-detection": "in_progress"
}
```

Update the manifest after each concept so the session can resume if
interrupted. Use TaskCreate/TaskUpdate to track progress visibly.

**Parallelism:** Launch up to 3 concept subagents in parallel when their
`connects_to` dependencies are already written. Start with concepts that
have no dependencies on other new concepts (they only link to existing
wiki pages). Then work outward.

### Phase 3: Wire up the wiki

After all concepts are synthesized:

1. **Cross-link pass.** Read all newly created concept pages. For every
   `connects_to` relationship, verify the reverse link exists. If
   concept A links to concept B but B doesn't link back to A, add the
   link to B's `## Where it shows up` or `## See also` section.

2. **Update `wiki/index.md`.** Add all new concept pages under the
   `## Concepts` section with one-line descriptions. Group logically
   (techniques, tools, datasets, etc.) if the list is getting long.

3. **Create person/org pages.** For each entry in the manifest's
   `people` and `orgs` arrays, create wiki pages following the schema
   conventions. These will typically be thin stubs (author bio, org
   description) — that's fine and expected.

4. **Append to `wiki/log.md`.** One entry:
   ```
   ## [YYYY-MM-DD] ingest | book decomposition | <source title> | project: none
   - Source: raw/books/<filename> → raw/reading-notes/<slug>/
   - Created N concept pages, updated M existing concepts
   - Created P person pages, Q org pages
   - Full manifest: raw/reading-notes/<slug>/manifest.json
   ```

5. **Summary.** Print a final summary listing:
   - New concept pages created (with slugs)
   - Existing concept pages updated
   - New person/org pages
   - Total section files processed

## Resumption

If the session is interrupted mid-decompose:

1. Check if `manifest.json` exists — if so, skip Phase 1.
2. Check the `progress` field — resume from the first concept not
   marked "done".
3. Continue from where we left off.

To resume: just run `/decompose <slug>` again.

## Notes

- This skill does NOT modify raw files. Section files in
  `raw/reading-notes/` are read-only inputs.
- Concept pages are written to `wiki/concepts/` following the vault
  schema's naming conventions (kebab-case, filename-only wiki links).
- The manifest is the source of truth for what was planned. If Mason
  wants to adjust the decomposition later, edit the manifest and re-run.
