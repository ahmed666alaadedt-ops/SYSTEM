"""Unit tests for Baghdad OSM entrance association decisions."""
import json
import pathlib
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from shapely.geometry import Point, Polygon, mapping

from associate_baghdad_entrances import annotate_pack, associate_features


def building(feature_id, polygon, tags=None):
    return {"id": feature_id, "geometry": mapping(polygon), "tags": tags or {"building": "yes"}}


def entrance(feature_id, point, tags=None):
    return {"id": feature_id, "geometry": mapping(point), "tags": tags or {"entrance": "main"}}


class EntranceAssociationTests(unittest.TestCase):
    def test_point_on_footprint_is_accepted(self):
        buildings = [building("way/10", Polygon([(0, 0), (10, 0), (10, 10), (0, 10)]))]
        report = associate_features(buildings, [entrance("node/1", Point(5, 5))])
        match = report["associations"][0]
        self.assertEqual(match["status"], "accepted")
        self.assertEqual(match["building_id"], "way/10")
        self.assertEqual(match["distance_m"], 0.0)

    def test_similarly_close_buildings_require_review(self):
        buildings = [
            building("way/10", Polygon([(0, 0), (4, 0), (4, 4), (0, 4)])),
            building("way/11", Polygon([(6, 0), (10, 0), (10, 4), (6, 4)])),
        ]
        report = associate_features(buildings, [entrance("node/2", Point(5, 2))])
        self.assertEqual(report["associations"][0]["status"], "review")
        self.assertEqual(report["summary"]["review_count"], 1)

    def test_private_access_is_not_marked_public(self):
        buildings = [building("way/12", Polygon([(0, 0), (8, 0), (8, 8), (0, 8)]))]
        report = associate_features(
            buildings,
            [entrance("node/3", Point(4, 4), {"entrance": "main", "access": "private"})],
        )
        self.assertEqual(report["associations"][0]["status"], "restricted")
        self.assertEqual(report["summary"]["restricted_count"], 1)

    def test_no_nearby_building_is_rejected(self):
        buildings = [building("way/13", Polygon([(0, 0), (2, 0), (2, 2), (0, 2)]))]
        report = associate_features(buildings, [entrance("node/4", Point(50, 50))])
        self.assertEqual(report["associations"][0]["status"], "rejected")
        self.assertEqual(report["summary"]["rejected_count"], 1)



    def test_annotation_embeds_only_the_reviewed_building_link(self):
        buildings = [building("way/20", Polygon([(0, 0), (10, 0), (10, 10), (0, 10)]))]
        entrances = [
            entrance("node/20", Point(5, 5)),
            entrance("node/21", Point(50, 50)),
        ]
        report = associate_features(buildings, entrances)
        with tempfile.TemporaryDirectory() as directory:
            pack_path = pathlib.Path(directory) / "baghdad-pack.zip"
            with zipfile.ZipFile(pack_path, "w") as archive:
                archive.writestr("manifest.json", json.dumps({
                    "schema_version": 1,
                    "region_id": "iraq_baghdad_region",
                    "coordinate_system": "SYSTEM_LOCAL_ECEF_TANGENT",
                }))
                archive.writestr("cells/0_0.json", json.dumps({
                    "schema_version": 1,
                    "region_id": "iraq_baghdad_region",
                    "layers": {"entrances": [
                        {"id": "node/20", "geometry": mapping(Point(5, 5)), "tags": {"entrance": "main"}},
                        {"id": "node/21", "geometry": mapping(Point(50, 50)), "tags": {"entrance": "main"}},
                    ]},
                }))
            annotate_pack(pack_path, report["associations"])
            with zipfile.ZipFile(pack_path) as archive:
                manifest = json.loads(archive.read("manifest.json"))
                tile = json.loads(archive.read("cells/0_0.json"))
            self.assertEqual(manifest["entrance_association_schema_version"], 1)
            entries = {item["id"]: item["association"] for item in tile["layers"]["entrances"]}
            self.assertEqual(entries["node/20"]["status"], "accepted")
            self.assertEqual(entries["node/20"]["building_id"], "way/20")
            self.assertEqual(entries["node/21"]["status"], "rejected")
            self.assertEqual(entries["node/21"]["building_id"], "")

    def test_annotation_rejects_an_unmatched_source_entrance(self):
        with tempfile.TemporaryDirectory() as directory:
            pack_path = pathlib.Path(directory) / "baghdad-pack.zip"
            with zipfile.ZipFile(pack_path, "w") as archive:
                archive.writestr("manifest.json", json.dumps({"schema_version": 1}))
                archive.writestr("cells/0_0.json", json.dumps({
                    "layers": {"entrances": [{"id": "node/missing"}]},
                }))
            with self.assertRaisesRegex(ValueError, "no association decision"):
                annotate_pack(pack_path, [])
            with zipfile.ZipFile(pack_path) as archive:
                self.assertNotIn("entrance_association_schema_version",
                                 json.loads(archive.read("manifest.json")))


if __name__ == "__main__":
    unittest.main()
