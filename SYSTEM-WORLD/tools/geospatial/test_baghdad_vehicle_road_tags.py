import ast
import unittest
from pathlib import Path


BUILDER_PATH = Path(__file__).with_name("build_baghdad_metric_cell_pack.py")


def load_kept_tags():
    tree = ast.parse(BUILDER_PATH.read_text(encoding="utf-8"))
    for node in tree.body:
        if isinstance(node, ast.Assign):
            if any(isinstance(target, ast.Name) and target.id == "KEEP_TAGS" for target in node.targets):
                return set(ast.literal_eval(node.value))
    raise AssertionError("KEEP_TAGS was not found in the Baghdad cell-pack builder")


class BaghdadVehicleRoadTagTests(unittest.TestCase):
    def test_cell_pack_preserves_vehicle_routing_and_level_tags(self):
        required_tags = {
            "highway",
            "oneway",
            "oneway:conditional",
            "access",
            "access:conditional",
            "vehicle",
            "vehicle:conditional",
            "motor_vehicle",
            "motor_vehicle:conditional",
            "motorcar",
            "junction",
            "layer",
            "bridge",
            "tunnel",
            "lanes",
            "maxspeed",
            "surface",
        }
        self.assertTrue(required_tags.issubset(load_kept_tags()))


if __name__ == "__main__":
    unittest.main()
