"""Regression tests for the Baghdad OSM cross-cell geometry auditor."""
from __future__ import annotations

import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from shapely.geometry import LineString, Polygon, box, mapping, shape
from shapely.ops import transform

import audit_baghdad_cell_connectivity as audit


def _feature(osm_id, osm_type, geometry):
    return {
        "type": "Feature",
        "properties": {"@id": str(osm_id), "@type": osm_type},
        "geometry": mapping(geometry),
    }


def _make_fixture(root: Path, omit_east_road: bool = False):
    source = root / "source"
    source.mkdir()

    # Small deterministic fixture around the real Baghdad WGS84 anchor.
    def wgs84(x: float, z: float):
        latitude = 33.3152 - z / 110574.0
        longitude = 44.3661 + x / (111319.49 * 0.835)
        return longitude, latitude

    def polygon(points):
        return Polygon([wgs84(x, z) for x, z in points])

    source_features = {
        "roads": [_feature(101, "way", LineString([wgs84(150, 100), wgs84(250, 100)]))],
        "waterways": [_feature(102, "way", LineString([wgs84(140, 120), wgs84(260, 120)]))],
        "bridges": [_feature(103, "way", LineString([wgs84(160, 80), wgs84(240, 80)]))],
        "railway": [_feature(104, "way", LineString([wgs84(130, 140), wgs84(270, 140)]))],
        "buildings": [_feature(202, "way", polygon([(180, 30), (220, 30), (220, 70), (180, 70), (180, 30)]))],
    }
    for layer in audit.LAYERS:
        (source / f"{layer}.geojson").write_text(
            json.dumps({
                "type": "FeatureCollection",
                "coordinate_reference_system": "EPSG:4326",
                "features": source_features.get(layer, []),
            }),
            encoding="utf-8",
        )

    manifest = {
        "schema_version": 1,
        "region_id": "iraq_baghdad_region",
        "coordinate_system": "SYSTEM_LOCAL_ECEF_TANGENT",
        "origin": {"latitude": 33.3152, "longitude": 44.3661},
        "axes": {"x": "east_m", "z": "south_m"},
        "cell_size_m": 200.0,
        "cell_bounds_inclusive": [0, 1, 0, 0],
        "source_snapshot": "2026-11-20T00:00:00Z",
        "cell_count": 2,
    }
    project = audit._projector()
    projected = {
        layer: [transform(project, shape(feature["geometry"])) for feature in features]
        for layer, features in source_features.items()
    }
    id_by_layer = {"roads": 101, "waterways": 102, "bridges": 103, "railway": 104, "buildings": 202}

    pack = root / "baghdad-pack.zip"
    with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("manifest.json", json.dumps(manifest))
        for x in (0, 1):
            layers = {name: [] for name in audit.LAYERS}
            cell_box = box(x * 200, 0, (x + 1) * 200, 200)
            for layer, geometries in projected.items():
                for geometry in geometries:
                    split = (
                        layer in audit.LINE_LAYERS
                        or layer in audit.AREA_LAYERS
                        or (layer == "buildings" and geometry.geom_type in ("Polygon", "MultiPolygon"))
                    )
                    if split:
                        part = geometry.intersection(cell_box)
                    else:
                        point = geometry.representative_point()
                        part = geometry if int(point.x // 200) == x else geometry.intersection(box(x * 200, 0, (x + 1) * 200, 200))
                    if layer == "roads" and omit_east_road and x == 1:
                        continue
                    if not part.is_empty:
                        layers[layer].append({
                            "id": str(id_by_layer[layer]),
                            "osm_type": "way",
                            "tags": {},
                            "geometry": mapping(part),
                        })
            tile = {
                "schema_version": 1,
                "region_id": "iraq_baghdad_region",
                "cell_x": x,
                "cell_z": 0,
                "cell_size_m": 200.0,
                "layers": layers,
            }
            archive.writestr(f"cells/{x}_0.json", json.dumps(tile))
    return source, pack


class BaghdadCellConnectivityTests(unittest.TestCase):
    def test_real_pack_fixture_passes_and_checks_all_crossings(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreaterEqual(result["cross_cell_feature_pairs"], 5)
            self.assertEqual(result["cell_size_m"], 200.0)

    def test_missing_neighbor_road_fragment_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp), omit_east_road=True)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertGreater(result["missing_parts"], 0)

    def test_missing_real_pack_never_passes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, _pack = _make_fixture(root)
            result = audit.audit_pack(source, root / "not-installed.zip")
            self.assertEqual(result["status"], "blocked_missing_real_osm_pack")

    def test_wrong_cell_size_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            manifest = json.loads(entries["manifest.json"])
            manifest["cell_size_m"] = 100.0
            entries["manifest.json"] = json.dumps(manifest).encode()
            with zipfile.ZipFile(pack, "w") as archive:
                for name, data in entries.items():
                    archive.writestr(name, data)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertTrue(any("200 m" in error for error in result["errors"]))


if __name__ == "__main__":
    unittest.main()
