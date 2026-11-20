"""Regression tests for the Baghdad OSM cross-cell geometry auditor."""
from __future__ import annotations

import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from shapely.geometry import LineString, Polygon, box, mapping\nfrom shapely.ops import transform\nfrom shapely.geometry import shape

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
    road = LineString([(150.0, 100.0), (250.0, 100.0)])
    building = Polygon([(180, 30), (220, 30), (220, 70), (180, 70), (180, 30)])
    source_features = {"roads": [_feature(101, "way", road)],
                       "buildings": [_feature(202, "way", building)]}
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
    cells = {}
    for x in (0, 1):
        layers = {name: [] for name in audit.LAYERS}
        cell_box = box(x * 200, 0, (x + 1) * 200, 200)
        road_part = road.intersection(cell_box)
        building_part = building.intersection(cell_box)
        if not (omit_east_road and x == 1) and not road_part.is_empty:
            layers["roads"].append({
                "id": "101", "osm_type": "way", "tags": {"highway": "primary"},
                "geometry": mapping(road_part),
            })
        if not building_part.is_empty:
            layers["buildings"].append({
                "id": "202", "osm_type": "way", "tags": {"building": "yes"},
                "geometry": mapping(building_part),
            })
        cells[f"cells/{x}_0.json"] = {
            "schema_version": 1, "region_id": "iraq_baghdad_region",
            "cell_x": x, "cell_z": 0, "cell_size_m": 200.0, "layers": layers,
        }
    pack = root / "baghdad-pack.zip"
    with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("manifest.json", json.dumps(manifest))
        for name, tile in cells.items():
            archive.writestr(name, json.dumps(tile))
    return source, pack


class BaghdadCellConnectivityTests(unittest.TestCase):
    def test_real_pack_fixture_passes_and_checks_building_split(self):
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
