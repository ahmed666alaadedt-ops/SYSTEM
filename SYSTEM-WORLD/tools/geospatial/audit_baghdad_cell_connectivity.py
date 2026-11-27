#!/usr/bin/env python3
"""Audit real Baghdad OSM cell-pack continuity against the clipped source geometries.

This is a build-time data audit, not a runtime streamer. It intentionally fails
when the source layers or the generated cell-pack ZIP are absent.
"""
from __future__ import annotations

import argparse
import json
import math
import pathlib
import zipfile
from collections import defaultdict
from typing import Any

from shapely.geometry import LineString, box, mapping, shape
from shapely.ops import transform, unary_union

A = 6378137.0
INV_F = 298.257223563
F = 1.0 / INV_F
E2 = F * (2.0 - F)
EXPECTED_ORIGIN = (33.3152, 44.3661)
EXPECTED_CELL_SIZE = 200.0
TOLERANCE_M = 0.04
LAYERS = (
    "buildings", "roads", "waterways", "bridges",
    "landuse", "amenities", "railway", "natural-water", "entrances",
)
LINE_LAYERS = {"roads", "waterways", "bridges", "railway"}
AREA_LAYERS = {"landuse", "natural-water"}


class AuditError(Exception):
    pass


def _ecef(latitude: float, longitude: float) -> tuple[float, float, float]:
    lat, lon = math.radians(latitude), math.radians(longitude)
    sin_lat, cos_lat = math.sin(lat), math.cos(lat)
    radius = A / math.sqrt(1.0 - E2 * sin_lat * sin_lat)
    return (
        radius * cos_lat * math.cos(lon),
        radius * cos_lat * math.sin(lon),
        radius * (1.0 - E2) * sin_lat,
    )


def _projector():
    lat, lon = map(math.radians, EXPECTED_ORIGIN)
    origin = _ecef(*EXPECTED_ORIGIN)
    east = (-math.sin(lon), math.cos(lon), 0.0)
    north = (
        -math.sin(lat) * math.cos(lon),
        -math.sin(lat) * math.sin(lon),
        math.cos(lat),
    )

    def project(longitude, latitude, _height=None):
        point = _ecef(latitude, longitude)
        delta = tuple(point[i] - origin[i] for i in range(3))
        return (
            sum(delta[i] * east[i] for i in range(3)),
            -sum(delta[i] * north[i] for i in range(3)),
        )

    return project


def _feature_key(layer: str, feature: dict[str, Any]) -> tuple[str, str, str]:
    feature_id = str(feature.get("id", ""))
    osm_type = str(feature.get("osm_type", ""))
    if not feature_id or not osm_type:
        raise AuditError(f"{layer}: cell feature is missing its OSM ID or type")
    return layer, osm_type, feature_id


def _source_key(layer: str, feature: dict[str, Any]) -> tuple[str, str, str]:
    properties = feature.get("properties") or {}
    feature_id = str(properties.get("@id", feature.get("id", "")))
    osm_type = str(properties.get("@type", ""))
    if not feature_id or not osm_type:
        raise AuditError(f"{layer}: source feature is missing @id or @type")
    return layer, osm_type, feature_id


def _payload_geometry(payload: dict[str, Any]):
    return shape(payload)



def _builder_normalized_geometry(geometry):
    """Mirror build_baghdad_metric_cell_pack.py geometry normalization."""
    if geometry.is_empty:
        return geometry
    if not geometry.is_valid and geometry.geom_type not in ("LineString", "MultiLineString"):
        geometry = geometry.buffer(0)
    return geometry


def _geometry_dimensions(geometry) -> set[str]:
    """Return source dimensions so boundary-only polygon clips are not crossings."""
    if geometry.is_empty:
        return set()
    kind = geometry.geom_type
    if kind in ("Polygon", "MultiPolygon"):
        return {"area"}
    if kind in ("LineString", "MultiLineString", "LinearRing"):
        return {"linear"}
    if kind == "GeometryCollection":
        dimensions: set[str] = set()
        for part in geometry.geoms:
            dimensions.update(_geometry_dimensions(part))
        return dimensions
    if kind in ("Point", "MultiPoint"):
        return {"point"}
    return set()


