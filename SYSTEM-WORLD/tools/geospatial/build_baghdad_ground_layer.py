#!/usr/bin/env python3
"""Add a flat, water-cut Baghdad municipal ground surface to the streamed OSM cell pack.

The source is the verified Baghdad municipal boundary minus mapped natural-water
polygons. Elevations are explicit game-world assumptions until a DEM is added.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import pathlib
import tempfile
import zipfile

from shapely import constrained_delaunay_triangles
from shapely.geometry import Point, box, mapping, shape
from shapely.ops import transform, unary_union

ORIGIN_LAT = 33.3152
ORIGIN_LON = 44.3661
TARGET_LAT = 33.32495
TARGET_LON = 44.40483
CELL_SIZE_M = 200.0
GROUND_ELEVATION_M = 34.0
WATER_SURFACE_ELEVATION_M = 28.0
BRIDGE_DECK_ELEVATION_M = 34.28
TOWER_PLATFORM_CLEARANCE_M = 12.0
BRIDGE_POLYGON_ID = "1077808833"
BRIDGE_LINE_ID = "754157537"
TIGRIS_WATER_POLYGON_ID = "1145641"
TIGRIS_WATERWAY_ID = "24709603"
BOUNDARY_RELATION_ID = "5638803"


def _ecef(latitude: float, longitude: float) -> tuple[float, float, float]:
    semi_major = 6378137.0
    inverse_flattening = 298.257223563
    flattening = 1.0 / inverse_flattening
    eccentricity_squared = flattening * (2.0 - flattening)
    lat = math.radians(latitude)
    lon = math.radians(longitude)
    sin_lat = math.sin(lat)
    cos_lat = math.cos(lat)
    radius = semi_major / math.sqrt(1.0 - eccentricity_squared * sin_lat * sin_lat)
    return (
        radius * cos_lat * math.cos(lon),
        radius * cos_lat * math.sin(lon),
        radius * (1.0 - eccentricity_squared) * sin_lat,
    )


def _project(longitude: float, latitude: float) -> tuple[float, float]:
    origin = _ecef(ORIGIN_LAT, ORIGIN_LON)
    lat0 = math.radians(ORIGIN_LAT)
    lon0 = math.radians(ORIGIN_LON)
    east = (-math.sin(lon0), math.cos(lon0), 0.0)
    north = (
        -math.sin(lat0) * math.cos(lon0),
        -math.sin(lat0) * math.sin(lon0),
        math.cos(lat0),
    )
    point = _ecef(latitude, longitude)
    delta = tuple(point[index] - origin[index] for index in range(3))
    return (
        sum(delta[index] * east[index] for index in range(3)),
        -sum(delta[index] * north[index] for index in range(3)),
    )


def _project_geometry(geometry):
    def project_xy(longitude, latitude, altitude=None):
        x, z = _project(float(longitude), float(latitude))
        return (x, z) if altitude is None else (x, z, altitude)

    return transform(project_xy, geometry)


def _find_feature(features: list[dict], feature_id: str, geometry_type: str) -> dict:
    for feature in features:
        properties = feature.get("properties") or {}
        if str(properties.get("@id", feature.get("id", ""))) == feature_id:
            if str(feature.get("geometry", {}).get("type", "")) == geometry_type:
                return feature
    raise SystemExit(f"Missing required OSM feature {feature_id} ({geometry_type}).")


def _round_coordinates(value):
    if isinstance(value, (list, tuple)):
        return [_round_coordinates(item) for item in value]
    if isinstance(value, float):
        return round(value, 2)
    return value


def _triangle_coordinates(triangle) -> list:
    coordinates = mapping(triangle)["coordinates"]
    return _round_coordinates(coordinates)


def _load_source_geometry(boundary_path: pathlib.Path, water_path: pathlib.Path, bridge_path: pathlib.Path):
    boundary_document = json.loads(boundary_path.read_text(encoding="utf-8"))
    boundary_feature = _find_feature(
        boundary_document.get("features", []), BOUNDARY_RELATION_ID, "MultiPolygon"
    )
    boundary_tags = boundary_feature.get("properties") or {}
    if boundary_tags.get("boundary") != "administrative" or boundary_tags.get("name:ar") != "بغداد":
        raise SystemExit("Ground source is not the verified Baghdad administrative boundary.")

    water_document = json.loads(water_path.read_text(encoding="utf-8"))
    water_features = [
        feature for feature in water_document.get("features", [])
        if feature.get("geometry") and feature.get("geometry", {}).get("type") in ("Polygon", "MultiPolygon")
    ]
    if not water_features:
        raise SystemExit("No mapped natural-water polygons are available for the Baghdad ground cutout.")
    water_geometries = [_project_geometry(shape(feature["geometry"])) for feature in water_features]
    water_union = unary_union(water_geometries)
    boundary_geometry = _project_geometry(shape(boundary_feature["geometry"]))
    ground_geometry = boundary_geometry.difference(water_union)

    bridge_document = json.loads(bridge_path.read_text(encoding="utf-8"))
    bridge_features = bridge_document.get("features", [])
    bridge_polygon = _find_feature(bridge_features, BRIDGE_POLYGON_ID, "Polygon")
    bridge_line = _find_feature(bridge_features, BRIDGE_LINE_ID, "LineString")
    river_line_document = json.loads(water_path.parent.joinpath("waterways.geojson").read_text(encoding="utf-8"))
    river_line = _find_feature(river_line_document.get("features", []), TIGRIS_WATERWAY_ID, "LineString")
    river_polygon = _find_feature(water_features, TIGRIS_WATER_POLYGON_ID, "Polygon")

    target_wgs84 = Point(TARGET_LON, TARGET_LAT)
    if not shape(bridge_polygon["geometry"]).covers(target_wgs84):
        raise SystemExit("Republic Bridge target is outside the mapped bridge polygon.")
    if not shape(river_polygon["geometry"]).covers(target_wgs84):
        raise SystemExit("Republic Bridge target is outside the mapped Tigris water polygon.")

    target_local = Point(*_project(TARGET_LON, TARGET_LAT))
    bridge_local = _project_geometry(shape(bridge_line["geometry"]))
    river_local = _project_geometry(shape(river_line["geometry"]))
    bridge_distance = bridge_local.distance(target_local)
    river_distance = river_local.distance(target_local)
    if bridge_distance > 3.0:
        raise SystemExit(f"Tower anchor is {bridge_distance:.2f} m from the Republic Bridge centerline.")
    if river_distance > 75.0:
        raise SystemExit(f"Tigris centerline is {river_distance:.2f} m from the Republic Bridge anchor.")

    line_coordinates = list(shape(bridge_line["geometry"]).coords)
    centerline_local = [_project(longitude, latitude) for longitude, latitude in line_coordinates]
    start = centerline_local[0]
    end = centerline_local[-1]
    dx = end[0] - start[0]
    dz = end[1] - start[1]
    length = math.hypot(dx, dz)
    if length < 100.0:
        raise SystemExit("Republic Bridge centerline is too short to define both bank approaches.")
    direction = (dx / length, dz / length)
    bank_points = [
        [round(target_local.x - direction[0] * 350.0, 2), round(target_local.y - direction[1] * 350.0, 2)],
        [round(target_local.x + direction[0] * 350.0, 2), round(target_local.y + direction[1] * 350.0, 2)],
    ]
    return {
        "boundary_geometry": boundary_geometry,
        "ground_geometry": ground_geometry,
        "water_union": water_union,
        "target_local": target_local,
        "centerline_local": [[round(x, 2), round(z, 2)] for x, z in centerline_local],
        "bank_points": bank_points,
        "water_feature_count": len(water_features),
        "bridge_distance_m": bridge_distance,
        "river_distance_m": river_distance,
    }


def _build_ground_triangles(ground_cell):
    if ground_cell.is_empty or ground_cell.area < 1.0:
        return []
    triangulated = constrained_delaunay_triangles(ground_cell)
    candidates = list(getattr(triangulated, "geoms", []))
    if triangulated.geom_type == "Polygon":
        candidates = [triangulated]
    triangles = [
        triangle for triangle in candidates
        if triangle.geom_type == "Polygon"
        and triangle.area > 0.01
        and ground_cell.covers(triangle)
    ]
    return sorted(triangles, key=lambda item: (round(item.centroid.x, 2), round(item.centroid.y, 2)))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--boundary", required=True, type=pathlib.Path)
    parser.add_argument("--water-layer", required=True, type=pathlib.Path)
    parser.add_argument("--bridge-layer", required=True, type=pathlib.Path)
    parser.add_argument("--pack", required=True, type=pathlib.Path)
    parser.add_argument("--report", required=True, type=pathlib.Path)
    args = parser.parse_args()

    source = _load_source_geometry(args.boundary, args.water_layer, args.bridge_layer)
    target_local = source["target_local"]
    target_cell = [math.floor(target_local.x / CELL_SIZE_M), math.floor(target_local.y / CELL_SIZE_M)]
    ground_union = source["ground_geometry"]
    if ground_union.covers(target_local):
        raise SystemExit("The Tigris river cutout was not preserved at the Republic Bridge anchor.")
    for bank_point in source["bank_points"]:
        if not ground_union.covers(Point(bank_point)):
            raise SystemExit(f"Mapped ground does not reach both Republic Bridge banks: {bank_point}")

    if not args.pack.is_file():
        raise SystemExit(f"Runtime cell pack is missing: {args.pack}")

    with zipfile.ZipFile(args.pack, "r") as archive:
        members = {name: archive.read(name) for name in archive.namelist()}
    if "manifest.json" not in members:
        raise SystemExit("Runtime cell pack has no manifest.json.")
    manifest = json.loads(members["manifest.json"])
    if manifest.get("cell_size_m") != CELL_SIZE_M:
        raise SystemExit("Ground generation requires the canonical 200 m cell size.")
    if manifest.get("cell_bounds_inclusive") != [-2, 20, -8, 2]:
        raise SystemExit("Ground generation requires the expanded Baghdad core-to-Republic Bridge bounds.")

    ground_cell_count = 0
    triangle_count = 0
    ground_area = 0.0
    ground_union_from_cells = []
    cell_names = sorted(
        name for name in members
        if name.startswith("cells/") and name.endswith(".json")
    )
    for name in cell_names:
        tile = json.loads(members[name])
        cell_x = int(tile["cell_x"])
        cell_z = int(tile["cell_z"])
        cell_bounds = box(
            cell_x * CELL_SIZE_M,
            cell_z * CELL_SIZE_M,
            (cell_x + 1) * CELL_SIZE_M,
            (cell_z + 1) * CELL_SIZE_M,
        )
        ground_cell = source["ground_geometry"].intersection(cell_bounds)
        triangles = _build_ground_triangles(ground_cell)
        layers = tile.setdefault("layers", {})
        layers.pop("ground", None)
        if not triangles:
            members[name] = json.dumps(tile, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
            continue

        coordinates = [_triangle_coordinates(triangle) for triangle in triangles]
        feature = {
            "id": f"baghdad_ground_{cell_x}_{cell_z}",
            "osm_type": "generated",
            "tags": {"landuse": "residential", "name": "Baghdad municipal ground foundation"},
            "geometry": {"type": "MultiPolygon", "coordinates": coordinates},
        }
        layers["ground"] = [feature]
        ground_cell_count += 1
        triangle_count += len(triangles)
        ground_area += sum(triangle.area for triangle in triangles)
        ground_union_from_cells.extend(triangles)
        members[name] = json.dumps(tile, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

    if not ground_union_from_cells:
        raise SystemExit("No Baghdad ground triangles were generated.")

    ground_union_runtime = unary_union(ground_union_from_cells)
    if ground_union_runtime.covers(target_local):
        raise SystemExit("Generated runtime ground incorrectly covers the Tigris bridge anchor.")
    for bank_point in source["bank_points"]:
        if not ground_union_runtime.covers(Point(bank_point)):
            raise SystemExit(f"Generated runtime ground is missing a bank approach: {bank_point}")

    manifest["ground_layer_schema_version"] = 1
    manifest["ground_source_relation_id"] = int(BOUNDARY_RELATION_ID)
    manifest["ground_water_exclusion_layer"] = "natural-water"
    manifest["ground_elevation_m"] = GROUND_ELEVATION_M
    manifest["water_surface_elevation_m"] = WATER_SURFACE_ELEVATION_M
    manifest["bridge_deck_elevation_m"] = BRIDGE_DECK_ELEVATION_M
    manifest["bridge_tower_platform_elevation_m"] = BRIDGE_DECK_ELEVATION_M + TOWER_PLATFORM_CLEARANCE_M
    manifest["ground_cell_count"] = ground_cell_count
    manifest["ground_triangle_count"] = triangle_count
    manifest["ground_area_m2"] = round(ground_area, 2)
    manifest["landmark_routes"] = {
        "republic_bridge": {
            "osm_bridge_polygon_id": BRIDGE_POLYGON_ID,
            "osm_bridge_centerline_id": BRIDGE_LINE_ID,
            "osm_tigris_water_polygon_id": TIGRIS_WATER_POLYGON_ID,
            "osm_tigris_centerline_id": TIGRIS_WATERWAY_ID,
            "name_ar": "جسر الجمهورية",
            "name_en": "Republic Bridge",
            "tower_anchor_local_m": [round(target_local.x, 2), round(target_local.y, 2)],
            "centerline_local_m": source["centerline_local"],
            "bank_access_points_local_m": source["bank_points"],
            "bridge_deck_elevation_m": BRIDGE_DECK_ELEVATION_M,
            "tower_platform_elevation_m": BRIDGE_DECK_ELEVATION_M + TOWER_PLATFORM_CLEARANCE_M,
            "river_surface_elevation_m": WATER_SURFACE_ELEVATION_M,
            "river_clearance_to_tower_platform_m": round(
                BRIDGE_DECK_ELEVATION_M + TOWER_PLATFORM_CLEARANCE_M - WATER_SURFACE_ELEVATION_M, 2
            ),
        }
    }
    members["manifest.json"] = json.dumps(manifest, ensure_ascii=False, indent=2).encode("utf-8")

    args.pack.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=args.pack.stem + ".", suffix=".tmp.zip", dir=args.pack.parent
    )
    os.close(descriptor)
    try:
        with zipfile.ZipFile(temporary_name, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as output:
            for name in sorted(members):
                output.writestr(name, members[name])
        os.replace(temporary_name, args.pack)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)

    report = {
        "audit": "baghdad_ground_foundation_and_republic_bridge_access",
        "status": "passed",
        "source_boundary_relation_id": int(BOUNDARY_RELATION_ID),
        "excluded_natural_water_feature_count": source["water_feature_count"],
        "ground_cell_count": ground_cell_count,
        "ground_triangle_count": triangle_count,
        "ground_area_m2": round(ground_area, 2),
        "ground_elevation_m": GROUND_ELEVATION_M,
        "water_surface_elevation_m": WATER_SURFACE_ELEVATION_M,
        "bridge_deck_elevation_m": BRIDGE_DECK_ELEVATION_M,
        "tower_platform_elevation_m": BRIDGE_DECK_ELEVATION_M + TOWER_PLATFORM_CLEARANCE_M,
        "tower_anchor_local_m": [round(target_local.x, 2), round(target_local.y, 2)],
        "target_cell": target_cell,
        "bridge_centerline_distance_m": round(source["bridge_distance_m"], 2),
        "tigris_centerline_distance_m": round(source["river_distance_m"], 2),
        "bank_access_points_local_m": source["bank_points"],
        "pack": str(args.pack),
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
