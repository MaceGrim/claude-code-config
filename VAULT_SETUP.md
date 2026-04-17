# Obsidian Vault Bootstrap

Several commands and rules in this config (`/decompose`, `/studio-*`, the wiki lookup in `CLAUDE.md`, lens usage tracking) assume an Obsidian vault exists at a known path. If you're setting up on a fresh machine and the vault isn't there yet, an AI agent can follow this guide to scaffold the minimum structure.

## Expected paths

`CLAUDE.md` hardcodes these:

| Path | Purpose |
|------|---------|
| `/mnt/o/obsidian_vault/` | Vault root (WSL path; Windows equivalent: `O:\obsidian_vault\`) |
| `wiki/index.md` | Knowledge base nav hub — lists concept pages and Communication Lenses |
| `wiki/concepts/` | Concept pages (populated by `/decompose`) |
| `wiki/concepts/_usage-tracker.md` | Running log of how often each Communication Lens is applied |
| `raw/reading-notes/` | Source markdown chunks fed into `/decompose` |

If the vault lives elsewhere, update path references in `CLAUDE.md` to match. Don't relocate the vault just to satisfy this config.

## Minimum scaffold

```bash
VAULT=/mnt/o/obsidian_vault
mkdir -p "$VAULT/wiki/concepts" "$VAULT/raw/reading-notes"
```

### `wiki/index.md` starter

```markdown
# Wiki Index

## Concepts
<!-- Populated by /decompose. Each concept page lives in concepts/ and links here. -->

## Communication Lenses
<!-- Lenses on explanation design, data viz, and storytelling structure. -->
<!-- Each lens links to a raw/reading-notes/ analysis for depth. -->
```

### `wiki/concepts/_usage-tracker.md` starter

```markdown
# Lens Usage Tracker

Each time a communication lens is applied, increment its count and append a log entry below.

| Lens | Count | Last Used |
|------|-------|-----------|

## Log
```

## Populating the vault

Once the scaffold exists:

1. Drop source notes into `raw/reading-notes/<source-name>/` as markdown chunks.
2. Run `/decompose <path-to-chunks>` to generate interconnected concept pages under `wiki/concepts/`.
3. As you invoke lenses while writing articles, the rule in `CLAUDE.md` increments `_usage-tracker.md` automatically.

The vault is the long-lived knowledge base — this repo only contains the tooling that reads from and writes to it.
