# Composite recipes and scene-type recommendations

This file documents the five Sentinel-2 composites the skill produces and gives
heuristics for which subset to default to based on the user's description of
the AOI. Read this when picking a default subset.

## Band map

Sentinel-2 L2A bands the skill uses (10 m or resampled to 10 m):

| Band | Wavelength    | Use                  |
|------|---------------|----------------------|
| B02  | ~490 nm Blue  | true color, sediment |
| B03  | ~560 nm Green | true color           |
| B04  | ~665 nm Red   | true color, NDVI     |
| B08  | ~842 nm NIR   | NDVI, vegetation     |
| B11  | ~1610 nm SWIR1| moisture, crops      |
| B12  | ~2190 nm SWIR2| built/bare contrast  |

## The five composites

### `true_color`  (B04, B03, B02)
Natural color, what the eye would see from orbit. Always safe. Good baseline
for any AOI; mandatory if the audience is non-technical.

### `false_color_nir`  (B08, B04, B03)
Vegetation blazes red/magenta because chlorophyll reflects strongly in NIR.
Water reads dark blue/black, urban grey-cyan, bare soil pale. Best single
composite for ecology, mangroves, forests, croplands.

### `agriculture`  (B11, B08, B02)
SWIR1 in red picks up plant moisture and crop stress; NIR in green is healthy
canopy; blue isolates water and shadow. Crops cluster by colour by growth stage,
which is exactly what makes the Brazil hero striking.

### `urban`  (B12, B11, B04)
Two SWIR bands plus red — built and bare surfaces glow, vegetation goes dark.
Designed for infrastructure, roads, mining, anything anthropogenic.

### `ndvi`  (single band: `(B08 - B04) / (B08 + B04)`, RdYlGn colormap)
A scalar vegetation index, not a true composite — rendered with a red-to-green
diverging colormap. Most legible to non-specialists ("greener = more plant").
Saturates over very dense canopy.

## Defaults by scene type

When the user doesn't explicitly pick composites, infer the scene type from
their description and default to a subset rather than rendering all five. The
"all five" output is overwhelming for a slide and biases toward technical
audiences.

| Scene the user describes        | Default subset                                  |
|---------------------------------|-------------------------------------------------|
| coastal, mangrove, wetland, estuary, lagoon, delta | `true_color`, `false_color_nir`, `ndvi` |
| forest, jungle, rainforest, savanna, woodland      | `true_color`, `false_color_nir`, `ndvi` |
| agriculture, cropland, farm, soy, corn, ranch      | `true_color`, `false_color_nir`, `agriculture`, `ndvi` |
| urban, city, infrastructure, mine, port, industrial| `true_color`, `urban`, `false_color_nir` |
| desert, bare ground, mountain, ice                 | `true_color`, `urban` (for contrast)    |
| unknown / mixed                                    | all five                                |

Always state the chosen subset before running so the user can override.

## Notes on tuning

- **Percentile normalization (2/98)** is applied per-band before display.
  This is the single biggest knob for "pretty"; widening to 1/99 makes images
  flatter, narrowing to 5/95 makes them more saturated.
- **Gamma 0.85** brightens midtones; raise toward 1.0 for a more "factual"
  feel, drop to 0.7 for "Instagram" punch.
- The output PNGs honor the AOI's native aspect ratio (no forced square).
- Median-of-top-5-scenes composite is what makes cloud streaks vanish even
  without a cloud mask. Don't change this without good reason.