def _builder_serialized_geometry(geometry):
    """Round-trip through the builder's exact 2-decimal GeoJSON payload."""
    if geometry.is_empty:
        return geometry

    def rounded(value):
        if isinstance(value, (list, tuple)):
            return [rounded(item) for item in value]
        if isinstance(value, float):
            return round(value, 2)
        return value

    payload = mapping(geometry)
    if geometry.geom_type == "GeometryCollection":
        payload = {"type": "GeometryCollection", "geometries": [
            mapping(part) for part in geometry.geoms if not part.is_empty
        ]}
        def round_geometry(item):
            if item.get("type") == "GeometryCollection":
                return {"type": "GeometryCollection", "geometries": [round_geometry(p) for p in item.get("geometries", [])]}
            return {"type": item["type"], "coordinates": rounded(item.get("coordinates", []))}
        payload = round_geometry(payload)
    else:
        payload = {"type": payload["type"], "coordinates": rounded(payload["coordinates"])}
    return shape(payload)

def _cell_clips_geometry(layer: str, geometry) -> bool:
    if layer in LINE_LAYERS or layer in AREA_LAYERS:
        return True
    return layer == "buildings" and geometry.geom_type in ("Polygon", "MultiPolygon")


def _expected_fragments(
    layer: str, geometry, cell_size: float, bounds: tuple[int, int, int, int]
):
    min_x, max_x, min_z, max_z = bounds
    if not _cell_clips_geometry(layer, geometry):
        point = geometry.representative_point()
        cell = (math.floor(point.x / cell_size), math.floor(point.y / cell_size))
        if min_x <= cell[0] <= max_x and min_z <= cell[1] <= max_z:
            yield cell, geometry
        return

    if geometry.is_empty:
        return
    min_fx, min_fz, max_fx, max_fz = geometry.bounds
    ix0 = max(math.floor(min_fx / cell_size), min_x)
    iz0 = max(math.floor(min_fz / cell_size), min_z)
    ix1 = min(math.floor(max_fx / cell_size), max_x)
    iz1 = min(math.floor(max_fz / cell_size), max_z)
    for ix in range(ix0, ix1 + 1):
        for iz in range(iz0, iz1 + 1):
            clipped = geometry.intersection(
                box(ix * cell_size, iz * cell_size,
                    (ix + 1) * cell_size, (iz + 1) * cell_size)
            )
            if not clipped.is_empty:
                yield (ix, iz), clipped


def _geometry_close(expected, actual) -> bool:
    if expected.is_empty or actual.is_empty:
        return expected.is_empty and actual.is_empty
    try:
        if expected.hausdorff_distance(actual) > TOLERANCE_M:
            return False
        if expected.geom_type == "GeometryCollection" or actual.geom_type == "GeometryCollection":
            delta = expected.symmetric_difference(actual)
            return (
                delta.area <= max(0.10, expected.area * 1e-6)
                and delta.length <= max(0.08, expected.length * 1e-6)
            )
        if expected.geom_type in ("Polygon", "MultiPolygon") or actual.geom_type in ("Polygon", "MultiPolygon"):
            return expected.symmetric_difference(actual).area <= max(0.10, expected.area * 1e-6)
        return abs(expected.length - actual.length) <= max(0.08, expected.length * 1e-6)
    except Exception:
        return False


def _seam_geometry(geometry, cell_a: tuple[int, int], cell_b: tuple[int, int], size: float):
    ax, az = cell_a
    bx, bz = cell_b
    if bx == ax + 1 and bz == az:
        edge = LineString([(bx * size, az * size), (bx * size, (az + 1) * size)])
    elif ax == bx + 1 and bz == az:
        edge = LineString([(ax * size, az * size), (ax * size, (az + 1) * size)])
    elif bz == az + 1 and bx == ax:
        edge = LineString([(ax * size, bz * size), ((ax + 1) * size, bz * size)])
    elif az == bz + 1 and bx == ax:
        edge = LineString([(ax * size, az * size), ((ax + 1) * size, az * size)])
    else:
        return None
    return geometry.intersection(edge)


