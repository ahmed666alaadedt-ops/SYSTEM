#!/usr/bin/env python3
"""Build deterministic 200 m Baghdad metric cell tiles from clipped OSM GeoJSON."""
from __future__ import annotations

import argparse
import json
import math
import pathlib
import zipfile
from collections import defaultdict

from shapely.geometry import box, shape
from shapely.ops import transform

A = 6378137.0
INV_F = 298.257223563
F = 1.0 / INV_F
E2 = F * (2.0 - F)
ORIGIN_LAT = 33.3152
ORIGIN_LON = 44.3661
DEFAULT_CELL_SIZE = 200.0
LAYERS = (
    "buildings", "roads", "waterways", "bridges",
    "landuse", "amenities", "railway", "natural-water", "wetlands", "entrances"
)
LINE_LAYERS = {"roads", "waterways", "bridges", "railway"}
AREA_LAYERS = {"landuse", "natural-water", "wetlands"}
KEEP_TAGS = {
    "name", "name:en", "name:ar", "ref", "highway", "building",
    "building:levels", "building:material", "height", "min_height",
    "roof:shape", "roof:material", "roof:colour", "roof:height",
    "roof:levels", "roof:angle", "roof:orientation", "bridge", "waterway", "natural",
    "landuse", "amenity", "railway", "surface", "maxspeed", "lanes",
    "oneway", "access", "service", "tunnel", "layer", "leisure",
    "shop", "tourism", "historic", "man_made", "water", "place",
    "religion", "operator", "aeroway", "military", "security", "barrier", "foot", "cycleway",
    "wetland", "tidal", "seasonal", "marsh",
    "healthcare", "emergency", "office", "craft", "cuisine", "opening_hours",
    "public_transport", "brand", "building:use", "addr:street", "addr:city",
    "entrance", "door", "wheelchair", "level", "indoor",
    "lit", "street_lamp", "crossing", "crossing:island", "traffic_signals",
    "traffic_calming", "bus", "bus_stop", "shelter", "bench",
    "drinking_water", "waste_basket", "toilets", "fountain", "playground",
    "parking", "bicycle_parking", "motorcycle_parking", "parking:lane",
    "kerb", "tactile_paving", "incline", "smoothness", "footway",
    "sidewalk", "sidewalk:left", "sidewalk:right", "cycleway:left",
    "cycleway:right", "lanes:forward", "lanes:backward", "turn:lanes",
    "junction", "access:conditional", "fee", "network", "route"
}


def _ecef(latitude: float, longitude: float) -> tuple[float, float, float]:
    lat = math.radians(latitude)
    lon = math.radians(longitude)
    sin_lat = math.sin(lat)
    cos_lat = math.cos(lat)
    radius = A / math.sqrt(1.0 - E2 * sin_lat * sin_lat)
    return (
        radius * cos_lat * math.cos(lon),
        radius * cos_lat * math.sin(lon),
        radius * (1.0 - E2) * sin_lat,
    )


def _make_projector():
    lat = math.radians(ORIGIN_LAT)
    lon = math.radians(ORIGIN_LON)
    origin = _ecef(ORIGIN_LAT, ORIGIN_LON)
    east = (-math.sin(lon), math.cos(lon), 0.0)
    north = (
        -math.sin(lat) * math.cos(lon),
        -math.sin(lat) * math.sin(lon),
        math.cos(lat),
    )

    def project(longitude, latitude, _height=None):
        point = _ecef(latitude, longitude)
        delta = tuple(point[i] - origin[i] for i in range(3))
        x = sum(delta[i] * east[i] for i in range(3))
        z = -sum(delta[i] * north[i] for i in range(3))
        return x, z

    return project


def _rounded(value):
    if isinstance(value, (list, tuple)):
        return [_rounded(item) for item in value]
    if isinstance(value, float):
        return round(value, 2)
    return value


