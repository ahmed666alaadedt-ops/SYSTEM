#!/usr/bin/env python3
"""Associate OSM entrance nodes with Baghdad building footprints in a metric cell pack.

The tool never invents doors. It emits a reviewable association report and marks
ambiguous, distant, or access-restricted candidates explicitly.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import zipfile
from collections import defaultdict
from typing import Any

from shapely.geometry import mapping, shape
from shapely.ops import unary_union

# Distances are metres because the cell pack uses SYSTEM_LOCAL_ECEF_TANGENT.
CONTAINED_DISTANCE_M = 0.75
HIGH_CONFIDENCE_DISTANCE_M = 2.0
REVIEW_DISTANCE_M = 5.0
MAX_CANDIDATE_DISTANCE_M = 10.0
AMBIGUITY_MARGIN_M = 0.75
RESTRICTED_ACCESS = {"no", "private"}
NON_ENTRY_VALUES = {"no"}


def _feature_geometry(feature: dict[str, Any]):
    geometry = feature.get("geometry")
    if not isinstance(geometry, dict):
        return None
    try:
        parsed = shape(geometry)
    except Exception:
        return None
    return None if parsed.is_empty else parsed


def read_pack(pack_path: pathlib.Path) -> tuple[dict[str, Any], dict[str, list[dict[str, Any]]]]:
    manifest: dict[str, Any]
    buildings: dict[str, list[dict[str, Any]]] = defaultdict(list)
    entrances: dict[str, list[dict[str, Any]]] = defaultdict(list)
    with zipfile.ZipFile(pack_path) as archive:
        manifest = json.loads(archive.read("manifest.json"))
        if manifest.get("coordinate_system") != "SYSTEM_LOCAL_ECEF_TANGENT":
            raise ValueError("Unsupported coordinate system; expected metric local tangent coordinates.")
        for name in sorted(archive.namelist()):
            if not name.startswith("cells/") or not name.endswith(".json"):
                continue
            tile = json.loads(archive.read(name))
            layers = tile.get("layers", {})
            for feature in layers.get("buildings", []):
                feature_id = str(feature.get("id", "")).strip()
                if feature_id:
                    buildings[feature_id].append(feature)
            for feature in layers.get("entrances", []):
                feature_id = str(feature.get("id", "")).strip()
                if feature_id:
                    entrances[feature_id].append(feature)
    # Building polygons are clipped at cell boundaries. Reassemble every
    # fragment for an OSM ID before measuring entrance-to-footprint distance.
    merged_buildings: list[dict[str, Any]] = []
    for feature_id, fragments in sorted(buildings.items()):
        geometries = [geometry for geometry in
                      (_feature_geometry(item) for item in fragments)
                      if geometry is not None]
        if not geometries:
            continue
        merged = dict(fragments[0])
        merged["geometry"] = mapping(unary_union(geometries))
        merged_buildings.append(merged)

    # Entrance points may be repeated only if source tiling duplicates them;
    # retain one canonical record per OSM ID.
    unique_entrances = [items[0] for _, items in sorted(entrances.items())]
    return manifest, {"buildings": merged_buildings, "entrances": unique_entrances}


def associate_features(building_features: list[dict[str, Any]],
                       entrance_features: list[dict[str, Any]]) -> dict[str, Any]:
    building_records: list[dict[str, Any]] = []
    for feature in building_features:
        geometry = _feature_geometry(feature)
        if geometry is None or geometry.geom_type not in {"Polygon", "MultiPolygon"}:
            continue
        building_records.append({
            "id": str(feature.get("id", "")),
            "geometry": geometry,
            "tags": feature.get("tags", {}),
        })

    associations: list[dict[str, Any]] = []
    counts = defaultdict(int)
    for entrance in entrance_features:
        entrance_id = str(entrance.get("id", ""))
        tags = entrance.get("tags", {}) or {}
        point = _feature_geometry(entrance)
        if point is None or point.geom_type != "Point":
            counts["rejected_invalid_geometry"] += 1
            associations.append({"entrance_id": entrance_id, "status": "rejected",
                                 "reason": "entrance_geometry_is_not_a_point"})
            continue

        entrance_kind = str(tags.get("entrance", "")).lower()
        door_kind = str(tags.get("door", "")).lower()
        access = str(tags.get("access", "")).lower()
        if entrance_kind in NON_ENTRY_VALUES or door_kind in NON_ENTRY_VALUES:
            counts["rejected_non_entry"] += 1
            associations.append({"entrance_id": entrance_id, "status": "rejected",
                                 "reason": "OSM tags explicitly mark this point as non-entry",
                                 "entrance_tags": tags})
            continue

        candidates = []
        for building in building_records:
            distance = float(building["geometry"].distance(point))
            if distance <= MAX_CANDIDATE_DISTANCE_M:
                candidates.append((distance, building))
        candidates.sort(key=lambda item: (item[0], item[1]["id"]))

        if not candidates:
            counts["rejected_no_nearby_building"] += 1
            associations.append({"entrance_id": entrance_id, "status": "rejected",
                                 "reason": "no_building_within_10m",
                                 "entrance_tags": tags})
            continue

        best_distance, best = candidates[0]
        second_distance = candidates[1][0] if len(candidates) > 1 else None
        ambiguous = second_distance is not None and (second_distance - best_distance) < AMBIGUITY_MARGIN_M
        if ambiguous:
            status = "review"
            reason = "multiple_buildings_have_similarly_close_footprints"
            counts["review_ambiguous"] += 1
        elif access in RESTRICTED_ACCESS:
            status = "restricted"
            reason = "associated_building_but_access_tag_restricts_public_entry"
            counts["restricted_access"] += 1
        elif best_distance <= CONTAINED_DISTANCE_M:
            status = "accepted"
            reason = "entrance_point_intersects_or_touches_building_footprint"
            counts["accepted_contained"] += 1
        elif best_distance <= HIGH_CONFIDENCE_DISTANCE_M:
            status = "accepted"
            reason = "high_confidence_near_footprint_match"
            counts["accepted_nearby"] += 1
        elif best_distance <= REVIEW_DISTANCE_M:
            status = "review"
            reason = "manual_review_required_distance_2_to_5m"
            counts["review_distance"] += 1
        else:
            status = "rejected"
            reason = "nearest_building_is_more_than_5m_away"
            counts["rejected_low_confidence"] += 1

        associations.append({
            "entrance_id": entrance_id,
            "building_id": best["id"],
            "status": status,
            "reason": reason,
            "distance_m": round(best_distance, 3),
            "second_candidate": ({"building_id": candidates[1][1]["id"],
                                  "distance_m": round(second_distance, 3)}
                                 if len(candidates) > 1 else None),
            "entrance_tags": tags,
            "building_tags": best["tags"],
        })

    return {
        "summary": {
            "entrance_count": len(entrance_features),
            "building_count": len(building_records),
            "counts": dict(sorted(counts.items())),
            "accepted_count": counts["accepted_contained"] + counts["accepted_nearby"],
            "review_count": counts["review_ambiguous"] + counts["review_distance"],
            "restricted_count": counts["restricted_access"],
            "rejected_count": (counts["rejected_invalid_geometry"]
                               + counts["rejected_non_entry"]
                               + counts["rejected_no_nearby_building"]
                               + counts["rejected_low_confidence"]),
        },
        "associations": associations,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pack", required=True, type=pathlib.Path,
                        help="Generated Baghdad OSM cell-pack ZIP.")
    parser.add_argument("--output", required=True, type=pathlib.Path,
                        help="JSON report path.")
    args = parser.parse_args()
    manifest, features = read_pack(args.pack)
    report = associate_features(features["buildings"], features["entrances"])
    output = {
        "schema_version": 1,
        "region_id": manifest.get("region_id"),
        "coordinate_system": manifest.get("coordinate_system"),
        "source_snapshot": manifest.get("source_snapshot"),
        "source_license": manifest.get("license"),
        "thresholds_m": {
            "contained": CONTAINED_DISTANCE_M,
            "high_confidence": HIGH_CONFIDENCE_DISTANCE_M,
            "review": REVIEW_DISTANCE_M,
            "maximum_candidate": MAX_CANDIDATE_DISTANCE_M,
            "ambiguity_margin": AMBIGUITY_MARGIN_M,
        },
        **report,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n",
                           encoding="utf-8")
    print(json.dumps(output["summary"], ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
