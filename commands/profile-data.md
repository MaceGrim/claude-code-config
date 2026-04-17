# Profile Data — Zero-Hallucination Dataset Overview

Rapidly profile a dataset and produce a PowerPoint summary backed by verifiable scripts. Every claim in the deck MUST come from a script output — never guess, infer, or editorialize.

## Arguments

**$ARGUMENTS** - Path to a data file (CSV, Excel, Parquet, JSON). Optionally a second argument for an output directory name. If empty, ask the user for a path.

## Instructions

You are profiling a dataset for someone who has never seen it before. Your job is to surface what's actually in the data — not what you think should be there.

### Rules

1. **NEVER hallucinate.** Every number in the PowerPoint must come from a script you ran. If a computation fails, say so — don't estimate.
2. **NEVER editorialize.** Don't say "this looks like it could be useful for X" or "this column appears to represent Y". Report what the data shows. The user draws conclusions.
3. **Show real values.** For categorical columns, show actual value counts. For numeric columns, show actual quantiles. For text, show actual samples.
4. **Surface data quality issues explicitly.** Nulls, mixed types, encoding problems — flag them with counts.

### Step 1: Create the profile directory

Create a directory called `data_profile_{filename}/` (or the user's chosen name) with this structure:

```
data_profile_{name}/
├── 01_overview.py          # File basics, shape, dtypes
├── 02_column_detail.py     # Per-column deep dive
├── 03_red_flags.py         # Quality issues, structural notes
├── build_deck.py           # Reads outputs, builds the PowerPoint
├── outputs/                # Script outputs land here (JSON)
└── {name}_profile.pptx     # Final deck
```

### Step 2: Write and run 01_overview.py

This script loads the file and writes `outputs/01_overview.json` with:

- `file_path`, `file_size_mb`, `row_count`, `column_count`
- `columns`: list of objects, each with:
  - `name`, `dtype`, `non_null_count`, `null_pct`, `unique_count`
  - `sample_values`: 3 real values from the column (as strings)
  - `classification`: one of `[numeric, categorical, boolean, datetime, free_text, id, constant, empty]` — determined by heuristics (unique ratio, dtype, value inspection), NOT by column name guessing

Run it. Fix any errors. Confirm the JSON was written.

### Step 3: Write and run 02_column_detail.py

Reads `outputs/01_overview.json` for classifications, then produces `outputs/02_column_detail.json` with per-column detail based on classification:

**Numeric**: min, p25, median, p75, max, mean, std, zero_count, negative_count, top_5_values (to catch coded categoricals)

**Categorical/Boolean**: full value_counts if ≤20 unique, else top 15 + overflow count. Flag encoding errors (â€, Ã, etc.)

**Datetime**: min_date, max_date, range_days, distribution by year/month

**Free text** (high unique ratio, string dtype): length stats (min, median, max chars), 5 random samples, flag multi-value delimiters

**ID-like** (unique ratio ≈ 1.0): sample format, whether truly unique, duplicate count

**Constant**: the single value

**Empty**: just note it

Run it. Fix any errors.

### Step 4: Write and run 03_red_flags.py

Produces `outputs/03_red_flags.json` checking:

1. **Mostly-null columns** (>80% null) — list with percentages
2. **Encoding issues** — scan for mojibake patterns, count affected rows per column
3. **Multi-value fields** — columns containing comma/semicolon-separated lists, with counts of multi-value vs single-value rows
4. **Duplicate rows** — exact duplicate count
5. **Type mismatches** — numeric data stored as strings, dates as strings
6. **Repeating column groups** — `col`, `col.1`, `col.2` patterns suggesting wide-to-long candidates
7. **Potential join keys** — columns with consistent format and high uniqueness

Run it. Fix any errors.

### Step 5: Write and run build_deck.js

This script reads ALL three JSON outputs and builds a PowerPoint (`{name}_profile.pptx`) using PptxGenJS (Node.js). Use the `/document-skills:pptx` skill reference for PptxGenJS API patterns and pitfalls. Install with `npm install pptxgenjs` in the profile directory. The deck should have:

**Slide 1 — Title**: Dataset name, row/column count, date profiled

**Slide 2 — Overview**: File basics, row/column counts, date range if applicable. A plain-English summary paragraph where every claim is backed by a number from 01_overview.json.

**Slide 3 — Column Summary Table**: The full column list with dtype, null%, unique count, classification. Use a real table object. If too many columns for one slide, split across multiple slides.

**Slides 4+ — Column Details**: One slide per "interesting" column (skip IDs, constants, empties). Show the stats and value distributions from 02_column_detail.json. Use bar charts (via PptxGenJS chart API) for categoricals with ≤15 values. Use bullet lists for numeric stats. NEVER truncate column names — show the full name.

**Second-to-last slide — Red Flags**: Everything from 03_red_flags.json. Use red/orange text for warnings.

**Last slide — Verification**: Note that all numbers come from the scripts in the profile directory, with the script filenames listed.

Style: clean, professional, minimal. White background, dark text, accent color for charts. No clip art. No decorative elements.

Run it. Fix any errors. Confirm the PPTX was written.

### Step 6: Open the PowerPoint

Open the PPTX for the user to review.

### Important notes

- The analysis scripts (01-03) are Python. The deck builder (build_deck.js) is Node.js using PptxGenJS.
- Install `pptxgenjs` with `npm install pptxgenjs` in the profile directory.
- All Python scripts should use the SAME file loading logic (same skiprows, same encoding, etc.). Define shared loading config at the top of each script or in a small shared module (shared.py).
- Each Python script must be independently runnable (`python 01_overview.py`) so the user can verify any claim.
- The JS deck builder reads ONLY from the JSON outputs — it never touches the source data directly.
- If the file has junk header rows (common with exports), detect and skip them — but document what was skipped.
- NEVER truncate or clip column names anywhere — in tables, slide titles, or labels. Show the full name.
- Print progress as you go so the user can follow along.
