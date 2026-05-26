"""
Sentinel-2 hero image generator.

Pulls Sentinel-2 L2A scenes via Microsoft Planetary Computer for a user-supplied
AOI, builds a median composite to suppress clouds, and renders one or more
named composites (true_color, false_color_nir, agriculture, urban, ndvi) as
high-DPI PNGs sized to the AOI's natural aspect ratio.

Usage examples:
  # GeoJSON file (Polygon / FeatureCollection of Polygons)
  python render_hero.py --aoi-geojson aoi.geojson --output-dir ./out

  # Inline bbox
  python render_hero.py --aoi-bbox -69.68,19.09,-69.60,19.20 --output-dir ./out

  # Center + buffer
  python render_hero.py --aoi-point -50.094,-17.99 --buffer-km 3 --output-dir ./out

  # Composite selection (subset)
  python render_hero.py --aoi-geojson aoi.geojson --composites true_color,false_color_nir,ndvi
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path

# GDAL env tuning for remote reads — set before rasterio/stackstac touch GDAL
os.environ.setdefault('GDAL_DISABLE_READDIR_ON_OPEN', 'EMPTY_DIR')
os.environ.setdefault('GDAL_HTTP_MAX_RETRY', '3')
os.environ.setdefault('GDAL_HTTP_RETRY_DELAY', '1')
os.environ.setdefault('GDAL_HTTP_TIMEOUT', '60')
os.environ.setdefault('VSI_CACHE', 'TRUE')
os.environ.setdefault('VSI_CACHE_SIZE', '500000000')

import numpy as np
import matplotlib.pyplot as plt
import planetary_computer
import pystac_client
import stackstac


# ── Composite recipes ──────────────────────────────────────────
# Band map: B02=Blue, B03=Green, B04=Red, B08=NIR, B11=SWIR1, B12=SWIR2
COMPOSITE_BANDS = {
    "true_color":      ("B04", "B03", "B02"),    # natural color
    "false_color_nir": ("B08", "B04", "B03"),    # vegetation pops red
    "agriculture":     ("B11", "B08", "B02"),    # crops bright, soil dark
    "urban":           ("B12", "B11", "B04"),    # built/bare bright, veg dark
    # ndvi handled separately (single-band with colormap)
}
ALL_COMPOSITES = list(COMPOSITE_BANDS.keys()) + ["ndvi"]

REQUIRED_BANDS_ALL = ["B02", "B03", "B04", "B08", "B11", "B12"]


# ── AOI normalization ──────────────────────────────────────────
@dataclass
class AOI:
    """A single AOI to render. Bbox is (lon_min, lat_min, lon_max, lat_max)."""
    name: str
    bbox: tuple[float, float, float, float]


def aois_from_geojson(path: Path) -> list[AOI]:
    """Read a GeoJSON file and return one AOI per Polygon feature.

    MultiPolygons are flattened to their constituent polygons. Each AOI gets a
    name from properties.name / properties.id / properties.title, else feature_N.
    """
    data = json.loads(path.read_text())
    features = data.get("features") if data.get("type") == "FeatureCollection" else [data]

    aois: list[AOI] = []
    counter = 0
    for feat in features:
        geom = feat.get("geometry") if "geometry" in feat else feat
        props = feat.get("properties", {}) or {}
        name = props.get("name") or props.get("id") or props.get("title")

        if geom["type"] == "Polygon":
            polys = [geom["coordinates"]]
        elif geom["type"] == "MultiPolygon":
            polys = geom["coordinates"]
        else:
            print(f"  ⚠ skipping non-polygon geometry: {geom['type']}", file=sys.stderr)
            continue

        for poly_coords in polys:
            ring = poly_coords[0]  # outer ring
            lons = [pt[0] for pt in ring]
            lats = [pt[1] for pt in ring]
            bbox = (min(lons), min(lats), max(lons), max(lats))
            aname = name if (name and len(polys) == 1) else f"feature_{counter}"
            aois.append(AOI(name=aname, bbox=bbox))
            counter += 1
    return aois


def aoi_from_bbox(bbox: tuple[float, float, float, float], name: str = "aoi") -> AOI:
    return AOI(name=name, bbox=bbox)


def aoi_from_point(lon: float, lat: float, buffer_km: float, name: str = "aoi") -> AOI:
    deg_per_km_lat = 1 / 111.32
    deg_per_km_lon = 1 / (111.32 * math.cos(math.radians(lat)))
    bbox = (
        lon - buffer_km * deg_per_km_lon,
        lat - buffer_km * deg_per_km_lat,
        lon + buffer_km * deg_per_km_lon,
        lat + buffer_km * deg_per_km_lat,
    )
    return AOI(name=name, bbox=bbox)


# ── UTM auto-derivation ────────────────────────────────────────
def utm_epsg_from_bbox(bbox: tuple[float, float, float, float]) -> int:
    """Pick a UTM zone EPSG from the bbox centroid.

    Local UTM keeps resolution uniform across the AOI. For Sentinel-2 chunks
    spanning more than ~5° of longitude this gets fuzzy, but those are not
    "hero" use cases anyway.
    """
    lon_min, lat_min, lon_max, lat_max = bbox
    lon_c = (lon_min + lon_max) / 2
    lat_c = (lat_min + lat_max) / 2
    zone = int((lon_c + 180) // 6) + 1
    return (32600 if lat_c >= 0 else 32700) + zone


# ── Date defaults ──────────────────────────────────────────────
def default_date_range(today: date | None = None) -> tuple[str, str]:
    """Rolling 3-month window ending today. Override at the CLI when needed."""
    today = today or date.today()
    start = today - timedelta(days=90)
    return start.isoformat(), today.isoformat()


# ── STAC pull with progressive cloud-cover widening ────────────
def find_scenes(
    bbox: tuple[float, float, float, float],
    start: str,
    end: str,
    cloud_max: int,
    min_scenes: int = 3,
) -> list:
    """Search Planetary Computer for clean S2 L2A scenes covering the bbox.

    Widening ladder: if fewer than min_scenes match, raise the cloud-cover cap
    in two steps (15→25→40). Date widening is not performed automatically —
    the caller controls the search window.
    """
    catalog = pystac_client.Client.open(
        "https://planetarycomputer.microsoft.com/api/stac/v1",
        modifier=planetary_computer.sign_inplace,
    )

    for cmax in sorted({cloud_max, 25, 40}):
        if cmax < cloud_max:
            continue
        search = catalog.search(
            collections=["sentinel-2-l2a"],
            bbox=list(bbox),
            datetime=f"{start}/{end}",
            query={"eo:cloud_cover": {"lt": cmax}},
        )
        items = list(search.items())
        print(f"  cloud<{cmax}%: {len(items)} scenes")
        if len(items) >= min_scenes:
            items.sort(key=lambda x: x.properties["eo:cloud_cover"])
            return items[:5]

    # Last resort: return whatever we found at the widest cap
    if items:
        items.sort(key=lambda x: x.properties["eo:cloud_cover"])
        return items[:5]
    return []


# ── Render pipeline ────────────────────────────────────────────
def normalize(arr: np.ndarray, plow: float = 2, phigh: float = 98) -> np.ndarray:
    lo = np.nanpercentile(arr, plow)
    hi = np.nanpercentile(arr, phigh)
    return np.clip((arr - lo) / (hi - lo + 1e-10), 0, 1)


def render_aoi(
    aoi: AOI,
    start: str,
    end: str,
    composites: list[str],
    cloud_max: int,
    output_root: Path,
    multi_aoi: bool,
) -> None:
    print(f"\n▶ AOI: {aoi.name}   bbox={aoi.bbox}")

    items = find_scenes(aoi.bbox, start, end, cloud_max)
    if not items:
        print(f"  ✗ no scenes found for {aoi.name} in {start}/{end} — skipping")
        return

    print(f"  using {len(items)} scenes "
          f"(cc={[round(i.properties['eo:cloud_cover'], 1) for i in items]}, "
          f"dates={[i.datetime.date().isoformat() for i in items]})")

    epsg = utm_epsg_from_bbox(aoi.bbox)
    print(f"  UTM EPSG: {epsg}")

    needs_ndvi = "ndvi" in composites
    needed = {b for c in composites if c != "ndvi" for b in COMPOSITE_BANDS[c]}
    if needs_ndvi:
        needed.update({"B04", "B08"})
    bands = [b for b in REQUIRED_BANDS_ALL if b in needed]

    stack = stackstac.stack(
        items,
        assets=bands,
        bounds_latlon=list(aoi.bbox),
        epsg=epsg,
        resolution=10,
        dtype="float64",
        fill_value=np.nan,
    )
    print(f"  stack shape: {stack.shape}; compositing median...")
    composite = stack.median(dim="time").compute()

    band_arrays = {b: composite.sel(band=b).values for b in bands}
    H, W = next(iter(band_arrays.values())).shape

    out_dir = output_root / aoi.name if multi_aoi else output_root
    out_dir.mkdir(parents=True, exist_ok=True)

    # Aspect-aware figure: portrait stays portrait, wide stays wide
    fig_w_in = 16
    fig_h_in = fig_w_in * (H / W)

    saved: list[str] = []
    for name in composites:
        if name == "ndvi":
            ndvi = (band_arrays["B08"] - band_arrays["B04"]) / (
                band_arrays["B08"] + band_arrays["B04"] + 1e-10
            )
            img = np.nan_to_num(normalize(ndvi), nan=0.0)
            fig, ax = plt.subplots(figsize=(fig_w_in, fig_h_in), dpi=300)
            ax.imshow(img, cmap=plt.cm.RdYlGn, vmin=0, vmax=1)
        else:
            r, g, b = COMPOSITE_BANDS[name]
            rgb = np.dstack([normalize(band_arrays[r]),
                             normalize(band_arrays[g]),
                             normalize(band_arrays[b])])
            rgb = np.nan_to_num(rgb, nan=0.0)
            rgb = np.power(rgb, 0.85)  # gamma boost
            fig, ax = plt.subplots(figsize=(fig_w_in, fig_h_in), dpi=300)
            ax.imshow(rgb)

        ax.axis("off")
        plt.subplots_adjust(left=0, right=1, top=1, bottom=0)
        outpath = out_dir / f"hero_{name}.png"
        fig.savefig(outpath, bbox_inches="tight", pad_inches=0, dpi=300)
        plt.close(fig)
        saved.append(outpath.name)
        print(f"  ✓ {outpath}")

    # ── Sidecar: Copernicus attribution + provenance ──────────
    years = sorted({i.datetime.year for i in items})
    year_str = "/".join(str(y) for y in years) if len(years) > 1 else str(years[0])
    credit = (
        f"Contains modified Copernicus Sentinel data {year_str}.\n"
        f"\nSource: Sentinel-2 L2A via Microsoft Planetary Computer.\n"
        f"AOI: {aoi.name}\n"
        f"BBox (WGS84): {aoi.bbox}\n"
        f"Date window: {start} / {end}\n"
        f"Scenes used ({len(items)}):\n"
    )
    for it in items:
        credit += (
            f"  - {it.id}  "
            f"date={it.datetime.date().isoformat()}  "
            f"cloud_cover={it.properties['eo:cloud_cover']:.2f}%\n"
        )
    credit += f"\nComposites rendered: {', '.join(saved)}\n"
    (out_dir / "CREDIT.txt").write_text(credit)
    print(f"  ✓ {out_dir / 'CREDIT.txt'}")


# ── Main / CLI ─────────────────────────────────────────────────
def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--aoi-geojson", type=Path, help="Path to a .geojson file")
    g.add_argument("--aoi-bbox", type=str,
                   help="lon_min,lat_min,lon_max,lat_max")
    g.add_argument("--aoi-point", type=str,
                   help="lon,lat (requires --buffer-km)")
    p.add_argument("--buffer-km", type=float, default=3,
                   help="Buffer in km when using --aoi-point (default 3)")
    p.add_argument("--name", type=str, default="aoi",
                   help="AOI name (used in output dirs when not from GeoJSON)")
    p.add_argument("--start-date", type=str, help="YYYY-MM-DD (inclusive)")
    p.add_argument("--end-date", type=str, help="YYYY-MM-DD (inclusive)")
    p.add_argument("--composites", type=str,
                   default=",".join(ALL_COMPOSITES),
                   help=f"Comma-separated subset of {ALL_COMPOSITES}")
    p.add_argument("--cloud-max", type=int, default=15,
                   help="Initial cloud-cover cap %% (default 15; widens 25, 40)")
    p.add_argument("--output-dir", type=Path, default=Path.cwd(),
                   help="Output root (default: CWD)")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    if args.aoi_geojson:
        aois = aois_from_geojson(args.aoi_geojson)
        multi_aoi = len(aois) > 1
    elif args.aoi_bbox:
        bbox = tuple(float(x) for x in args.aoi_bbox.split(","))
        if len(bbox) != 4:
            raise ValueError("--aoi-bbox needs 4 comma-separated floats")
        aois = [aoi_from_bbox(bbox, args.name)]  # type: ignore[arg-type]
        multi_aoi = False
    else:
        lon, lat = (float(x) for x in args.aoi_point.split(","))
        aois = [aoi_from_point(lon, lat, args.buffer_km, args.name)]
        multi_aoi = False

    if args.start_date and args.end_date:
        start, end = args.start_date, args.end_date
    else:
        start, end = default_date_range()
    print(f"Date window: {start} / {end}")

    composites = [c.strip() for c in args.composites.split(",") if c.strip()]
    invalid = set(composites) - set(ALL_COMPOSITES)
    if invalid:
        raise ValueError(f"Unknown composites: {invalid}. Available: {ALL_COMPOSITES}")

    args.output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Output root: {args.output_dir.resolve()}")
    print(f"AOIs: {len(aois)} ({'multi' if multi_aoi else 'single'})")
    print(f"Composites: {composites}")

    for aoi in aois:
        try:
            render_aoi(aoi, start, end, composites, args.cloud_max,
                       args.output_dir, multi_aoi)
        except Exception as e:
            print(f"  ✗ failed for {aoi.name}: {e}", file=sys.stderr)

    print("\nDone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
