#!/usr/bin/env python3
"""Deterministic, mobile-conscious SYSTEM WORLD environment tile generator.

Run with Blender 4.x:
  blender --background --python generate_system_world_environment.py -- \
    --world modern --seed 20261117 --segments 48 --output ../../generated/environment_tiles

The script intentionally generates original low-poly blockout assets. They are
production starting points, not finished AAA art. No external assets are used.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path


WORLD_PRESETS = {
    "modern": {
        "ground": (0.19, 0.25, 0.28, 1.0),
        "accent": (0.12, 0.42, 0.52, 1.0),
        "vegetation": (0.12, 0.29, 0.19, 1.0),
        "landmark": "city",
    },
    "historical": {
        "ground": (0.43, 0.32, 0.19, 1.0),
        "accent": (0.67, 0.48, 0.25, 1.0),
        "vegetation": (0.22, 0.31, 0.16, 1.0),
        "landmark": "temple",
    },
    "fantasy": {
        "ground": (0.19, 0.25, 0.22, 1.0),
        "accent": (0.31, 0.20, 0.48, 1.0),
        "vegetation": (0.10, 0.34, 0.21, 1.0),
        "landmark": "spire",
    },
    "greed_island": {
        "ground": (0.17, 0.30, 0.27, 1.0),
        "accent": (0.12, 0.46, 0.39, 1.0),
        "vegetation": (0.08, 0.31, 0.19, 1.0),
        "landmark": "monolith",
    },
}


def height_at(x: float, y: float, seed: int, world: str) -> float:
    """Pure deterministic height function, also usable by --self-test."""
    phase = (seed % 997) * 0.013
    broad = math.sin(x * 0.075 + phase) * math.cos(y * 0.061 - phase)
    detail = math.sin(x * 0.19 + y * 0.11 + phase * 2.0) * 0.22
    ridge = math.cos((x + y) * 0.045 - phase) * 0.28
    island = 1.0
    if world == "greed_island":
        radius = math.sqrt(x * x + y * y)
        island = max(0.0, min(1.0, (30.0 - radius) / 7.0))
        island = island * island * (3.0 - 2.0 * island)
    historical_bias = 0.15 if world == "historical" else 0.0
    return (broad * 2.0 + detail + ridge + historical_bias) * island


def run_self_test() -> None:
    for world in WORLD_PRESETS:
        a = height_at(3.25, -7.5, 12345, world)
        b = height_at(3.25, -7.5, 12345, world)
        assert a == b, "height function must be deterministic"
        assert math.isfinite(a), "height function returned a non-finite value"
    assert set(WORLD_PRESETS) == {"modern", "historical", "fantasy", "greed_island"}
    print("SELF-TEST PASS: four world presets and deterministic terrain sampling")


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", choices=tuple(WORLD_PRESETS), default="modern")
    parser.add_argument("--seed", type=int, default=20261117)
    parser.add_argument("--size", type=float, default=64.0)
    parser.add_argument("--segments", type=int, default=48)
    parser.add_argument("--output", type=Path, default=Path("generated/environment_tiles"))
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args(argv)


def make_material(bpy, name: str, color: tuple, roughness: float = 0.92):
    material = bpy.data.materials.new(name=name)
    material.diffuse_color = color
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    if shader:
        shader.inputs["Base Color"].default_value = color
        shader.inputs["Roughness"].default_value = roughness
    return material


def add_box(bpy, name: str, location, dimensions, material):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    return obj


def add_landmark(bpy, kind: str, accent, ground, size: float):
    cx, cy = size * 0.23, size * 0.16
    if kind == "city":
        for index, (dx, dy, height) in enumerate(
            [(-3.0, 0.0, 5.0), (2.5, 1.5, 8.0), (6.0, -2.0, 4.0)]
        ):
            add_box(
                bpy, f"Landmark_Building_{index + 1}",
                (cx + dx, cy + dy, height / 2.0),
                (3.0, 3.0, height), accent
            )
    elif kind == "temple":
        add_box(bpy, "Landmark_Temple_Base", (cx, cy, 0.8), (12, 9, 1.6), ground)
        for index in range(6):
            x = cx - 4.5 + index * 1.8
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=8, radius=0.42, depth=5.0,
                location=(x, cy - 2.5, 3.3)
            )
            bpy.context.object.name = f"Temple_Column_{index + 1:02d}"
            bpy.context.object.data.materials.append(accent)
        add_box(bpy, "Temple_Upper_Beam", (cx, cy - 2.5, 6.0), (12, 1.2, 1.0), accent)
    elif kind == "spire":
        bpy.ops.mesh.primitive_cone_add(
            vertices=7, radius1=3.0, radius2=0.15, depth=14.0,
            location=(cx, cy, 7.0)
        )
        bpy.context.object.name = "Fantasy_Landmark_Spire"
        bpy.context.object.data.materials.append(accent)
        add_box(bpy, "Spire_Podium", (cx, cy, 0.5), (8, 8, 1.0), ground)
    else:
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=1, radius=4.5, location=(cx, cy, 4.5)
        )
        bpy.context.object.name = "Greed_Island_Ancient_Monolith"
        bpy.context.object.scale = (0.75, 0.75, 1.8)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        bpy.context.object.data.materials.append(accent)


def build_scene(args: argparse.Namespace) -> dict:
    try:
        import bpy
    except ImportError as exc:
        raise RuntimeError(
            "Blender Python API (bpy) is unavailable. Run this file with Blender, "
            "not the system Python interpreter."
        ) from exc

    if not 16 <= args.segments <= 128:
        raise ValueError("--segments must be between 16 and 128 for controlled mesh size")
    if args.size <= 0:
        raise ValueError("--size must be greater than zero")

    random.seed(args.seed)
    preset = WORLD_PRESETS[args.world]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.unit_settings.system = "METRIC"

    ground_mat = make_material(bpy, "SW_Ground", preset["ground"])
    accent_mat = make_material(bpy, "SW_Landmark", preset["accent"])
    foliage_mat = make_material(bpy, "SW_Vegetation", preset["vegetation"])
    road_mat = make_material(bpy, "SW_Road", (0.11, 0.12, 0.13, 1.0))

    half = args.size / 2.0
    vertices = []
    faces = []
    for row in range(args.segments + 1):
        y = -half + args.size * row / args.segments
        for column in range(args.segments + 1):
            x = -half + args.size * column / args.segments
            z = height_at(x, y, args.seed, args.world)
            vertices.append((x, y, z))
    stride = args.segments + 1
    for row in range(args.segments):
        for column in range(args.segments):
            a = row * stride + column
            b, c, d = a + 1, a + stride, a + stride + 1
            faces.extend(((a, c, b), (b, c, d)))

    terrain_mesh = bpy.data.meshes.new("SW_TerrainTile_Mesh")
    terrain_mesh.from_pydata(vertices, [], faces)
    terrain_mesh.materials.append(ground_mat)
    terrain_mesh.update()
    terrain = bpy.data.objects.new("SW_TerrainTile", terrain_mesh)
    scene.collection.objects.link(terrain)
    for polygon in terrain_mesh.polygons:
        polygon.use_smooth = True

    # A narrow, low-poly road ribbon provides a visible map/navigation spine.
    curve = bpy.data.curves.new("SW_Road_Path", type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = 0.85
    curve.bevel_resolution = 1
    spline = curve.splines.new("POLY")
    road_anchors = [
        (-half * 0.82, -half * 0.70),
        (-half * 0.30, -half * 0.20),
        (half * 0.15, half * 0.05),
        (half * 0.75, half * 0.62),
    ]
    road_points = []
    samples_per_segment = 12
    for start, end in zip(road_anchors, road_anchors[1:]):
        for sample in range(samples_per_segment):
            t = sample / samples_per_segment
            x = start[0] + (end[0] - start[0]) * t
            y = start[1] + (end[1] - start[1]) * t
            z = height_at(x, y, args.seed, args.world) + 0.18
            road_points.append((x, y, z, 1.0))
    x, y = road_anchors[-1]
    road_points.append((x, y, height_at(x, y, args.seed, args.world) + 0.18, 1.0))
    spline.points.add(len(road_points) - 1)
    for point, coordinate in zip(spline.points, road_points):
        point.co = coordinate
    road = bpy.data.objects.new("SW_Road", curve)
    scene.collection.objects.link(road)
    curve.materials.append(road_mat)

    # Bounded, deterministic prop scatter. Instancing can replace this in a later pass.
    for index in range(14):
        x = random.uniform(-half * 0.85, half * 0.85)
        y = random.uniform(-half * 0.85, half * 0.85)
        if abs(x - y) < 5.0:
            continue
        z = height_at(x, y, args.seed, args.world)
        if index % 2 == 0:
            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6, radius=0.22, depth=1.8,
                location=(x, y, z + 0.9)
            )
            trunk = bpy.context.object
            trunk.name = f"SW_TreeTrunk_{index:02d}"
            trunk.data.materials.append(road_mat)
            bpy.ops.mesh.primitive_cone_add(
                vertices=7, radius1=1.15, radius2=0.05, depth=2.8,
                location=(x, y, z + 2.7)
            )
            crown = bpy.context.object
            crown.name = f"SW_TreeCrown_{index:02d}"
            crown.data.materials.append(foliage_mat)
        else:
            bpy.ops.mesh.primitive_ico_sphere_add(
                subdivisions=1, radius=random.uniform(0.45, 1.0),
                location=(x, y, z + 0.35)
            )
            rock = bpy.context.object
            rock.name = f"SW_Rock_{index:02d}"
            rock.scale = (1.2, 0.9, 0.7)
            rock.data.materials.append(ground_mat)

    add_landmark(bpy, preset["landmark"], accent_mat, ground_mat, args.size)

    # Neutral lighting is intentionally simple for the Android compatibility path.
    bpy.ops.object.light_add(type="SUN", location=(0, 0, 30))
    sun = bpy.context.object
    sun.name = "SW_KeyLight"
    sun.data.energy = 1.5
    sun.rotation_euler = (math.radians(25), math.radians(-20), math.radians(-25))

    bpy.ops.object.camera_add(location=(args.size * 0.95, -args.size * 1.15, args.size * 0.85))
    camera = bpy.context.object
    camera.name = "SW_ProductionPreviewCamera"
    direction = -camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 42
    scene.camera = camera

    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    stem = f"sw_{args.world}_tile_s{args.seed}"
    blend_path = output / f"{stem}.blend"
    glb_path = output / f"{stem}.glb"

    bpy.ops.object.select_all(action="DESELECT")
    for obj in scene.objects:
        if obj.type in {"MESH", "CURVE"}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = terrain

    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))

    metadata = {
        "asset": stem,
        "world": args.world,
        "seed": args.seed,
        "tile_size_m": args.size,
        "terrain_segments": args.segments,
        "terrain_triangles": args.segments * args.segments * 2,
        "format": "glb",
        "source_file": blend_path.name,
        "runtime_file": glb_path.name,
        "generator": "SYSTEM WORLD Blender Environment Generator",
        "status": "procedural_blockout_requires_visual_review",
    }
    (output / f"{stem}.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8"
    )
    print(json.dumps(metadata, indent=2))
    return metadata


def main() -> int:
    args = parse_args()
    if args.self_test:
        run_self_test()
        return 0
    metadata = build_scene(args)
    print(f"EXPORTED: {metadata['runtime_file']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
