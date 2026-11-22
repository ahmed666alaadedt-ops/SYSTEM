#!/usr/bin/env python3
"""Verify that the real Tigris and Republic Bridge survive into the Baghdad runtime cell pack."""

from __future__ import annotations

import argparse
import json
import math
import pathlib
import zipfile

from shapely.geometry import Point, shape
from shapely.ops import transform as transform_geometry, unary_union

ORIGIN_LAT = 33.3152
ORIGIN_LON = 44.3661
TARGET_LAT = 33.32495
TARGET_LON = 44.40483
CELL_SIZE_M = 200.0
EXPECTED_BOUNDS = [-2, 20, -8, 2]
BRIDGE_POLYGON_ID = "1077808833"
BRIDGE_LINE_ID = "754157537"
TIGRIS_WATER_POLYGON_ID = "1145641"
TIGRIS_WATERWAY_ID = "24709603"


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
    x = sum(delta[index] * east[index] for index in range(3))
    z = -sum(delta[index] * north[index] for index in range(3))
    return x, z


def _project_geometry(geometry):
    def project_xy(longitude, latitude, altitude=None):
        x, z = _project(float(longitude), float(latitude))
        if altitude is None:
            return x, z
        return x, z, altitude

    return transform_geometry(project_xy, geometry)


def _find_feature(source_dir: pathlib.Path, layer: str, feature_id: str, geometry_type: str):
    path = source_dir / f"{layer}.geojson"
    if not path.is_file():
        raise SystemExit(f"Required source layer is missing: {path}")
    source = json.loads(path.read_text(encoding="utf-8"))
    for feature in source.get("features", []):
        properties = feature.get("properties") or {}
        if str(properties.get("@id", feature.get("id", ""))) != feature_id:
            continue
        if str(feature.get("geometry", {}).get("type", "")) == geometry_type:
            return feature
    raise SystemExit(f"Missing {layer} source feature {feature_id} ({geometry_type}).")


def _assert_source_landmarks(source_dir: pathlib.Path) -> dict:
    target = Point(TARGET_LON, TARGET_LAT)
    bridge_polygon = _find_feature(source_dir, "bridges", BRIDGE_POLYGON_ID, "Polygon")
    bridge_line = _find_feature(source_dir, "bridges", BRIDGE_LINE_ID, "LineString")
    river_polygon = _find_feature(source_dir, "natural-water", TIGRIS_WATER_POLYGON_ID, "Polygon")
    river_line = _find_feature(source_dir, "waterways", TIGRIS_WATERWAY_ID, "LineString")

    bridge_tags = bridge_polygon.get("properties") or {}
    bridge_line_tags = bridge_line.get("properties") or {}
    river_tags = river_polygon.get("properties") or {}
    river_line_tags = river_line.get("properties") or {}

    if bridge_tags.get("bridge") != "yes" or bridge_tags.get("name:ar") != "جسر الجمهورية":
        raise SystemExit("Republic Bridge polygon identity/tags do not match the approved Baghdad landmark.")
    if bridge_line_tags.get("bridge") != "yes" or bridge_line_tags.get("name:ar") != "جسر الجمهورية":
        raise SystemExit("Republic Bridge road centerline identity/tags do not match.")
    if river_tags.get("natural") != "water" or river_tags.get("water") != "river":
        raise SystemExit("Tigris water-surface polygon is not tagged as a river.")
    if river_line_tags.get("waterway") != "river" or river_line_tags.get("name:ar") != "نهر دجلة":
        raise SystemExit("Tigris waterway centerline identity/tags do not match.")

    if not shape(bridge_polygon["geometry"]).covers(target):
        raise SystemExit("Approved tower target is outside the mapped Republic Bridge polygon.")
    if not shape(river_polygon["geometry"]).covers(target):
        raise SystemExit("Approved tower target is outside the mapped Tigris river-water polygon.")

    target_local = Point(*_project(TARGET_LON, TARGET_LAT))
    bridge_line_distance = _project_geometry(shape(bridge_line["geometry"])).distance(target_local)
    river_line_distance = _project_geometry(shape(river_line["geometry"])).distance(target_local)
    if bridge_line_distance > 3.0:
        raise SystemExit(f"Tower target is {bridge_line_distance:.2f} m from the Republic Bridge centerline (limit 3 m).")
    if river_line_distance > 75.0:
        raise SystemExit(f"Tigris centerline is {river_line_distance:.2f} m from the bridge target (limit 75 m).")

    cell_x = math.floor(target_local.x / CELL_SIZE_M)
    cell_z = math.floor(target_local.y / CELL_SIZE_M)
    if (cell_x, cell_z) != (18, -6):
        raise SystemExit(f"Unexpected projected Republic Bridge cell: {(cell_x, cell_z)}.")

    return {
        "target_latitude": TARGET_LAT,
        "target_longitude": TARGET_LON,
        "target_local_east_m": round(target_local.x, 2),
        "target_local_south_m": round(target_local.y, 2),
        "target_cell": [cell_x, cell_z],
        "bridge_centerline_distance_m": round(bridge_line_distance, 2),
        "tigris_centerline_distance_m": round(river_line_distance, 2),
        "bridge_polygon_id": BRIDGE_POLYGON_ID,
        "bridge_line_id": BRIDGE_LINE_ID,
        "tigris_water_polygon_id": TIGRIS_WATER_POLYGON_ID,
        "tigris_waterway_id": TIGRIS_WATERWAY_ID,
    }


