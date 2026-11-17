#!/usr/bin/env python3
"""Generate a deterministic, self-contained SYSTEM WORLD environment GLB.

Pure Python 3.10+; no Blender or third-party packages required. The output is
an original low-poly blockout, not finished production artwork.

Example:
  python3 generate_environment_glb.py --world modern --seed 20261117 \
    --segments 32 --output ../generated/environment_tiles
"""
from __future__ import annotations
import argparse
import json
import math
import random
import struct
from pathlib import Path
from typing import Any

PRESETS: dict[str, dict[str, Any]] = {
    "modern": {"ground": (0.20, 0.27, 0.30, 1), "road": (0.10, 0.12, 0.14, 1), "green": (0.13, 0.34, 0.20, 1), "accent": (0.13, 0.48, 0.62, 1), "landmark": "city"},
    "historical": {"ground": (0.46, 0.34, 0.21, 1), "road": (0.26, 0.20, 0.14, 1), "green": (0.25, 0.34, 0.17, 1), "accent": (0.72, 0.53, 0.29, 1), "landmark": "temple"},
    "fantasy": {"ground": (0.20, 0.27, 0.24, 1), "road": (0.13, 0.15, 0.18, 1), "green": (0.10, 0.38, 0.24, 1), "accent": (0.43, 0.25, 0.68, 1), "landmark": "spire"},
    "greed_island": {"ground": (0.16, 0.31, 0.27, 1), "road": (0.12, 0.19, 0.18, 1), "green": (0.08, 0.34, 0.21, 1), "accent": (0.16, 0.62, 0.51, 1), "landmark": "monolith"},
}


def height_at(x: float, y: float, seed: int, world: str) -> float:
    phase = (seed % 997) * 0.013
    broad = math.sin(x * 0.075 + phase) * math.cos(y * 0.061 - phase)
    detail = math.sin(x * 0.19 + y * 0.11 + phase * 2.0) * 0.22
    ridge = math.cos((x + y) * 0.045 - phase) * 0.28
    island = 1.0
    if world == "greed_island":
        radius = math.hypot(x, y)
        t = max(0.0, min(1.0, (30.0 - radius) / 7.0))
        island = t * t * (3.0 - 2.0 * t)
    return (broad * 2.0 + detail + ridge + (0.15 if world == "historical" else 0.0)) * island


class GLBBuilder:
    def __init__(self) -> None:
        self.binary = bytearray()
        self.views: list[dict[str, Any]] = []
        self.accessors: list[dict[str, Any]] = []
        self.meshes: list[dict[str, Any]] = []
        self.nodes: list[dict[str, Any]] = []

    def _append(self, payload: bytes, target: int) -> int:
        while len(self.binary) % 4:
            self.binary.append(0)
        offset = len(self.binary)
        self.binary.extend(payload)
        view = len(self.views)
        self.views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(payload), "target": target})
        return view

    def add_mesh(self, name: str, vertices: list[tuple[float, float, float]], indices: list[int], material: int) -> None:
        if not vertices or not indices:
            return
        flat = [component for vertex in vertices for component in vertex]
        p_view = self._append(struct.pack("<" + "f" * len(flat), *flat), 34962)
        p_min = [min(v[i] for v in vertices) for i in range(3)]
        p_max = [max(v[i] for v in vertices) for i in range(3)]
        p_accessor = len(self.accessors)
        self.accessors.append({"bufferView": p_view, "componentType": 5126, "count": len(vertices), "type": "VEC3", "min": p_min, "max": p_max})
        i_view = self._append(struct.pack("<" + "I" * len(indices), *indices), 34963)
        i_accessor = len(self.accessors)
        self.accessors.append({"bufferView": i_view, "componentType": 5125, "count": len(indices), "type": "SCALAR", "min": [min(indices)], "max": [max(indices)]})
        mesh_index = len(self.meshes)
        self.meshes.append({"name": name, "primitives": [{"attributes": {"POSITION": p_accessor}, "indices": i_accessor, "material": material, "mode": 4}]})
        self.nodes.append({"name": name, "mesh": mesh_index})

    def write(self, path: Path, materials: list[dict[str, Any]]) -> None:
        document = {
            "asset": {"version": "2.0", "generator": "SYSTEM WORLD Pure Python Environment Generator"},
            "scene": 0, "scenes": [{"nodes": list(range(len(self.nodes)))}],
            "nodes": self.nodes, "meshes": self.meshes, "materials": materials,
            "buffers": [{"byteLength": len(self.binary)}],
            "bufferViews": self.views, "accessors": self.accessors,
        }
        json_chunk = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        json_chunk += b" " * ((4 - len(json_chunk) % 4) % 4)
        binary = bytes(self.binary)
        binary += b"\0" * ((4 - len(binary) % 4) % 4)
        total = 12 + 8 + len(json_chunk) + 8 + len(binary)
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("wb") as stream:
            stream.write(struct.pack("<4sII", b"glTF", 2, total))
            stream.write(struct.pack("<II", len(json_chunk), 0x4E4F534A))
            stream.write(json_chunk)
            stream.write(struct.pack("<II", len(binary), 0x004E4942))
            stream.write(binary)


