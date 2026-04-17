# Studio Publish — Claude Code Skill

Publish reviewed content to the Grimshaw Studio Astro site. This skill handles the final steps from approved draft to live content.

---

## Prerequisites

Before publishing, verify:

1. **Review checklist passes** — Read the project's `review/checklist.md` and confirm all checks are marked `[x]`. If any checklist item is failing, abort and return to review. Do not publish drafts with unresolved issues.
2. **Edits applied** — All critical edits from `review/edits.md` have been addressed.

---

## Step 1: Build the SITE Locally

Run the Astro dev server to verify the site builds before making changes:

```bash
cd SITE
npm install
npm run dev
```

Confirm the site is accessible at `localhost` (typically `http://localhost:4321`). If the build fails, diagnose the error and fix it before proceeding. Common error scenarios:

- **Missing dependencies** — Run `npm install` again or check for version conflicts
- **TypeScript errors** — Check type definitions in content config
- **Content schema mismatch** — Verify frontmatter matches the expected schema
- **Build timeout** — Check for infinite loops or oversized assets

If the build continues to fail after troubleshooting, stop and report the error to Mason. Do not force a broken build.

---

## Step 2: Create the Blog Post File

Copy the approved `draft.md` content into a new file under `SITE/src/content/blog/`:

1. Create the blog post file with a slugified filename: `SITE/src/content/blog/<slug>.md`
2. Add Astro-compatible frontmatter at the top of the file
3. Copy the draft body content below the frontmatter
4. Copy any artifacts (images, diagrams) to `SITE/public/blog/<slug>/`
5. Update image references in the post to use the correct public paths

### Frontmatter Template

```yaml
---
title: "The Post Title"
description: "A one-sentence summary for SEO and social cards"
pubDate: 2026-01-15
updatedDate: 2026-01-15
pillar: "enterprise"
tags: ["ai", "production", "enterprise"]
heroImage: "/blog/<slug>/hero.png"
draft: false
---
```

---

## Step 3: Verify the Published Post

After adding the blog post file:

1. Restart the dev server if needed (`npm run dev`)
2. Navigate to `http://localhost:4321/blog/<slug>` in the browser
3. Verify the post renders correctly:
   - Title and metadata display properly
   - All images and artifacts load
   - Code blocks are syntax-highlighted
   - Links work
   - Layout is consistent with other posts

If the post does not render or any element is broken, fix the error before marking as published.

---

## Step 4: Build for Production

Run a production build to catch any errors the dev server might miss:

```bash
cd SITE
npm run build
```

If the production build fails, diagnose and fix the error. Do not deploy a broken build.

---

## Step 5: Update Status

After the post is verified and the production build succeeds:

1. Update the idea's status in `BACKLOG/ideas.yaml` to `published`
2. Add the `pubDate` and URL to the idea entry
3. Mark the project as published in the project folder

---

## Error Handling

At every step, if an error or failure occurs:

- **Log the error** clearly with the step number and full error message
- **Do not proceed** to the next step until the error is resolved
- **Report blocking errors** to Mason with context and suggested fix
- **Never force-publish** content with known issues

---

## Publishing Checklist

- [ ] Review checklist.md confirms all checks pass
- [ ] Critical edits from edits.md are applied
- [ ] Site builds locally with `npm run dev`
- [ ] Blog post file created with correct frontmatter
- [ ] Artifacts copied to public directory
- [ ] Post renders correctly at localhost
- [ ] Production build succeeds with `npm run build`
- [ ] Status updated to published in ideas.yaml