def _assert_runtime_pack(pack_path: pathlib.Path, source_report: dict) -> dict:
    if not pack_path.is_file() or pack_path.stat().st_size == 0:
        raise SystemExit(f"Baghdad runtime cell pack is missing or empty: {pack_path}")

    with zipfile.ZipFile(pack_path) as archive:
        names = set(archive.namelist())
        if "manifest.json" not in names:
            raise SystemExit("Baghdad runtime cell pack has no manifest.json.")
        manifest = json.loads(archive.read("manifest.json"))
        if manifest.get("schema_version") != 1:
            raise SystemExit("Unsupported Baghdad runtime cell-pack schema.")
        if manifest.get("region_id") != "iraq_baghdad_region":
            raise SystemExit("Runtime cell pack is not the canonical Baghdad region.")
        if manifest.get("coordinate_system") != "SYSTEM_LOCAL_ECEF_TANGENT":
            raise SystemExit("Runtime cell pack uses the wrong local coordinate system.")
        if manifest.get("cell_size_m") != CELL_SIZE_M:
            raise SystemExit("Runtime cell pack does not use 200 m cells.")
        if manifest.get("cell_bounds_inclusive") != EXPECTED_BOUNDS:
            raise SystemExit(f"Runtime cell pack bounds must be {EXPECTED_BOUNDS}.")
        origin = manifest.get("origin") or {}
        if abs(float(origin.get("latitude", 0.0)) - ORIGIN_LAT) > 0.000001:
            raise SystemExit("Runtime cell pack latitude origin differs from the canonical registry.")
        if abs(float(origin.get("longitude", 0.0)) - ORIGIN_LON) > 0.000001:
            raise SystemExit("Runtime cell pack longitude origin differs from the canonical registry.")

        if manifest.get("ground_layer_schema_version") != 1:
            raise SystemExit("Runtime cell pack has no verified Baghdad ground layer.")
        if float(manifest.get("ground_elevation_m", -999.0)) != 34.0:
            raise SystemExit("Baghdad ground elevation does not match the current registry baseline.")
        if float(manifest.get("water_surface_elevation_m", -999.0)) != 28.0:
            raise SystemExit("Tigris water surface elevation is not 6 m below the municipal ground baseline.")
        if float(manifest.get("bridge_deck_elevation_m", -999.0)) != 34.28:
            raise SystemExit("Republic Bridge deck elevation is not aligned with the verified ground baseline.")
        if float(manifest.get("bridge_tower_platform_elevation_m", -999.0)) != 46.28:
            raise SystemExit("Bridge tower platform elevation does not preserve the planned 12 m clearance above the deck.")
        route = (manifest.get("landmark_routes") or {}).get("republic_bridge", {})
        if route.get("osm_bridge_centerline_id") != BRIDGE_LINE_ID:
            raise SystemExit("Manifest Republic Bridge route does not reference the verified OSM centerline.")
        if route.get("osm_tigris_centerline_id") != TIGRIS_WATERWAY_ID:
            raise SystemExit("Manifest Republic Bridge route does not reference the verified Tigris centerline.")
        if route.get("osm_tigris_water_polygon_id") != TIGRIS_WATER_POLYGON_ID:
            raise SystemExit("Manifest Republic Bridge route does not reference the verified Tigris water polygon.")
        if route.get("osm_bridge_polygon_id") != BRIDGE_POLYGON_ID:
            raise SystemExit("Manifest Republic Bridge route does not reference the verified bridge polygon.")
        route_anchor = route.get("tower_anchor_local_m", [])
        if len(route_anchor) != 2:
            raise SystemExit("Manifest Republic Bridge route has no local tower anchor.")
        expected_anchor = [
            float(source_report["target_local_east_m"]),
            float(source_report["target_local_south_m"]),
        ]
        if math.dist(route_anchor, expected_anchor) > 0.5:
            raise SystemExit("Manifest tower anchor differs from the verified geographic target.")
        bank_points = route.get("bank_access_points_local_m", [])
        if len(bank_points) != 2 or any(len(point) != 2 for point in bank_points):
            raise SystemExit("Manifest Republic Bridge route must contain two bank access points.")

        cell_names = sorted(
            name for name in names
            if name.startswith("cells/") and name.endswith(".json")
        )
        if len(cell_names) != int(manifest.get("cell_count", -1)):
            raise SystemExit("Runtime cell pack cell_count does not match its ZIP contents.")
        if not 25 <= len(cell_names) <= 253:
            raise SystemExit(f"Expanded Baghdad corridor pack has an unexpected occupied-cell count: {len(cell_names)}.")

        target_cell = source_report["target_cell"]
        target_name = f"cells/{target_cell[0]}_{target_cell[1]}.json"
        if target_name not in names:
            raise SystemExit(f"Republic Bridge target cell is missing: {target_name}")

        found = {"bridges": set(), "natural-water": set(), "waterways": set()}
        ground_geometries = []
        water_geometries = []
        ground_feature_count = 0
        ground_triangle_count = 0
        target_tile = json.loads(archive.read(target_name))
        target_layers = target_tile.get("layers", {})
        target_cell_ids = {
            "bridges": {str(item.get("id", "")) for item in target_layers.get("bridges", [])},
            "natural-water": {str(item.get("id", "")) for item in target_layers.get("natural-water", [])},
        }
        if BRIDGE_POLYGON_ID not in target_cell_ids["bridges"]:
            raise SystemExit("Republic Bridge geometry is missing from its projected runtime cell.")
        if TIGRIS_WATER_POLYGON_ID not in target_cell_ids["natural-water"]:
            raise SystemExit("Tigris water surface is missing from the Republic Bridge runtime cell.")

        for name in cell_names:
            tile = json.loads(archive.read(name))
            layers = tile.get("layers", {})
            for feature in layers.get("ground", []):
                geometry = feature.get("geometry", {})
                if geometry:
                    ground_geometries.append(shape(geometry))
                    ground_feature_count += 1
                    ground_triangle_count += len(geometry.get("coordinates", []))
            for feature in layers.get("natural-water", []):
                geometry = feature.get("geometry", {})
                if geometry:
                    water_geometries.append(shape(geometry))
            for layer, feature_ids in found.items():
                for feature in layers.get(layer, []):
                    feature_id = str(feature.get("id", ""))
                    if feature_id in {
                        BRIDGE_LINE_ID if layer == "bridges" else "",
                        TIGRIS_WATERWAY_ID if layer == "waterways" else "",
                    }:
                        found[layer].add(feature_id)

        if BRIDGE_LINE_ID not in found["bridges"]:
            raise SystemExit("Republic Bridge road centerline is missing from the expanded runtime pack.")
        if TIGRIS_WATERWAY_ID not in found["waterways"]:
            raise SystemExit("Tigris River centerline is missing from the expanded runtime pack.")
        if not ground_geometries or ground_feature_count != int(manifest.get("ground_cell_count", -1)):
            raise SystemExit("Generated Baghdad ground cells are missing or do not match the manifest.")
        if ground_triangle_count != int(manifest.get("ground_triangle_count", -1)):
            raise SystemExit("Generated Baghdad ground triangle count does not match the manifest.")
        ground_union = unary_union(ground_geometries)
        water_union = unary_union(water_geometries) if water_geometries else None
        target_local = Point(
            float(source_report["target_local_east_m"]),
            float(source_report["target_local_south_m"]),
        )
        if ground_union.covers(target_local):
            raise SystemExit("Generated ground covers the Tigris water at the Republic Bridge anchor.")
        for bank_point in bank_points:
            if not ground_union.covers(Point(float(bank_point[0]), float(bank_point[1]))):
                raise SystemExit(f"Generated ground does not reach both bank access points: {bank_point}")
        water_overlap_area = ground_union.intersection(water_union).area if water_union is not None else 0.0
        if water_overlap_area > 0.5:
            raise SystemExit(f"Generated ground overlaps mapped water by {water_overlap_area:.2f} m².")

        return {
            "cell_pack": str(pack_path),
            "cell_count": len(cell_names),
            "cell_bounds_inclusive": manifest["cell_bounds_inclusive"],
            "source_snapshot": manifest.get("source_snapshot", ""),
            "target_cell": target_name,
            "verified_runtime_features": {
                "republic_bridge_polygon": BRIDGE_POLYGON_ID,
                "republic_bridge_centerline": BRIDGE_LINE_ID,
                "tigris_water_surface": TIGRIS_WATER_POLYGON_ID,
                "tigris_centerline": TIGRIS_WATERWAY_ID,
            },
            "ground_cell_count": ground_feature_count,
            "ground_triangle_count": ground_triangle_count,
            "ground_area_m2": round(float(manifest.get("ground_area_m2", 0.0)), 2),
            "water_ground_overlap_m2": round(water_overlap_area, 3),
            "bank_access_points_local_m": bank_points,
            "tower_platform_elevation_m": float(manifest["bridge_tower_platform_elevation_m"]),
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", required=True, type=pathlib.Path)
    parser.add_argument("--pack", required=True, type=pathlib.Path)
    parser.add_argument("--report", required=True, type=pathlib.Path)
    args = parser.parse_args()

    report = {
        "audit": "baghdad_republic_bridge_and_tigris_runtime_coverage",
        "status": "failed",
        "real_osm_source_required": True,
    }
    try:
        source_report = _assert_source_landmarks(args.input_dir)
        pack_report = _assert_runtime_pack(args.pack, source_report)
        report.update(source_report)
        report.update(pack_report)
        report["status"] = "passed"
    except Exception as error:
        report["error"] = str(error)
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        raise

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