def _geometry_payload(geometry):
    if geometry.is_empty:
        return None
    if geometry.geom_type == "GeometryCollection":
        parts = [
            _geometry_payload(part)
            for part in geometry.geoms
            if not part.is_empty
        ]
        return {"type": "GeometryCollection", "geometries": [p for p in parts if p]}
    from shapely.geometry import mapping
    return {
        "type": geometry.geom_type,
        "coordinates": _rounded(mapping(geometry)["coordinates"]),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--cell-size", type=float, default=DEFAULT_CELL_SIZE)
    parser.add_argument("--source-timestamp", required=True)
    parser.add_argument("--layers", default=",".join(LAYERS),
                        help="comma-separated source layers to include")
    parser.add_argument("--bounds-geojson", type=pathlib.Path,
                        help="derive inclusive metric cell bounds from a WGS84 boundary GeoJSON")
    parser.add_argument("--cell-bounds", default="-2,2,-2,2",
                        help="inclusive min_x,max_x,min_z,max_z cell coordinates")
    args = parser.parse_args()
    if args.cell_size <= 0:
        raise SystemExit("cell size must be positive")
    selected_layers = tuple(item.strip() for item in args.layers.split(",") if item.strip())
    unknown_layers = sorted(set(selected_layers) - set(LAYERS))
    if not selected_layers or unknown_layers:
        raise SystemExit(f"invalid --layers selection: {unknown_layers or args.layers!r}")

    project = _make_projector()
    if args.bounds_geojson:
        boundary_data = json.loads(args.bounds_geojson.read_text(encoding="utf-8"))
        boundary_features = boundary_data.get("features", [])
        if len(boundary_features) != 1 or not boundary_features[0].get("geometry"):
            raise SystemExit("bounds GeoJSON must contain exactly one boundary geometry")
        projected_boundary = transform(project, shape(boundary_features[0]["geometry"]))
        if projected_boundary.is_empty or not projected_boundary.is_valid:
            raise SystemExit("bounds boundary geometry is empty or invalid")
        min_bx, min_bz, max_bx, max_bz = projected_boundary.bounds
        min_x = math.floor(min_bx / args.cell_size)
        max_x = math.floor(max_bx / args.cell_size)
        min_z = math.floor(min_bz / args.cell_size)
        max_z = math.floor(max_bz / args.cell_size)
    else:
        min_x, max_x, min_z, max_z = (int(value) for value in args.cell_bounds.split(","))
    if min_x > max_x or min_z > max_z:
        raise SystemExit("invalid cell bounds")

    cells = defaultdict(lambda: defaultdict(list))
    source_counts = defaultdict(int)
    emitted_counts = defaultdict(int)

    for layer in selected_layers:
        source_path = args.input_dir / f"{layer}.geojson"
        if not source_path.is_file():
            raise SystemExit(f"missing required source layer: {source_path}")
        source = json.loads(source_path.read_text(encoding="utf-8"))
        if source.get("coordinate_reference_system") != "EPSG:4326":
            raise SystemExit(f"unexpected CRS in {source_path.name}")
        for feature in source.get("features", []):
            if not feature.get("geometry"):
                continue
            geometry = transform(project, shape(feature["geometry"]))
            if geometry.is_empty:
                continue
            if not geometry.is_valid and geometry.geom_type not in ("LineString", "MultiLineString"):
                geometry = geometry.buffer(0)
            if geometry.is_empty:
                continue
            properties = feature.get("properties", {})
            feature_id = str(properties.get("@id", feature.get("id", "")))
            if not feature_id:
                continue
            tags = {
                key: str(value)
                for key, value in properties.items()
                if key in KEEP_TAGS and value not in (None, "")
            }
            record = {
                "id": feature_id,
                "osm_type": str(properties.get("@type", "")),
                "tags": tags,
            }
            source_counts[layer] += 1
            min_fx, min_fz, max_fx, max_fz = geometry.bounds
            ix0 = max(math.floor(min_fx / args.cell_size), min_x)
            iz0 = max(math.floor(min_fz / args.cell_size), min_z)
            ix1 = min(math.floor(max_fx / args.cell_size), max_x)
            iz1 = min(math.floor(max_fz / args.cell_size), max_z)

            if layer in LINE_LAYERS or layer in AREA_LAYERS:
                for ix in range(ix0, ix1 + 1):
                    for iz in range(iz0, iz1 + 1):
                        cell_bounds = box(
                            ix * args.cell_size,
                            iz * args.cell_size,
                            (ix + 1) * args.cell_size,
                            (iz + 1) * args.cell_size,
                        )
                        clipped = geometry.intersection(cell_bounds)
                        payload = _geometry_payload(clipped)
                        if payload is None:
                            continue
                        cells[(ix, iz)][layer].append(
                            {**record, "geometry": payload}
                        )
                        emitted_counts[layer] += 1
            else:
                center = geometry.representative_point()
                ix = math.floor(center.x / args.cell_size)
                iz = math.floor(center.y / args.cell_size)
                if min_x <= ix <= max_x and min_z <= iz <= max_z:
                    payload = _geometry_payload(geometry)
                    if payload is not None:
                        cells[(ix, iz)][layer].append(
                            {**record, "geometry": payload}
                        )
                        emitted_counts[layer] += 1

    manifest = {
        "schema_version": 1,
        "region_id": "iraq_baghdad_region",
        "coordinate_system": "SYSTEM_LOCAL_ECEF_TANGENT",
        "origin": {"latitude": ORIGIN_LAT, "longitude": ORIGIN_LON},
        "axes": {"x": "east_m", "z": "south_m"},
        "cell_size_m": args.cell_size,
        "cell_bounds_inclusive": [min_x, max_x, min_z, max_z],
        "layers_included": list(selected_layers),
        "source": "OpenStreetMap contributors; BBBike.org",
        "license": "ODbL-1.0",
        "source_snapshot": args.source_timestamp,
        "boundary_relation": 5638803,
        "source_feature_counts": dict(source_counts),
        "emitted_feature_parts": dict(emitted_counts),
        "cell_count": len(cells),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(
        args.output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
    ) as archive:
        archive.writestr(
            "manifest.json",
            json.dumps(manifest, separators=(",", ":")),
        )
        for (ix, iz), layers in sorted(cells.items()):
            tile = {
                "schema_version": 1,
                "region_id": "iraq_baghdad_region",
                "cell_x": ix,
                "cell_z": iz,
                "cell_size_m": args.cell_size,
                "layers": layers,
            }
            archive.writestr(
                f"cells/{ix}_{iz}.json",
                json.dumps(tile, ensure_ascii=False, separators=(",", ":")),
            )
    manifest["output_bytes"] = args.output.stat().st_size
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