def _geometry_diagnostics(expected, actual) -> dict[str, Any]:
    """Expose exact parity differences without relaxing geometry tolerances."""
    def describe(geometry):
        if geometry is None:
            return None
        if geometry.is_empty:
            return {"type": geometry.geom_type, "empty": True}
        return {
            "type": geometry.geom_type,
            "valid": bool(geometry.is_valid),
            "bounds": [round(float(value), 6) for value in geometry.bounds],
            "area_m2": round(float(geometry.area), 6),
            "length_m": round(float(geometry.length), 6),
        }

    result = {"expected": describe(expected), "actual": describe(actual)}
    if expected is None or actual is None or expected.is_empty or actual.is_empty:
        return result
    try:
        result["hausdorff_distance_m"] = round(float(expected.hausdorff_distance(actual)), 6)
    except Exception as exc:
        result["hausdorff_error"] = str(exc)
    try:
        delta = expected.symmetric_difference(actual)
        result["symmetric_difference"] = {
            "type": delta.geom_type,
            "area_m2": round(float(delta.area), 6),
            "length_m": round(float(delta.length), 6),
            "is_empty": bool(delta.is_empty),
        }
    except Exception as exc:
        result["symmetric_difference_error"] = str(exc)
    return result


def audit_pack(input_dir: pathlib.Path, pack_path: pathlib.Path) -> dict[str, Any]:
    report: dict[str, Any] = {
        "audit": "baghdad_osm_cross_cell_connectivity",
        "status": "failed",
        "real_osm_source_required": True,
        "source_layers": {},
        "cell_count": 0,
        "adjacent_cell_pairs": 0,
        "source_osm_features": 0,
        "verified_feature_cell_parts": 0,
        "cross_cell_feature_pairs": 0,
        "seam_checks": 0,
        "duplicate_parts": 0,
        "overlapping_parts": 0,
        "missing_parts": 0,
        "missing_feature_cell_parts": 0,
        "mismatched_feature_cell_parts": 0,
        "missing_osm_feature_ids": 0,
        "unexpected_osm_feature_ids": 0,
        "feature_id_comparison": {},
        "geometry_mismatch_diagnostics": [],
        "comparison_by_layer": {},
        "unexpected_parts": 0,
        "disconnected_seams": 0,
        "errors": [],
        "seam_mismatch_diagnostics": [],
        "tolerance_m": TOLERANCE_M,
    }

    if not input_dir.is_dir():
        report["errors"].append(f"Real clipped OSM source directory is missing: {input_dir}")
        return report
    if not pack_path.is_file() or pack_path.stat().st_size == 0:
        report["errors"].append(f"Real Baghdad OSM cell-pack ZIP is missing or empty: {pack_path}")
        report["status"] = "blocked_missing_real_osm_pack"
        return report

    try:
        with zipfile.ZipFile(pack_path) as archive:
            names = set(archive.namelist())
            if "manifest.json" not in names:
                raise AuditError("Cell pack has no manifest.json")
            manifest = json.loads(archive.read("manifest.json"))
            if manifest.get("schema_version") != 1:
                raise AuditError("Unsupported cell-pack schema version")
            if manifest.get("region_id") != "iraq_baghdad_region":
                raise AuditError("Cell-pack region ID is not canonical Baghdad")
            if manifest.get("coordinate_system") != "SYSTEM_LOCAL_ECEF_TANGENT":
                raise AuditError("Cell-pack coordinate system is not SYSTEM_LOCAL_ECEF_TANGENT")
            origin = manifest.get("origin") or {}
            if (
                abs(float(origin.get("latitude", math.nan)) - EXPECTED_ORIGIN[0]) > 1e-6
                or abs(float(origin.get("longitude", math.nan)) - EXPECTED_ORIGIN[1]) > 1e-6
            ):
                raise AuditError("Cell-pack WGS84 origin differs from the fixed Baghdad anchor")
            cell_size = float(manifest.get("cell_size_m", math.nan))
            if not math.isclose(cell_size, EXPECTED_CELL_SIZE, abs_tol=1e-6):
                raise AuditError(f"Expected unchanged 200 m cells, got {cell_size!r}")
            raw_bounds = manifest.get("cell_bounds_inclusive")
            if not isinstance(raw_bounds, list) or len(raw_bounds) != 4:
                raise AuditError("Manifest cell_bounds_inclusive is invalid")
            bounds = tuple(int(value) for value in raw_bounds)
            min_x, max_x, min_z, max_z = bounds
            if min_x > max_x or min_z > max_z:
                raise AuditError("Manifest cell bounds are inverted")

            cell_files = sorted(
                name for name in names
                if name.startswith("cells/") and name.endswith(".json")
            )
            if not cell_files:
                raise AuditError("Cell pack contains no actual cell JSON files")
            if len(cell_files) != int(manifest.get("cell_count", -1)):
                raise AuditError(
                    f"Manifest cell_count={manifest.get('cell_count')} but ZIP contains {len(cell_files)} cells"
                )

            cells: dict[tuple[int, int], dict[str, Any]] = {}
            actual: dict[tuple[tuple[int, int], tuple[str, str, str]], list[Any]] = defaultdict(list)
            seen_exact: set[tuple[tuple[int, int], tuple[str, str, str], bytes]] = set()
            for name in cell_files:
                tile = json.loads(archive.read(name))
                cell = (int(tile.get("cell_x", 999999)), int(tile.get("cell_z", 999999)))
                if cell in cells:
                    raise AuditError(f"Duplicate cell coordinates in pack: {cell}")
                if name != f"cells/{cell[0]}_{cell[1]}.json":
                    raise AuditError(f"Cell filename does not match its embedded coordinates: {name} vs {cell}")
                if not (min_x <= cell[0] <= max_x and min_z <= cell[1] <= max_z):
                    raise AuditError(f"Cell {cell} lies outside manifest bounds")
                if tile.get("region_id") != manifest["region_id"]:
                    raise AuditError(f"Cell {cell} has a different region ID")
                if not math.isclose(float(tile.get("cell_size_m", math.nan)), cell_size, abs_tol=1e-6):
                    raise AuditError(f"Cell {cell} does not use the manifest cell size")
                cells[cell] = tile
                layers = tile.get("layers")
                if not isinstance(layers, dict):
                    raise AuditError(f"Cell {cell} has no layers object")
                for layer in LAYERS:
                    if not isinstance(layers.get(layer, []), list):
                        raise AuditError(f"Cell {cell} layer {layer} is not an array")
                    for feature in layers.get(layer, []):
                        key = _feature_key(layer, feature)
                        geometry = _payload_geometry(feature.get("geometry") or {})
                        exact_key = (cell, key, geometry.wkb)
                        if exact_key in seen_exact:
                            report["duplicate_parts"] += 1
                        seen_exact.add(exact_key)
                        actual[(cell, key)].append(geometry)

            report["cell_count"] = len(cells)
            report["source_snapshot"] = manifest.get("source_snapshot", "")
            report["cell_size_m"] = cell_size
            report["origin"] = origin
            if not report["source_snapshot"]:
                raise AuditError("Manifest does not identify the real OSM source snapshot")

            project = _projector()
            expected: dict[tuple[tuple[int, int], tuple[str, str, str]], list[Any]] = defaultdict(list)
            source_keys: set[tuple[str, str, str]] = set()
            source_dimensions: dict[tuple[str, str, str], set[str]] = defaultdict(set)
            for layer in LAYERS:
                source_path = input_dir / f"{layer}.geojson"
                if not source_path.is_file() or source_path.stat().st_size == 0:
                    raise AuditError(f"Required real OSM source layer is missing: {source_path}")
                source = json.loads(source_path.read_text(encoding="utf-8"))
                if source.get("coordinate_reference_system") != "EPSG:4326":
                    raise AuditError(f"{layer}: source layer is not EPSG:4326")
                layer_keys: set[tuple[str, str, str]] = set()
                for feature in source.get("features", []):
                    source_geometry = feature.get("geometry")
                    if not source_geometry:
                        continue
                    key = _source_key(layer, feature)
                    geometry = transform(project, shape(source_geometry))
                    geometry = _builder_normalized_geometry(geometry)
                    if geometry.is_empty:
                        continue
                    source_keys.add(key)
                    layer_keys.add(key)
                    source_dimensions[key].update(_geometry_dimensions(geometry))
                    # The builder assigns non-clipped features to a cell per source
                    # feature. Never unary_union separate OSM feature records first:
                    # that changes representative_point() for mixed amenity layers.
                    for cell, fragment in _expected_fragments(layer, geometry, cell_size, bounds):
                        expected[(cell, key)].append(_builder_serialized_geometry(fragment))
                report["source_layers"][layer] = len(layer_keys)

            report["source_osm_features"] = len(source_keys)
            expected_union = {key: unary_union(items) for key, items in expected.items()}
            actual_union = {key: unary_union(items) for key, items in actual.items()}

            # Compare OSM feature identity independently from per-cell geometry
            # parity. A feature missing from every cell, or an unknown ID injected
            # into the pack, must be visible as an ID-level failure as well.
            expected_feature_keys = {feature_key for _cell, feature_key in expected_union}
            actual_feature_keys = {feature_key for _cell, feature_key in actual_union}
            # The clipped source covers the whole Baghdad municipality, while
            # the generated pack intentionally covers its configured municipal cell bounds.
            # Only IDs with at least one expected in-bounds cell fragment can be
            # called missing from this pack.
            missing_feature_keys = sorted(expected_feature_keys - actual_feature_keys)
            unexpected_feature_keys = sorted(actual_feature_keys - expected_feature_keys)
            report["missing_osm_feature_ids"] = len(missing_feature_keys)
            report["unexpected_osm_feature_ids"] = len(unexpected_feature_keys)
            report["feature_id_comparison"] = {
                "source_osm_feature_ids_total": len(source_keys),
                "expected_cell_feature_ids": len(expected_feature_keys),
                "actual_feature_ids": len(actual_feature_keys),
                "missing_osm_feature_ids": [
                    {"layer": key[0], "osm_type": key[1], "osm_id": key[2]}
                    for key in missing_feature_keys
                ],
                "unexpected_osm_feature_ids": [
                    {"layer": key[0], "osm_type": key[1], "osm_id": key[2]}
                    for key in unexpected_feature_keys
                ],
            }
            for feature_key in missing_feature_keys:
                report["errors"].append(
                    f"Missing OSM feature ID from cell pack: {feature_key}"
                )
            for feature_key in unexpected_feature_keys:
                report["errors"].append(
                    f"Unexpected OSM feature ID not expected in the audited cell bounds: {feature_key}"
                )

            for key, geometry in expected_union.items():
                cell, feature_key = key
                layer = feature_key[0]
                layer_stats = report["comparison_by_layer"].setdefault(
                    layer, {"expected": 0, "verified": 0, "missing": 0, "mismatched": 0}
                )
                layer_stats["expected"] += 1
                if cell not in cells:
                    report["missing_parts"] += 1
                    report["missing_feature_cell_parts"] += 1
                    layer_stats["missing"] += 1
                    report["errors"].append(f"Missing cell {cell} for expected OSM part {feature_key}")
                    continue
                candidate = actual_union.get(key)
                if candidate is None:
                    report["missing_parts"] += 1
                    report["missing_feature_cell_parts"] += 1
                    layer_stats["missing"] += 1
                    report["errors"].append(f"Missing OSM part in cell {cell}: {feature_key}")
                    continue
                if not _geometry_close(geometry, candidate):
                    report["missing_parts"] += 1
                    report["mismatched_feature_cell_parts"] += 1
                    layer_stats["mismatched"] += 1
                    report["geometry_mismatch_diagnostics"].append({
                        "cell": [cell[0], cell[1]],
                        "layer": layer,
                        "osm_type": feature_key[1],
                        "osm_id": feature_key[2],
                        "expected_source_records": len(expected[key]),
                        "actual_cell_records": len(actual.get(key, [])),
                        "metrics": _geometry_diagnostics(geometry, candidate),
                    })
                    report["errors"].append(
                        f"Geometry mismatch in cell {cell}: {feature_key}"
                    )
                else:
                    report["verified_feature_cell_parts"] += 1
                    layer_stats["verified"] += 1

            for key in actual_union:
                if key not in expected_union:
                    report["unexpected_parts"] += 1
                    report["errors"].append(f"Unexpected OSM part not present in clipped source: {key}")

            if report["duplicate_parts"]:
                report["errors"].append(
                    f"Found {report['duplicate_parts']} byte-identical duplicate OSM parts in cells"
                )

            # Keep source parity and actual generated-cell seam checks separate.
            # Candidate keys come from BOTH the expected source and actual pack,
            # and every continuity measurement below is taken from actual_union.
            cell_set = set(cells)
            expected_keys_by_cell: dict[tuple[int, int], set[tuple[str, str, str]]] = defaultdict(set)
            actual_keys_by_cell: dict[tuple[int, int], set[tuple[str, str, str]]] = defaultdict(set)
            for cell, feature_key in expected_union:
                expected_keys_by_cell[cell].add(feature_key)
            for cell, feature_key in actual_union:
                actual_keys_by_cell[cell].add(feature_key)
            neighbor_pairs = set()
            for x, z in cell_set:
                for neighbor in ((x + 1, z), (x, z + 1)):
                    if neighbor in cell_set:
                        neighbor_pairs.add(((x, z), neighbor))
            report["adjacent_cell_pairs"] = len(neighbor_pairs)
            seam_report = {
                "geometry_source": "actual_generated_cell_geometries",
                "checked_actual_cell_geometries": True,
                "checks_by_layer": {},
                "missing_neighbor_fragments": 0,
                "unexpected_neighbor_fragments": 0,
                "disconnected_seams": 0,
                "valid_boundary_touches": 0,
                "non_crossing_adjacent_cell_features": 0,
                "non_clipped_layer_features": 0,
                "overlapping_fragments": 0,
            }

            def has_interior(geometry, feature_key):
                # Use the original source dimensions, not the clipped fragment's
                # resulting type: a polygon that merely touches a cell can clip to
                # a LineString, but that is not polygon interior in that cell.
                if geometry is None or geometry.is_empty:
                    return False
                dimensions = source_dimensions.get(feature_key, set())
                if dimensions == {"area"}:
                    return geometry.area > 1e-6
                if dimensions == {"linear"}:
                    return geometry.length > 1e-6
                if "area" in dimensions or "linear" in dimensions:
                    return geometry.area > 1e-6 or geometry.length > 1e-6
                return False

            def record_seam_error(layer, message):
                report["disconnected_seams"] += 1
                seam_report["disconnected_seams"] += 1
                stats = seam_report["checks_by_layer"].setdefault(
                    layer, {"checks": 0, "disconnected": 0}
                )
                stats["disconnected"] += 1
                report["errors"].append(message)

            for cell_a, cell_b in sorted(neighbor_pairs):
                expected_a_keys = expected_keys_by_cell.get(cell_a, set())
                expected_b_keys = expected_keys_by_cell.get(cell_b, set())
                actual_a_keys = actual_keys_by_cell.get(cell_a, set())
                actual_b_keys = actual_keys_by_cell.get(cell_b, set())
                expected_shared = expected_a_keys & expected_b_keys
                actual_shared = actual_a_keys & actual_b_keys
                # Include actual-only keys so unexpected cell geometry cannot
                # escape the seam section merely because it is absent in source.
                feature_keys = expected_shared | actual_shared

                for feature_key in sorted(feature_keys):
                    layer = feature_key[0]
                    expected_geometry_a = expected_union.get((cell_a, feature_key))
                    expected_geometry_b = expected_union.get((cell_b, feature_key))
                    actual_geometry_a = actual_union.get((cell_a, feature_key))
                    actual_geometry_b = actual_union.get((cell_b, feature_key))

                    if feature_key in actual_shared and feature_key not in expected_shared:
                        seam_report["unexpected_neighbor_fragments"] += 1
                        report["errors"].append(
                            f"Unexpected OSM feature appears in both adjacent cells: "
                            f"{feature_key}, {cell_a}<->{cell_b}"
                        )
                        continue

                    # Some layers (notably amenities) are intentionally assigned
                    # to one representative-point cell by the builder. Same-ID
                    # components in adjacent cells are not split fragments and
                    # must not be treated as a connected seam.
                    if not (
                        _cell_clips_geometry(layer, expected_geometry_a)
                        or _cell_clips_geometry(layer, expected_geometry_b)
                    ):
                        seam_report["non_clipped_layer_features"] += 1
                        continue

                    # Only require continuity when the source has real geometry
                    # inside both cells. Boundary-only contacts are valid and are
                    # already checked by expected-vs-actual part parity.
                    if not has_interior(expected_geometry_a, feature_key) or not has_interior(expected_geometry_b, feature_key):
                        if feature_key in expected_shared:
                            seam_report["valid_boundary_touches"] += 1
                        continue

                    expected_edge_a = _seam_geometry(
                        expected_geometry_a, cell_a, cell_b, cell_size
                    )
                    expected_edge_b = _seam_geometry(
                        expected_geometry_b, cell_a, cell_b, cell_size
                    )
                    if expected_edge_a is None or expected_edge_b is None:
                        record_seam_error(
                            layer,
                            f"Could not calculate source shared-edge intersection for "
                            f"{feature_key}, {cell_a}<->{cell_b}",
                        )
                        continue
                    # A feature may occupy both cells while travelling around
                    # their common edge (for example, a curved road that exits
                    # through another side and later re-enters). Empty expected
                    # intersections mean there is no seam to connect.
                    if expected_edge_a.is_empty or expected_edge_b.is_empty:
                        seam_report["non_crossing_adjacent_cell_features"] += 1
                        continue

                    report["cross_cell_feature_pairs"] += 1
                    report["seam_checks"] += 1
                    layer_stats = seam_report["checks_by_layer"].setdefault(
                        layer, {"checks": 0, "disconnected": 0}
                    )
                    layer_stats["checks"] += 1

                    if actual_geometry_a is None or actual_geometry_b is None:
                        seam_report["missing_neighbor_fragments"] += 1
                        record_seam_error(
                            layer,
                            f"Actual generated cell is missing a crossing neighbor fragment: "
                            f"{feature_key}, {cell_a}<->{cell_b}",
                        )
                        continue

                    actual_edge_a = _seam_geometry(
                        actual_geometry_a, cell_a, cell_b, cell_size
                    )
                    actual_edge_b = _seam_geometry(
                        actual_geometry_b, cell_a, cell_b, cell_size
                    )
                    if any(edge is None for edge in (
                        expected_edge_a, expected_edge_b, actual_edge_a, actual_edge_b
                    )):
                        record_seam_error(
                            layer,
                            f"Could not calculate shared-edge intersection for "
                            f"{feature_key}, {cell_a}<->{cell_b}",
                        )
                        continue

                    mismatch = (
                        expected_edge_a.is_empty
                        or expected_edge_b.is_empty
                        or actual_edge_a.is_empty
                        or actual_edge_b.is_empty
                        or not _geometry_close(expected_edge_a, expected_edge_b)
                        or not _geometry_close(expected_edge_a, actual_edge_a)
                        or not _geometry_close(expected_edge_b, actual_edge_b)
                        or not _geometry_close(actual_edge_a, actual_edge_b)
                    )
                    if layer in LINE_LAYERS and not mismatch:
                        # Roads, waterways, bridge lines and railway segments
                        # must meet at the same point(s) on the actual shared edge.
                        mismatch = actual_edge_a.distance(actual_edge_b) > TOLERANCE_M
                    if mismatch:
                        report["seam_mismatch_diagnostics"].append({
                            "layer": layer,
                            "feature_key": list(feature_key),
                            "cell_a": list(cell_a),
                            "cell_b": list(cell_b),
                            "expected_edge_a": expected_edge_a.wkt[:1200],
                            "expected_edge_b": expected_edge_b.wkt[:1200],
                            "actual_edge_a": actual_edge_a.wkt[:1200],
                            "actual_edge_b": actual_edge_b.wkt[:1200],
                            "expected_a_b_hausdorff_m": round(expected_edge_a.hausdorff_distance(expected_edge_b), 6),
                            "actual_a_b_hausdorff_m": round(actual_edge_a.hausdorff_distance(actual_edge_b), 6),
                            "expected_actual_a_hausdorff_m": round(expected_edge_a.hausdorff_distance(actual_edge_a), 6),
                            "expected_actual_b_hausdorff_m": round(expected_edge_b.hausdorff_distance(actual_edge_b), 6),
                            "actual_a_b_distance_m": round(actual_edge_a.distance(actual_edge_b), 6),
                        })
                        record_seam_error(
                            layer,
                            f"Actual geometry seam mismatch for {feature_key}: "
                            f"{cell_a}<->{cell_b}",
                        )

            report["actual_cell_seam_checks"] = seam_report

            # Detect non-identical overlaps between fragments with the same OSM key.
            overlap_errors = []
            for (cell, feature_key), geometries in actual.items():
                for index, left in enumerate(geometries):
                    for right in geometries[index + 1:]:
                        if left.is_empty or right.is_empty or not left.intersects(right):
                            continue
                        overlap = left.intersection(right)
                        magnitude = overlap.area if overlap.geom_type in ("Polygon", "MultiPolygon") else overlap.length
                        has_area = left.area > 1e-9 or right.area > 1e-9
                        is_overlap = overlap.area > 0.01 if has_area else overlap.length > 0.01
                        if is_overlap:
                            report["overlapping_parts"] = report.get("overlapping_parts", 0) + 1
                            seam_report["overlapping_fragments"] += 1
                            overlap_errors.append(f"Overlapping fragments for {feature_key} in cell {cell}")
            report["actual_cell_seam_checks"] = seam_report
            report["expected_source_comparison"] = {
                "expected_feature_cell_parts": len(expected_union),
                "actual_feature_cell_keys": len(actual_union),
                "verified_feature_cell_parts": report["verified_feature_cell_parts"],
                "missing_or_mismatched_parts": report["missing_parts"],
                "missing_parts": report["missing_feature_cell_parts"],
                "mismatched_parts": report["mismatched_feature_cell_parts"],
                "comparison_by_layer": report["comparison_by_layer"],
                "unexpected_parts": report["unexpected_parts"],
                "duplicate_exact_parts": report["duplicate_parts"],
                "overlapping_parts": report.get("overlapping_parts", 0),
            }
            report["errors"].extend(overlap_errors)
            if report["duplicate_parts"]:
                report["errors"].append(
                    f"Found {report['duplicate_parts']} byte-identical duplicate OSM parts in cells"
                )

            report["status"] = "passed" if not report["errors"] else "failed"
    except (OSError, ValueError, KeyError, TypeError, zipfile.BadZipFile, AuditError) as exc:
        report["errors"].append(str(exc))
        report["status"] = "failed"

    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", required=True, type=pathlib.Path)
    parser.add_argument("--pack", required=True, type=pathlib.Path)
    parser.add_argument("--report", type=pathlib.Path)
    args = parser.parse_args()
    report = audit_pack(args.input_dir, args.pack)
    output = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(output, encoding="utf-8")
    print(output, end="")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
