"""Regression tests for the Baghdad OSM cross-cell geometry auditor."""
from __future__ import annotations

import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from shapely.geometry import GeometryCollection, LineString, MultiLineString, MultiPolygon, Point, Polygon, box, mapping, shape
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
        layer: [
            audit._builder_normalized_geometry(transform(project, shape(feature["geometry"])))
            for feature in features
        ]
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
                            "geometry": mapping(audit._builder_serialized_geometry(part)),
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


def _append_projected_feature(source: Path, pack: Path, layer: str, osm_id: int, osm_type: str, geometry):
    source_path = source / f"{layer}.geojson"
    data = json.loads(source_path.read_text(encoding="utf-8"))
    data["features"].append(_feature(osm_id, osm_type, geometry))
    source_path.write_text(json.dumps(data), encoding="utf-8")
    projected = audit._builder_normalized_geometry(
        transform(audit._projector(), geometry)
    )
    with zipfile.ZipFile(pack, "r") as archive:
        entries = {name: archive.read(name) for name in archive.namelist()}
    for x in (0, 1):
        tile_name = f"cells/{x}_0.json"
        tile = json.loads(entries[tile_name])
        split = layer in audit.LINE_LAYERS or layer in audit.AREA_LAYERS or (
            layer == "buildings" and projected.geom_type in ("Polygon", "MultiPolygon")
        )
        if split:
            fragment = projected.intersection(box(x * 200, 0, (x + 1) * 200, 200))
        else:
            point = projected.representative_point()
            target = (int(point.x // 200), int(point.y // 200))
            if target != (x, 0):
                continue
            fragment = projected
        if not fragment.is_empty:
            tile["layers"][layer].append({
                "id": str(osm_id), "osm_type": osm_type, "tags": {},
                "geometry": mapping(audit._builder_serialized_geometry(fragment)),
            })
        entries[tile_name] = json.dumps(tile).encode()
    with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, payload in entries.items():
            archive.writestr(name, payload)



class BaghdadCellConnectivityTests(unittest.TestCase):
    def test_geometry_parity_mismatch_has_exact_diagnostic_metrics(self):
        expected = LineString([(0, 0), (100, 0)])
        actual = LineString([(0, 0), (100, 3)])
        details = audit._geometry_diagnostics(expected, actual)
        self.assertEqual(details["expected"]["type"], "LineString")
        self.assertEqual(details["actual"]["type"], "LineString")
        self.assertGreater(details["hausdorff_distance_m"], 0)
        self.assertGreater(details["symmetric_difference"]["length_m"], 0)

    def test_real_pack_fixture_passes_and_checks_all_crossings(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreaterEqual(result["cross_cell_feature_pairs"], 5)
            self.assertEqual(result["cell_size_m"], 200.0)
            self.assertTrue(result["actual_cell_seam_checks"]["checked_actual_cell_geometries"])

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


    def test_multiple_source_parts_with_one_osm_id_keep_per_feature_cell_assignment(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            path = source / "amenities.geojson"
            data = json.loads(path.read_text(encoding="utf-8"))
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            data["features"] = [
                _feature(777, "node", Point(wgs84(40, 80))),
                _feature(777, "node", Point(wgs84(260, 80))),
            ]
            path.write_text(json.dumps(data), encoding="utf-8")
            project = audit._projector()
            points = [transform(project, shape(item["geometry"])) for item in data["features"]]
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            for x, point in enumerate(points):
                tile_name = f"cells/{x}_0.json"
                tile = json.loads(entries[tile_name])
                tile["layers"]["amenities"].append({
                    "id": "777", "osm_type": "node", "tags": {},
                    "geometry": mapping(audit._builder_serialized_geometry(point)),
                })
                entries[tile_name] = json.dumps(tile).encode()
            with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                for name, payload in entries.items():
                    archive.writestr(name, payload)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])

    def test_geometry_collection_is_audited_as_the_builder_serializes_it(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            collection = GeometryCollection([
                LineString([wgs84(25, 160), wgs84(35, 160)]),
                Point(wgs84(30, 165)),
                Polygon([
                    wgs84(30, 150), wgs84(36, 150), wgs84(36, 156),
                    wgs84(30, 156), wgs84(30, 150),
                ]),
            ])
            _append_projected_feature(source, pack, "amenities", 810, "way", collection)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            with zipfile.ZipFile(pack) as archive:
                cells = [
                    json.loads(archive.read(f"cells/{x}_0.json"))
                    for x in (0, 1)
                ]
            stored = [
                feature
                for tile in cells
                for feature in tile["layers"]["amenities"]
                if feature["id"] == "810"
            ]
            self.assertEqual(len(stored), 1)
            self.assertEqual(stored[0]["geometry"]["type"], "GeometryCollection")

    def test_invalid_polygon_repair_matches_builder_and_real_pack_geometry(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            invalid = Polygon([
                wgs84(175, 25), wgs84(215, 65), wgs84(175, 65),
                wgs84(215, 25), wgs84(175, 25),
            ])
            self.assertFalse(transform(audit._projector(), invalid).is_valid)
            _append_projected_feature(source, pack, "buildings", 811, "way", invalid)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])


    def test_multipolygon_building_crosses_cells_and_preserves_all_parts(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            west = Polygon([wgs84(x, z) for x, z in [(175, 20), (210, 20), (210, 60), (175, 60), (175, 20)]])
            east = Polygon([wgs84(x, z) for x, z in [(40, 30), (55, 30), (55, 45), (40, 45), (40, 30)]])
            _append_projected_feature(source, pack, "buildings", 808, "way", MultiPolygon([west, east]))
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])

    def test_multipolygon_crossing_seam_ignores_separate_point_touch(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)

            def wgs84(x, z):
                latitude = 33.3152 - z / 110574.0
                longitude = 44.3661 + x / (111319.49 * 0.835)
                project = audit._projector()
                for _ in range(8):
                    projected_x, projected_z = transform(
                        project, Point(longitude, latitude)
                    ).coords[0]
                    longitude += (x - projected_x) / (111319.49 * 0.835)
                    latitude -= (z - projected_z) / 110574.0
                return longitude, latitude

            crossing_component = Polygon([
                wgs84(180, 30), wgs84(220, 30), wgs84(220, 70),
                wgs84(180, 70), wgs84(180, 30),
            ])
            point_touch_component = Polygon([
                wgs84(200, 80), wgs84(180, 70), wgs84(180, 90),
                wgs84(200, 80),
            ])
            feature = MultiPolygon([crossing_component, point_touch_component])
            _append_projected_feature(source, pack, "buildings", 947581133, "way", feature)

            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertEqual(result["actual_cell_seam_checks"]["disconnected_seams"], 0)

    def test_bridge_polygon_crossing_cell_boundary_is_audited(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            polygon = Polygon([wgs84(x, z) for x, z in [(190, 75), (210, 75), (210, 85), (190, 85), (190, 75)]])
            _append_projected_feature(source, pack, "bridges", 809, "way", polygon)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])


    def test_multiple_clipped_road_pieces_with_one_osm_id_are_unioned_after_assignment(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            west_piece = LineString([wgs84(150, 90), wgs84(250, 90)])
            second_piece = LineString([wgs84(145, 105), wgs84(255, 105)])
            _append_projected_feature(source, pack, "roads", 812, "way", west_piece)
            _append_projected_feature(source, pack, "roads", 812, "way", second_piece)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreaterEqual(result["expected_source_comparison"]["expected_feature_cell_parts"], 2)

    def test_same_osm_line_in_adjacent_cells_without_shared_edge_is_not_a_seam(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)
            disjoint = MultiLineString([
                [wgs84(20, 50), wgs84(60, 50)],
                [wgs84(240, 50), wgs84(280, 50)],
            ])
            _append_projected_feature(source, pack, "roads", 814, "way", disjoint)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreater(
                result["actual_cell_seam_checks"]["non_crossing_adjacent_cell_features"], 0
            )

    def test_polygon_that_only_touches_neighbor_edge_is_not_a_disconnected_seam(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)
            def wgs84(x, z):
                latitude = 33.3152 - z / 110574.0
                longitude = 44.3661 + x / (111319.49 * 0.835)
                project = audit._projector()
                for _ in range(8):
                    projected_x, projected_z = transform(
                        project, Point(longitude, latitude)
                    ).coords[0]
                    longitude += (x - projected_x) / (111319.49 * 0.835)
                    latitude -= (z - projected_z) / 110574.0
                return longitude, latitude
            # Place the east edge 1 mm beyond the boundary: the builder
            # emits a non-empty east-cell sliver, then 2-decimal GeoJSON
            # serialization collapses that sliver to a boundary-only part.
            touching_building = Polygon([
                wgs84(160, 20), wgs84(200.001, 20), wgs84(200.001, 60),
                wgs84(160, 60), wgs84(160, 20),
            ])
            _append_projected_feature(source, pack, "buildings", 813, "way", touching_building)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreater(
                result["actual_cell_seam_checks"]["valid_boundary_touches"], 0
            )
            self.assertEqual(result["disconnected_seams"], 0)


    def test_adjacent_cells_with_same_osm_id_but_no_shared_edge_crossing_are_valid(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)

            def wgs84(x, z):
                return (
                    44.3661 + x / (111319.49 * 0.835),
                    33.3152 - z / 110574.0,
                )

            _append_projected_feature(
                source,
                pack,
                "roads",
                813,
                "way",
                LineString([wgs84(40, 100), wgs84(80, 100)]),
            )
            _append_projected_feature(
                source,
                pack,
                "roads",
                813,
                "way",
                LineString([wgs84(250, 100), wgs84(290, 100)]),
            )

            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreater(
                result["actual_cell_seam_checks"]["non_crossing_adjacent_cell_features"],
                0,
            )
            self.assertEqual(result["disconnected_seams"], 0)


    def test_mixed_amenity_point_line_polygon_records_are_audited_individually(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)

            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)

            line = LineString([wgs84(190, 80), wgs84(234, 120)])
            polygon = Polygon([
                wgs84(190, 80), wgs84(234, 80), wgs84(234, 120),
                wgs84(190, 120), wgs84(190, 80),
            ])
            point = Point(wgs84(100, 100))
            _append_projected_feature(source, pack, "amenities", 950, "way", line)
            _append_projected_feature(source, pack, "amenities", 950, "way", polygon)
            _append_projected_feature(source, pack, "amenities", 951, "node", point)

            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreater(
                result["actual_cell_seam_checks"]["non_clipped_layer_features"], 0
            )
            with zipfile.ZipFile(pack, "r") as archive:
                west = json.loads(archive.read("cells/0_0.json"))
                east = json.loads(archive.read("cells/1_0.json"))
            west_950 = [f for f in west["layers"]["amenities"] if f["id"] == "950"]
            east_950 = [f for f in east["layers"]["amenities"] if f["id"] == "950"]
            self.assertEqual(len(west_950), 1)
            self.assertEqual(len(east_950), 1)
            self.assertEqual(shape(west_950[0]["geometry"]).geom_type, "LineString")
            self.assertEqual(shape(east_950[0]["geometry"]).geom_type, "Polygon")

    def test_landuse_polygon_crossing_multiple_cells_is_audited(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source, pack = _make_fixture(root)

            def wgs84(x, z):
                return (44.3661 + x / (111319.49 * 0.835), 33.3152 - z / 110574.0)

            polygon = Polygon([
                wgs84(175, 30), wgs84(225, 30), wgs84(225, 70),
                wgs84(175, 70), wgs84(175, 30),
            ])
            _append_projected_feature(source, pack, "landuse", 820, "way", polygon)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertGreaterEqual(
                result["expected_source_comparison"]["expected_feature_cell_parts"], 2
            )

    def test_actual_disconnected_road_seam_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            tile = json.loads(entries["cells/1_0.json"])
            road = next(item for item in tile["layers"]["roads"] if item["id"] == "101")
            geometry = shape(road["geometry"])
            coordinates = list(geometry.coords)
            edge_index = min(
                range(len(coordinates)),
                key=lambda index: abs(coordinates[index][0] - 200.0),
            )
            coordinates[edge_index] = (
                coordinates[edge_index][0] + 5.0,
                coordinates[edge_index][1],
            )
            road["geometry"] = mapping(LineString(coordinates))
            entries["cells/1_0.json"] = json.dumps(tile).encode()
            with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                for name, payload in entries.items():
                    archive.writestr(name, payload)

            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertGreater(result["disconnected_seams"], 0)
            self.assertTrue(
                any("Actual geometry seam mismatch" in error for error in result["errors"])
            )

    def test_unexpected_osm_id_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            tile = json.loads(entries["cells/0_0.json"])
            tile["layers"]["roads"].append({
                "id": "999999", "osm_type": "way", "tags": {},
                "geometry": mapping(LineString([(20, 20), (30, 20)])),
            })
            entries["cells/0_0.json"] = json.dumps(tile).encode()
            with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                for name, payload in entries.items():
                    archive.writestr(name, payload)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertGreater(result["unexpected_parts"], 0)
            self.assertEqual(result["unexpected_osm_feature_ids"], 1)
            self.assertEqual(
                result["feature_id_comparison"]["unexpected_osm_feature_ids"][0]["osm_id"],
                "999999",
            )


    def test_source_feature_ids_outside_cell_pack_extent_are_not_missing(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            roads_path = source / "roads.geojson"
            data = json.loads(roads_path.read_text(encoding="utf-8"))

            def wgs84(x, z):
                return (
                    44.3661 + x / (111319.49 * 0.835),
                    33.3152 - z / 110574.0,
                )

            data["features"].append(
                _feature(
                    999998,
                    "way",
                    LineString([wgs84(1000, 80), wgs84(1040, 80)]),
                )
            )
            roads_path.write_text(json.dumps(data), encoding="utf-8")

            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "passed", result["errors"])
            self.assertEqual(result["missing_osm_feature_ids"], 0)
            comparison = result["feature_id_comparison"]
            self.assertGreater(comparison["source_osm_feature_ids_total"], comparison["expected_cell_feature_ids"])
            self.assertEqual(comparison["expected_cell_feature_ids"], comparison["actual_feature_ids"])


    def test_missing_osm_feature_id_is_reported_separately_from_missing_fragments(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            target_key = None
            for name in sorted(n for n in entries if n.startswith("cells/") and n.endswith(".json")):
                tile = json.loads(entries[name])
                roads = tile["layers"].get("roads", [])
                if roads:
                    target_key = (roads[0]["id"], roads[0]["osm_type"])
                    break
            self.assertIsNotNone(target_key)
            for name in sorted(n for n in entries if n.startswith("cells/") and n.endswith(".json")):
                tile = json.loads(entries[name])
                tile["layers"]["roads"] = [
                    feature for feature in tile["layers"].get("roads", [])
                    if (feature["id"], feature["osm_type"]) != target_key
                ]
                entries[name] = json.dumps(tile).encode()
            with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                for name, payload in entries.items():
                    archive.writestr(name, payload)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertEqual(result["missing_osm_feature_ids"], 1)
            self.assertGreater(result["missing_feature_cell_parts"], 0)
            self.assertEqual(
                result["feature_id_comparison"]["missing_osm_feature_ids"][0]["osm_id"],
                target_key[0],
            )

    def test_exact_duplicate_and_overlapping_fragments_are_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            tile = json.loads(entries["cells/0_0.json"])
            road = tile["layers"]["roads"][0]
            tile["layers"]["roads"].append(dict(road))
            tile["layers"]["roads"].append({
                **road,
                "geometry": mapping(LineString([(155, 100), (190, 100)])),
            })
            entries["cells/0_0.json"] = json.dumps(tile).encode()
            with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                for name, payload in entries.items():
                    archive.writestr(name, payload)
            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertGreater(result["duplicate_parts"], 0)
            self.assertGreater(result["overlapping_parts"], 0)


    def test_waterway_bridge_and_railway_actual_line_seams_are_checked(self):
        for layer in ("waterways", "bridges", "railway"):
            with self.subTest(layer=layer), tempfile.TemporaryDirectory() as temp:
                source, pack = _make_fixture(Path(temp))
                with zipfile.ZipFile(pack, "r") as archive:
                    entries = {name: archive.read(name) for name in archive.namelist()}
                tile = json.loads(entries["cells/1_0.json"])
                feature = tile["layers"][layer][0]
                geometry = shape(feature["geometry"])
                self.assertIn(geometry.geom_type, ("LineString", "MultiLineString"))
                if geometry.geom_type == "LineString":
                    coordinates = list(geometry.coords)
                    edge_index = min(
                        range(len(coordinates)),
                        key=lambda index: abs(coordinates[index][0] - 200.0),
                    )
                    coordinates[edge_index] = (
                        coordinates[edge_index][0] + 5.0,
                        coordinates[edge_index][1],
                    )
                    feature["geometry"] = mapping(LineString(coordinates))
                else:
                    parts = []
                    for line in geometry.geoms:
                        coordinates = list(line.coords)
                        edge_index = min(
                            range(len(coordinates)),
                            key=lambda index: abs(coordinates[index][0] - 200.0),
                        )
                        coordinates[edge_index] = (
                            coordinates[edge_index][0] + 5.0,
                            coordinates[edge_index][1],
                        )
                        parts.append(LineString(coordinates))
                    feature["geometry"] = mapping(MultiLineString(parts))
                entries["cells/1_0.json"] = json.dumps(tile).encode()
                with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                    for name, payload in entries.items():
                        archive.writestr(name, payload)

                result = audit.audit_pack(source, pack)
                self.assertEqual(result["status"], "failed", result["errors"])
                self.assertGreater(result["disconnected_seams"], 0)
                self.assertTrue(
                    any("Actual geometry seam mismatch" in error for error in result["errors"])
                )

    def test_missing_waterway_bridge_and_railway_neighbor_fragments_are_detected(self):
        for layer in ("waterways", "bridges", "railway"):
            with self.subTest(layer=layer), tempfile.TemporaryDirectory() as temp:
                source, pack = _make_fixture(Path(temp))
                with zipfile.ZipFile(pack, "r") as archive:
                    entries = {name: archive.read(name) for name in archive.namelist()}
                tile = json.loads(entries["cells/1_0.json"])
                self.assertTrue(tile["layers"][layer])
                tile["layers"][layer] = []
                entries["cells/1_0.json"] = json.dumps(tile).encode()
                with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                    for name, payload in entries.items():
                        archive.writestr(name, payload)

                result = audit.audit_pack(source, pack)
                self.assertEqual(result["status"], "failed", result["errors"])
                self.assertGreater(result["actual_cell_seam_checks"]["missing_neighbor_fragments"], 0)
                self.assertGreater(result["disconnected_seams"], 0)

    def test_actual_building_polygon_boundary_mismatch_is_reported(self):
        with tempfile.TemporaryDirectory() as temp:
            source, pack = _make_fixture(Path(temp))
            with zipfile.ZipFile(pack, "r") as archive:
                entries = {name: archive.read(name) for name in archive.namelist()}
            tile = json.loads(entries["cells/1_0.json"])
            building = tile["layers"]["buildings"][0]
            polygon = shape(building["geometry"])
            self.assertEqual(polygon.geom_type, "Polygon")
            exterior = list(polygon.exterior.coords)
            edge_index = min(
                range(len(exterior)),
                key=lambda index: abs(exterior[index][0] - 200.0),
            )
            exterior[edge_index] = (
                exterior[edge_index][0] + 5.0,
                exterior[edge_index][1],
            )
            building["geometry"] = mapping(Polygon(exterior))
            entries["cells/1_0.json"] = json.dumps(tile).encode()
            with zipfile.ZipFile(pack, "w", zipfile.ZIP_DEFLATED) as archive:
                for name, payload in entries.items():
                    archive.writestr(name, payload)

            result = audit.audit_pack(source, pack)
            self.assertEqual(result["status"], "failed")
            self.assertGreater(result["mismatched_feature_cell_parts"], 0)
            self.assertGreater(result["disconnected_seams"], 0)


if __name__ == "__main__":
    unittest.main()