def material(name: str, color: tuple[float, float, float, float]) -> dict[str, Any]:
    return {"name": name, "pbrMetallicRoughness": {"baseColorFactor": list(color), "metallicFactor": 0.0, "roughnessFactor": 0.92}}


def _quad(vertices, indices, a, b, c, d) -> None:
    start = len(vertices)
    vertices.extend((a, b, c, d))
    indices.extend((start, start + 1, start + 2, start, start + 2, start + 3))


def _box(vertices, indices, center, size) -> None:
    x, y, z = center
    sx, sy, sz = (v / 2 for v in size)
    corners = [(x-sx,y-sy,z-sz),(x+sx,y-sy,z-sz),(x+sx,y+sy,z-sz),(x-sx,y+sy,z-sz),(x-sx,y-sy,z+sz),(x+sx,y-sy,z+sz),(x+sx,y+sy,z+sz),(x-sx,y+sy,z+sz)]
    faces = ((0,2,1,0,3,2),(4,5,6,4,6,7),(0,1,5,0,5,4),(1,2,6,1,6,5),(2,3,7,2,7,6),(3,0,4,3,4,7))
    start = len(vertices)
    vertices.extend(corners)
    indices.extend(start + i for face in faces for i in face)


def _cone(vertices, indices, center, radius, height, sides=7) -> None:
    x, y, z = center
    start = len(vertices)
    vertices.append((x, y, z + height))
    for i in range(sides):
        angle = math.tau * i / sides
        vertices.append((x + math.cos(angle) * radius, y + math.sin(angle) * radius, z))
    for i in range(sides):
        indices.extend((start, start + 1 + i, start + 1 + ((i + 1) % sides)))


