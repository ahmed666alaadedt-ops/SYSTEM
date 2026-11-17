# SYSTEM WORLD — 3D Production Tools

This folder contains additive tools for producing small, repeatable environment
assets. They do not replace either Godot project or modify runtime scenes.

## Tools

- `generate_environment_glb.py`: pure-Python 3.10+ generator that writes a
  self-contained GLB 2.0 plus JSON metadata. No Blender or third-party package
  is required. It creates a 64 m terrain tile, road ribbon, deterministic
  low-poly vegetation/rocks, and a world-specific landmark.
- `blender/generate_system_world_environment.py`: Blender 4.x variant that
  additionally saves an editable `.blend` source file.
- `validate_glb.py`: standard-library GLB structural validator for GLB
  containers, embedded resources, accessors, mesh primitives and triangle counts.

## Generate the first tile

From the repository root:

```bash
python3 SYSTEM-WORLD/tools/generate_environment_glb.py \
  --world modern --seed 20261117 --segments 32 \
  --output SYSTEM-WORLD/generated/environment_tiles
```

The tool writes:
- `sw_modern_tile_s20261117.glb` — runtime model.
- `sw_modern_tile_s20261117.json` — reproducibility metadata.

Use `--world historical`, `fantasy`, or `greed_island` to select the other
independent world identities. Use `--seed` to reproduce a tile. Segment counts
are restricted to 16–128 to bound mesh size. At 32 segments, the terrain itself
contains 2,048 triangles before road, props and landmark geometry.

## Checks

```bash
cd SYSTEM-WORLD/tools
python3 generate_environment_glb.py --self-test
python3 -m unittest discover -s tests -v
python3 validate_glb.py --self-test
```

The unit tests generate each of the four presets in a temporary directory,
check GLB 2.0 headers and scene structure, verify deterministic output, and
check island falloff and input limits.

## Blender alternative

```bash
blender --background --python SYSTEM-WORLD/tools/blender/generate_system_world_environment.py -- \
  --world modern --seed 20261117 --segments 48 \
  --output SYSTEM-WORLD/generated/environment_tiles
```

This path exports editable `.blend`, runtime `.glb`, and metadata `.json`.
Blender 4.x is required.

## Godot import and Android rules

1. Keep generated output under `SYSTEM-WORLD/generated/environment_tiles/`.
2. Open `SYSTEM-WORLD/project.godot` with the project's verified Godot 4.x
   editor and let the importer finish.
3. Inspect material, scale, orientation, mesh count and collision in a test
   scene before connecting the tile to world streaming.
4. Add collision/navigation only where gameplay needs it; avoid expensive
   collision on decorative foliage.
5. Keep the Compatibility renderer and use region streaming, LOD, culling and
   mobile-friendly material/texture budgets.
6. Do not call the blockout finished artwork or mobile-ready until Godot import,
   visual review and real-device performance checks pass.

The pure-Python generator and structural tests can run without Blender/Godot.
Godot import, Blender source export and Android device tests remain separate
checks requiring those tools.
