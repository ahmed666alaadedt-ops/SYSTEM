# SYSTEM WORLD — 3D Production Tools

This folder contains an additive, isolated first pass of the 3D asset pipeline.
It does not replace either Godot project and it does not modify runtime scenes.

## Current tools

- `blender/generate_system_world_environment.py`: deterministic Blender 4.x
  generator for a small terrain tile, a navigation road, low-poly vegetation /
  rocks and one world-specific landmark. Presets: modern, historical, fantasy,
  greed_island. Exports a source `.blend`, runtime `.glb`, and metadata `.json`.
- `validate_glb.py`: standard-library GLB 2.0 structural validator. Checks
  container/chunk integrity, embedded buffers, buffer view/accessor bounds,
  mesh primitives, triangle counts and external texture/buffer references.

## Quick start

Run the pure-Python checks without Blender:

```bash
python3 SYSTEM-WORLD/tools/validate_glb.py --self-test
blender --background --python SYSTEM-WORLD/tools/blender/generate_system_world_environment.py -- \
  --world modern --seed 20261117 --segments 48 \
  --output SYSTEM-WORLD/generated/environment_tiles
python3 SYSTEM-WORLD/tools/validate_glb.py \
  SYSTEM-WORLD/generated/environment_tiles/sw_modern_tile_s20261117.glb
```

Use `--world historical`, `fantasy`, or `greed_island` for the other
independent world identities. Keep the seed in the asset metadata so a tile can
be regenerated. The generator enforces 16–128 terrain segments; 48 segments
produce 4,608 terrain triangles before props and the landmark.

## Godot import and Android rules

1. Copy or export the generated GLB into the canonical runtime project under
   `SYSTEM-WORLD/generated/environment_tiles/`.
2. Open `SYSTEM-WORLD/project.godot` with the project's verified Godot 4.x
   editor and let the importer finish.
3. Inspect the imported material, scale, orientation, mesh count and collision.
   Add collision/navigation only where gameplay needs it; do not create expensive
   collision for decorative foliage.
4. Test the tile in a dedicated test scene before connecting it to world streaming.
5. Keep the Compatibility renderer. Use smaller texture sizes, few materials,
   simple collision, region streaming and LOD before expanding the tile.
6. Run a real Android export and device test before calling the asset mobile-ready.

The Blender generator was authored for Blender 4.x, but Blender is not installed
in the current execution environment. Its Blender export has therefore not yet
been executed here. The GLB validator self-test is independent of Blender and
can run with Python 3.10+.
