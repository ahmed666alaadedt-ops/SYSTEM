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

from shapely.geometry import LineString, box, shape
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
        "missing_parts": 0,
        "unexpected_parts": 0,
        "disconnected_seams": 0,
        "errors": [],
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
            for layer in LAYERS:
                source_path = input_dir / f"{layer}.geojson"
                if not source_path.is_file() or source_path.stat().st_size == 0:
                    raise AuditError(f"Required real OSM source layer is missing: {source_path}")
                source = json.loads(source_path.read_text(encoding="utf-8"))
                if source.get("coordinate_reference_system") != "EPSG:4326":
                    raise AuditError(f"{layer}: source layer is not EPSG:4326")
                grouped: dict[tuple[str, str, str], list[Any]] = defaultdict(list)
                for feature in source.get("features", []):
                    source_geometry = feature.get("geometry")
                    if not source_geometry:
                        continue
                    key = _source_key(layer, feature)
                    geometry = transform(project, shape(source_geometry))
                    if geometry.is_empty:
                        continue
                    grouped[key].append(geometry)
                report["source_layers"][layer] = len(grouped)
                for key, geometries in grouped.items():
                    source_keys.add(key)
                    source_geometry = unary_union(geometries)
                    for cell, fragment in _expected_fragments(layer, source_geometry, cell_size, bounds):
                        expected[(cell, key)].append(fragment)

            report["source_osm_features"] = len(source_keys)
            expected_union = {key: unary_union(items) for key, items in expected.items()}
            actual_union = {key: unary_union(items) for key, items in actual.items()}

            for key, geometry in expected_union.items():
                cell, feature_key = key
                if cell not in cells:
                    report["missing_parts"] += 1
                    report["errors"].append(f"Missing cell {cell} for expected OSM part {feature_key}")
                    continue
                candidate = actual_union.get(key)
                if candidate is None:
                    report["missing_parts"] += 1
                    report["errors"].append(f"Missing OSM part in cell {cell}: {feature_key}")
                    continue
                if not _geometry_close(geometry, candidate):
                    report["missing_parts"] += 1
                    report["errors"].append(
                        f"Geometry mismatch or disconnected/missing fragment in cell {cell}: {feature_key}"
                    )
                else:
                    report["verified_feature_cell_parts"] += 1

            for key in actual_union:
                if key not in expected_union:
                    report["unexpected_parts"] += 1
                    report["errors"].append(f"Unexpected OSM part not present in clipped source: {key}")

            if report["duplicate_parts"]:
                report["errors"].append(
                    f"Found {report['duplicate_parts']} byte-identical duplicate OSM parts in cells"
                )

            # Check every occupied east/south neighbor pair, and verify seams for
            # each OSM feature whose source geometry occupies both cells.
            cell_set = set(cells)
            neighbor_pairs = set()
            for x, z in cell_set:
                for neighbor in ((x + 1, z), (x, z + 1)):
                    if neighbor in cell_set:
                        neighbor_pairs.add(((x, z), neighbor))
            report["adjacent_cell_pairs"] = len(neighbor_pairs)

            for cell_a, cell_b in sorted(neighbor_pairs):
                keys_a = {key for cell, key in expected_union if cell == cell_a}
                keys_b = {key for cell, key in expected_union if cell == cell_b}
                for feature_key in keys_a.intersection(keys_b):
                    geometry_a = expected_union[(cell_a, feature_key)]
                    geometry_b = expected_union[(cell_b, feature_key)]
                    layer = feature_key[0]
                    combined = geometry_a.union(geometry_b)
                    seam_a = _seam_geometry(geometry_a, cell_a, cell_b, cell_size)
                    seam_b = _seam_geometry(geometry_b, cell_a, cell_b, cell_size)
                    if seam_a is None or seam_b is None or combined.is_empty:
                        continue
                    source_seam = _seam_geometry(combined, cell_a, cell_b, cell_size)
                    if source_seam is None or source_seam.is_empty:
                        continue
                    report["cross_cell_feature_pairs"] += 1
                    report["seam_checks"] += 1
                    if seam_a.is_empty or seam_b.is_empty:
                        report["disconnected_seams"] += 1
                        report["errors"].append(
                            f"OSM feature does not meet both sides of shared cell edge: {feature_key}, {cell_a}<->{cell_b}"
                        )
                    elif layer in LINE_LAYERS and geometry_a.geom_type in ("LineString", "MultiLineString", "Point", "MultiPoint"):
                        if seam_a.distance(seam_b) > TOLERANCE_M:
                            report["disconnected_seams"] += 1
                            report["errors"].append(
                                f"Line endpoint discontinuity at cell edge: {feature_key}, {cell_a}<->{cell_b}"
                            )
                    else:
                        if not _geometry_close(seam_a, seam_b):
                            report["disconnected_seams"] += 1
                            report["errors"].append(
                                f"Area/building edge mismatch at cell boundary: {feature_key}, {cell_a}<->{cell_b}"
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
