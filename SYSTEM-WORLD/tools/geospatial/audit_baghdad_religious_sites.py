#!/usr/bin/env python3
"""Audit Baghdad OSM worship features without treating OSM as a complete census."""
from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path


def load_features(path: Path):
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("features", [])


def preferred_geometry(geometries: set[str]) -> str:
    for candidate in ("Polygon", "MultiPolygon", "Point", "LineString"):
        if candidate in geometries:
            return candidate
    return "unknown"


def classify(tags: dict[str, object]) -> str | None:
    amenity = str(tags.get("amenity", "")).lower()
    religion = str(tags.get("religion", "")).lower()
    building = str(tags.get("building", "")).lower()
    explicit_worship = amenity in {"place_of_worship", "monastery"} or building in {
        "mosque", "church", "chapel", "cathedral", "synagogue", "temple", "monastery", "shrine"
    }
    # Match the runtime classifier for generic public/religious building tags.
    religious_building = religion in {
        "muslim", "islam", "christian", "christianity"
    } and building in {"public", "religious"}
    if not explicit_worship and not religious_building:
        return None
    if amenity == "monastery" or building == "monastery":
        return "monastery"
    if (religion in {"muslim", "islam"} and building in {"church", "chapel", "cathedral"}) or (
        religion in {"christian", "christianity"} and building == "mosque"
    ):
        return "conflict"
    if religion in {"muslim", "islam"}:
        return "mosque"
    if religion in {"christian", "christianity"}:
        return "church"
    if building == "mosque":
        return "mosque"
    if building in {"church", "chapel", "cathedral"}:
        return "church"
    if building == "shrine":
        return "shrine"
    return "other_or_unspecified"

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--source-verification", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    objects: dict[tuple[str, str], dict[str, object]] = {}
    layer_counts = {}
    for layer_name in ("amenities", "buildings"):
        features = load_features(args.input_dir / f"{layer_name}.geojson")
        layer_counts[layer_name] = len(features)
        for feature in features:
            properties = feature.get("properties") or {}
            osm_type = str(properties.get("@type", ""))
            osm_id = str(properties.get("@id", ""))
            if not osm_type or not osm_id:
                continue
            key = (osm_type, osm_id)
            record = objects.setdefault(key, {"tags": {}, "geometries": set(), "layers": set()})
            record["tags"].update(properties)
            geometry_type = (feature.get("geometry") or {}).get("type", "unknown")
            record["geometries"].add(geometry_type)
            record["layers"].add(layer_name)

    categories: Counter[str] = Counter()
    geometry_counts: dict[str, Counter[str]] = defaultdict(Counter)
    conflicts = []
    raw_religions: Counter[str] = Counter()
    raw_place_of_worship = 0
    raw_monastery = 0
    for (osm_type, osm_id), record in sorted(objects.items()):
        tags = record["tags"]
        if str(tags.get("amenity", "")).lower() == "place_of_worship":
            raw_place_of_worship += 1
            raw_religions[str(tags.get("religion", "")).lower() or "(missing)"] += 1
        if str(tags.get("amenity", "")).lower() == "monastery":
            raw_monastery += 1
        category = classify(tags)
        if category is None:
            continue
        geometry = preferred_geometry(record["geometries"])
        categories[category] += 1
        geometry_counts[category][geometry] += 1
        if category == "conflict":
            conflicts.append({
                "osm_type": osm_type,
                "osm_id": int(osm_id),
                "name": tags.get("name:ar") or tags.get("name"),
                "amenity": tags.get("amenity"),
                "religion": tags.get("religion"),
                "building": tags.get("building"),
                "geometry": geometry,
                "layers": sorted(record["layers"]),
                "review_required": True,
            })

    source = json.loads(args.source_verification.read_text(encoding="utf-8"))
    totals = {
        "unique_worship_objects": sum(categories.values()),
        "mosques": categories["mosque"],
        "churches": categories["church"],
        "shrines": categories["shrine"],
        "monasteries": categories["monastery"],
        "other_or_unspecified": categories["other_or_unspecified"],
        "conflicting_tags": categories["conflict"],
        "raw_amenity_place_of_worship_objects": raw_place_of_worship,
        "raw_amenity_monastery_objects": raw_monastery,
    }
    report = {
        "schema_version": "1.1",
        "region": "Baghdad Municipality, Iraq",
        "boundary_relation": 5638803,
        "source": "OpenStreetMap contributors; BBBike.org Iraq PBF extract",
        "source_snapshot_utc": source.get("snapshot_timestamp"),
        "source_file_sha256": source.get("source_file_sha256"),
        "license": "ODbL-1.0",
        "status": "reproducible_osm_snapshot_audit_not_ground_truth",
        "deduplication": "Unique OSM objects keyed by @type + @id across clipped amenities and buildings; when an object has several geometries, polygon is preferred over point and line for the geometry count.",
        "source_layer_feature_counts": layer_counts,
        "totals": totals,
        "raw_place_of_worship_by_religion": dict(sorted(raw_religions.items())),
        "preferred_geometry_counts": {
            category: dict(sorted(counts.items()))
            for category, counts in sorted(geometry_counts.items())
        },
        "tag_conflicts": conflicts,
        "limitations": [
            "Counts describe this downloaded OSM snapshot only, not a complete census of real-world Baghdad places of worship.",
            "OSM tags can be missing or contradictory; unspecified objects remain neutral and conflicts are not assigned a religious architectural silhouette.",
            "A mapped polygon proves only an imported exterior footprint, not a verified interior, collision, signage, or visual fidelity.",
            "The 1 km regional overview and 200 m detailed cell pack require separate validation.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
