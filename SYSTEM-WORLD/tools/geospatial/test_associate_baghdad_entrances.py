"""Unit tests for Baghdad OSM entrance association decisions."""
import unittest

from shapely.geometry import Point, Polygon, mapping

from associate_baghdad_entrances import associate_features


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


if __name__ == "__main__":
    unittest.main()
