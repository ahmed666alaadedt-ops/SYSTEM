#!/usr/bin/env python3
"""Clip OSM-derived GeoJSON layers to the reviewed Baghdad boundary.

The input geometries come from a reference-complete OSM extract. This tool
preserves OSM tags/IDs, clips crossing geometry, records repairs and verifies
that every emitted geometry is covered by the approved boundary polygon.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

from shapely.geometry import GeometryCollection, shape, mapping
from shapely.validation import make_valid


LAYERS = (
    "buildings",
    "roads",
    "waterways",
    "bridges",
    "landuse",
    "amenities",
    "railway",
    "natural-water",
    "wetlands",
    "entrances",
)


def flatten_geometry(geometry: Any) -> Iterable[Any]:
    if geometry.is_empty:
        return
    if isinstance(geometry, GeometryCollection):
        for part in geometry.geoms:
            yield from flatten_geometry(part)
        return
    yield geometry


def read_boundary(path: Path):
    data = json.loads(path.read_text(encoding="utf-8"))
    features = data.get("features", [])
    if len(features) != 1:
        raise ValueError(f"Expected exactly one boundary feature, found {len(features)}")
    boundary = shape(features[0]["geometry"])
    if boundary.geom_type not in ("Polygon", "MultiPolygon"):
        raise ValueError(f"Unsupported boundary geometry: {boundary.geom_type}")
    if boundary.is_empty or not boundary.is_valid:
        raise ValueError(f"Boundary geometry is empty or invalid: {boundary.geom_type}")
    return boundary


def clip_layer(layer: str, input_path: Path, output_path: Path, boundary):
    data = json.loads(input_path.read_text(encoding="utf-8"))
    features = data.get("features", [])
    output_features = []
    geometry_counts: Counter[str] = Counter()
    coverage_boundary = boundary.buffer(1e-8)
    dropped = 0
    clipped = 0
    repaired = 0

    for feature in features:
        source_geometry = feature.get("geometry")
        if not source_geometry:
            dropped += 1
            continue

        geometry = shape(source_geometry)
        if geometry.is_empty:
            dropped += 1
            continue

        if not geometry.is_valid:
            geometry = make_valid(geometry)
            repaired += 1
        if geometry.is_empty:
            dropped += 1
            continue

        if geometry.geom_type in ("Point", "MultiPoint"):
            intersection = geometry.intersection(boundary)
        else:
            intersection = geometry.intersection(boundary)

        if intersection.is_empty:
            dropped += 1
            continue

        if not geometry.equals(intersection):
            clipped += 1

        parts = list(flatten_geometry(intersection))
        if not parts:
            dropped += 1
            continue

        properties = dict(feature.get("properties") or {})
        for index, part in enumerate(parts):
            if part.is_empty:
                continue
            if not coverage_boundary.covers(part):
                raise ValueError(
                    f"{layer}: clipped geometry is not covered by the Baghdad boundary "
                    f"(source OSM ID={properties.get('@id')})"
                )
            out_properties = dict(properties)
            if len(parts) > 1:
                out_properties["system_clip_part"] = index
            output_features.append(
                {
                    "type": "Feature",
                    "properties": out_properties,
                    "geometry": mapping(part),
                }
            )
            geometry_counts[part.geom_type] += 1

    output = {
        "type": "FeatureCollection",
        "name": layer,
        "source": "OpenStreetMap contributors via BBBike.org",
        "license": "ODbL-1.0",
        "boundary_relation": 5638803,
        "coordinate_reference_system": "EPSG:4326",
        "features": output_features,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(output, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )

    return {
        "input_features": len(features),
        "output_features": len(output_features),
        "dropped_outside_or_empty": dropped,
        "features_clipped": clipped,
        "invalid_geometries_repaired": repaired,
        "output_geometry_types": dict(geometry_counts),
        "output_bytes": output_path.stat().st_size,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--boundary", type=Path, required=True)
    parser.add_argument("--source-timestamp", required=True)
    parser.add_argument("--source-sha256", required=True)
    args = parser.parse_args()

    boundary = read_boundary(args.boundary)
    results = {}
    for layer in LAYERS:
        input_path = args.input_dir / f"{layer}.geojson"
        output_path = args.output_dir / f"{layer}.geojson"
        if not input_path.is_file():
            raise FileNotFoundError(f"Missing source layer: {input_path}")
        results[layer] = clip_layer(layer, input_path, output_path, boundary)

    report = {
        "status": "clipped_to_baghdad_boundary; review_required",
        "source_timestamp": args.source_timestamp,
        "source_sha256": args.source_sha256,
        "boundary_relation": 5638803,
        "boundary_bounds_wgs84": list(boundary.bounds),
        "boundary_area_degrees_squared": boundary.area,
        "coordinate_reference_system": "EPSG:4326",
        "coverage_tolerance_degrees": 1e-8,
        "license": "ODbL-1.0",
        "attribution": "© OpenStreetMap contributors; © BBBike.org",
        "layers": results,
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "clip-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