def build(world: str, seed: int, segments: int, size: float, output: Path) -> dict[str, Any]:
    if world not in PRESETS:
        raise ValueError(f"unknown world preset: {world}")
    if not 16 <= segments <= 128:
        raise ValueError("segments must be between 16 and 128")
    if size <= 0:
        raise ValueError("size must be greater than zero")
    preset = PRESETS[world]
    builder = GLBBuilder()
    half = size / 2
    terrain_v: list[tuple[float, float, float]] = []
    terrain_i: list[int] = []
    for row in range(segments + 1):
        y = -half + size * row / segments
        for col in range(segments + 1):
            x = -half + size * col / segments
            terrain_v.append((x, y, height_at(x, y, seed, world)))
    stride = segments + 1
    for row in range(segments):
        for col in range(segments):
            a = row * stride + col
            terrain_i.extend((a, a + stride, a + 1, a + 1, a + stride, a + stride + 1))
    builder.add_mesh("SW_TerrainTile", terrain_v, terrain_i, 0)

    road_v: list[tuple[float, float, float]] = []
    road_i: list[int] = []
    route = [(-half*.82,-half*.70),(-half*.30,-half*.20),(half*.15,half*.05),(half*.75,half*.62)]
    for x, y in route:
        z = height_at(x, y, seed, world) + 0.12
        _quad(road_v, road_i, (x-.75,y,z),(x+.75,y,z),(x+.75,y+1.5,z),(x-.75,y+1.5,z))
    builder.add_mesh("SW_RoadRibbon", road_v, road_i, 1)

    rng = random.Random(seed)
    prop_v: list[tuple[float, float, float]] = []
    prop_i: list[int] = []
    for index in range(18):
        x = rng.uniform(-half*.84, half*.84)
        y = rng.uniform(-half*.84, half*.84)
        if abs(x-y) < 5:
            continue
        z = height_at(x, y, seed, world)
        if index % 2 == 0:
            _box(prop_v, prop_i, (x,y,z+.8), (.38,.38,1.6))
            _cone(prop_v, prop_i, (x,y,z+1.4), 1.0, 2.4)
        else:
            start = len(prop_v)
            prop_v.extend(((x,y,z+.8),(x-.65,y,z+.2),(x+.65,y,z+.2),(x,y-.55,z+.2),(x,y+.55,z+.2),(x,y,z-.1)))
            prop_i.extend(start+i for tri in ((0,1,3),(0,3,2),(0,2,4),(0,4,1),(5,3,1),(5,2,3),(5,4,2),(5,1,4)) for i in tri)
    builder.add_mesh("SW_VegetationAndRocks", prop_v, prop_i, 2)

    landmark_v: list[tuple[float, float, float]] = []
    landmark_i: list[int] = []
    cx, cy = size*.22, size*.16
    kind = preset["landmark"]
    if kind == "city":
        for dx, dy, height in ((-3,0,5),(2.5,1.5,8),(6,-2,4)):
            _box(landmark_v, landmark_i, (cx+dx,cy+dy,height/2), (3,3,height))
    elif kind == "temple":
        _box(landmark_v, landmark_i, (cx,cy,.8), (12,9,1.6))
        for i in range(6):
            _box(landmark_v, landmark_i, (cx-4.5+i*1.8,cy-2.5,3.3), (.84,.84,5))
        _box(landmark_v, landmark_i, (cx,cy-2.5,6), (12,1.2,1))
    elif kind == "spire":
        _box(landmark_v, landmark_i, (cx,cy,.5), (8,8,1))
        _cone(landmark_v, landmark_i, (cx,cy,1), 3, 13, 9)
    else:
        _box(landmark_v, landmark_i, (cx,cy,4.5), (4,4,9))
    landmark_names = {"city":"SW_ModernCityLandmark","temple":"SW_HistoricalTempleLandmark","spire":"SW_FantasySpireLandmark","monolith":"SW_GreedIslandMonolith"}
    builder.add_mesh(landmark_names[kind], landmark_v, landmark_i, 3)

    stem = f"sw_{world}_tile_s{seed}"
    glb_path = output / f"{stem}.glb"
    mats = [material("SW_Ground",preset["ground"]),material("SW_Road",preset["road"]),material("SW_Vegetation",preset["green"]),material("SW_Landmark",preset["accent"])]
    builder.write(glb_path, mats)
    metadata = {
        "asset": stem, "world": world, "seed": seed, "tile_size_m": size,
        "terrain_segments": segments, "terrain_triangles": segments*segments*2,
        "mesh_count": len(builder.meshes), "primitive_count": len(builder.meshes),
        "format": "glb", "runtime_file": glb_path.name,
        "generator": "SYSTEM WORLD Pure Python Environment Generator",
        "dependencies": ["Python 3.10+ standard library only"],
        "status": "procedural_blockout_requires_godot_import_and_visual_review",
    }
    (output / f"{stem}.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    return metadata


def self_test() -> None:
    for world in PRESETS:
        assert height_at(2.0,-3.0,123,world) == height_at(2.0,-3.0,123,world)
    assert math.isfinite(height_at(0,0,1,"greed_island"))
    assert height_at(40,0,1,"greed_island") == 0.0
    print("SELF-TEST PASS: four presets, deterministic terrain, island falloff")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", choices=tuple(PRESETS), default="modern")
    parser.add_argument("--seed", type=int, default=20261117)
    parser.add_argument("--segments", type=int, default=32)
    parser.add_argument("--size", type=float, default=64.0)
    parser.add_argument("--output", type=Path, default=Path("generated/environment_tiles"))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    print(json.dumps(build(args.world,args.seed,args.segments,args.size,args.output),indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
