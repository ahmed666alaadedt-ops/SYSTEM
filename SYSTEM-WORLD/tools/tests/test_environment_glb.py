"""Regression tests for the pure-Python SYSTEM WORLD GLB generator."""
import json
import math
import struct
import tempfile
import unittest
from pathlib import Path

from generate_environment_glb import PRESETS, build, height_at


class EnvironmentGeneratorTests(unittest.TestCase):
    def test_all_four_presets_generate_valid_glb_containers(self):
        with tempfile.TemporaryDirectory() as folder:
            for world in PRESETS:
                metadata = build(world, 20261117, 16, 64.0, Path(folder))
                data = (Path(folder) / metadata["runtime_file"]).read_bytes()
                magic, version, length = struct.unpack_from("<4sII", data)
                self.assertEqual((magic, version, length), (b"glTF", 2, len(data)))
                json_length, json_type = struct.unpack_from("<II", data, 12)
                self.assertEqual(json_type, 0x4E4F534A)
                document = json.loads(data[20:20 + json_length].decode("utf-8"))
                self.assertEqual(document["asset"]["version"], "2.0")
                self.assertEqual(len(document["meshes"]), 4)
                self.assertEqual(len(document["materials"]), 4)
                self.assertEqual(metadata["world"], world)

    def test_seed_repeats_geometry(self):
        with tempfile.TemporaryDirectory() as folder:
            first = build("modern", 99, 16, 64.0, Path(folder))
            original = (Path(folder) / first["runtime_file"]).read_bytes()
            second = build("modern", 99, 16, 64.0, Path(folder))
            self.assertEqual(original, (Path(folder) / second["runtime_file"]).read_bytes())

    def test_different_seeds_change_terrain(self):
        self.assertNotEqual(height_at(8.0,-4.0,11,"modern"), height_at(8.0,-4.0,12,"modern"))

    def test_greed_island_has_falloff(self):
        self.assertTrue(math.isfinite(height_at(0.0,0.0,123,"greed_island")))
        self.assertEqual(height_at(40.0,0.0,123,"greed_island"), 0.0)

    def test_segment_limits_are_enforced(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                build("modern",1,8,64.0,Path(folder))


if __name__ == "__main__":
    unittest.main()
