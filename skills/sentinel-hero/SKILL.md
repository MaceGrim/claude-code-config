---
name: sentinel-hero
description: Generate beautiful "hero" satellite imagery composites (true color, false color NIR, NDVI, agriculture, urban) from Sentinel-2 L2A via Microsoft Planetary Computer. Use this skill whenever the user wants a polished satellite render of a location for a slide, deck, report, or presentation; whenever they provide a GeoJSON polygon or bbox of an area and ask for imagery; or when they say things like "hero image", "satellite composite", "Sentinel render", "pretty satellite view", or "aerial view of [place]" for visual use. Handles single AOIs and multi-polygon FeatureCollections. Auto-picks the best composite subset for the described scene type (coastal/agricultural/urban) so the output is slide-ready, not data-dump.
---

# Sentinel hero

Pulls Sentinel-2 L2A scenes via Microsoft Planetary Computer, median-composites
them to dodge clouds, and renders one or more named composites at high DPI with
aspect ratios that match the AOI's natural shape. Outputs are intended for
slides and reports, not analysis — pretty first, defensible second.

## What you need from the user

The skill needs an AOI. Anything else has sensible defaults — explain the
defaults you're applying and let the user override.

**AOI** — accept any of:
- A GeoJSON file path (`.geojson`) with one or more Polygon features
- An inline GeoJSON snippet pasted in chat (write it to a temp file)
- A bbox tuple `(lon_min, lat_min, lon_max, lat_max)`
- A point + buffer-in-km (Brazil-style center+radius)
- A named place (in this case ASK for a polygon or bbox — don't guess
  coordinates from a name; that's a frequent source of "wrong location" bugs)

**Date window** — default is the last 3 months ending today. Override when the
user says "the most recent dry season", "last year", "Q3 2025", etc. Always
state the window you're using before pulling.

**Composites** — by default, pick a subset based on the scene type the user
described, not all five. See `references/composites.md` for the heuristic.
If the user provides no description, default to all five and tell them why.

**Output location** — default to CWD. If the AOI came from a GeoJSON file with
a useful sibling location, optionally suggest that.

## How to run

The work happens in `scripts/render_hero.py`. Run it with the user's
parameters; do not re-derive the band recipes or STAC search from scratch.

```bash
# Single polygon from a GeoJSON file
python ~/.claude/skills/sentinel-hero/scripts/render_hero.py \
    --aoi-geojson aoi.geojson \
    --composites true_color,false_color_nir,ndvi \
    --output-dir ./samana_hero

# Inline bbox
python ~/.claude/skills/sentinel-hero/scripts/render_hero.py \
    --aoi-bbox -69.6778,19.0851,-69.6008,19.1993 \
    --name samana_bay \
    --output-dir ./samana_hero

# Center + buffer (Brazil-style)
python ~/.claude/skills/sentinel-hero/scripts/render_hero.py \
    --aoi-point -50.094,-17.99 --buffer-km 3 \
    --name soy_facility \
    --start-date 2024-03-01 --end-date 2024-04-30 \
    --output-dir ./soy_hero
```

When the user pastes inline GeoJSON, write it to a temp file (e.g.
`/tmp/aoi.geojson`) and pass `--aoi-geojson`. That's cleaner than trying to
flatten coordinates into `--aoi-bbox` and handles multi-polygon collections
correctly.

## Defaults the skill applies

The script itself handles these — you don't need to compute them, but you
should *tell the user* what it picked so they can override.

| Parameter         | Default                                              |
|-------------------|------------------------------------------------------|
| Date window       | Rolling 90 days ending today                         |
| Cloud-cover cap   | 15% → widens to 25% → 40% if too few scenes          |
| Scenes used       | Top 5 by cloud cover, median-composited              |
| UTM EPSG          | Auto-picked from bbox centroid longitude (zone math) |
| Output figure DPI | 300                                                  |
| Aspect ratio      | Matches AOI bbox shape (portrait stays portrait)     |
| Multi-AOI layout  | One subfolder per polygon, named by `properties.name` if present else `feature_N` |

## Picking composites (this is the judgement call)

This is the one place the skill needs you to think rather than just call the
script. The right subset depends on what the user wants to convey. Open
`references/composites.md` and apply the table — but use your judgement, the
heuristics are not a hard rule. Examples:

- "make a hero of Samana Bay for our mangrove deck" → coastal/mangrove →
  `true_color,false_color_nir,ndvi`
- "I need a render of this soy farm" → agricultural → all five, or four
  excluding `urban`
- "satellite image of the port at Santos" → urban/infrastructure →
  `true_color,urban,false_color_nir`
- User pastes a polygon with no context → default to all five and ask which
  they want for the final slide

Always **announce the subset before running**. The user will redirect if you
pick wrong, and you'll save them a 1-3 minute STAC pull.

## After the run

The script emits a `CREDIT.txt` alongside the PNGs with the required
attribution string and the scene list (IDs, dates, cloud cover). This is not
optional decoration — Copernicus Sentinel data is free for commercial use
*conditional* on the attribution `Contains modified Copernicus Sentinel data
<year>` being shown to recipients. When you summarize the run to the user, say
that the attribution lives in `CREDIT.txt` and that they need a small credit
line on the slide (or one source slide at the end of the deck).

Don't try to bake the credit into the PNGs themselves — it would clash with the
slide design.

## Dependencies

The script imports `planetary_computer`, `pystac_client`, `stackstac`,
`numpy`, `matplotlib`, `pyproj`. If imports fail, suggest:

```bash
pip install planetary-computer pystac-client stackstac matplotlib pyproj
```

No API key is required for Planetary Computer's public Sentinel-2 collection —
`planetary_computer.sign_inplace` handles anonymous SAS signing.

## What this skill does NOT do

- Cloud masking via SCL band — the median composite handles light cloud streaks
  well, but very cloudy windows (rainy season, hurricane months) may still show
  artifacts. If outputs look streaky, suggest a different date window.
- Sentinel-1 SAR, Landsat, or commercial imagery. Add separate skills if those
  become routine asks.
- Large AOIs that span >5° of longitude (UTM auto-pick breaks down). If the
  user wants continental-scale, suggest a different tool.
- Animation / time-lapse. The `bay_sentinel/` quarterly mosaic workflow in
  `ode-geoai/dominican_republic/` is the right pattern for that.

## Pointers

- Composite recipes & scene-type heuristics: `references/composites.md`
- Reference implementations (read these if curious about provenance):
  - `~/ode/Github/brazil-soy-infrastructure-identification/scripts_for_writeup/generate_hero_image.py`
  - `~/ode/Github/ode-geoai/dominican_republic/samana_hero/generate_samana_hero.py`
