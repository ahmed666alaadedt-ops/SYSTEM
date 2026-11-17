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
- `TEST_RESULTS.md`: dated record separating actual checks from checks blocked
  by missing Blender/Godot executables.

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

## Execution status (2026-11-17)

Blender and Godot are not installed/discoverable in the current execution
environment. The Blender generator has therefore **not** been executed here,
and no Blender-exported GLB or `.blend` file is claimed.

A separate fallback GLB smoke test was run with Trimesh 4.11.1: a seven-mesh
fixture was exported (7,804 bytes), reopened successfully, and its GLB 2.0
container, JSON chunk and binary chunk were inspected. This only proves that a
GLB can be written and reopened by the fallback library in this environment;
it does not test Blender's `bpy` generator or exporter. Full observed results
and blockers are in `TEST_RESULTS.md`.

The Blender generator is authored for Blender 4.x. When Blender is available,
run the exact Quick start commands above, then run the repository validator
against the generated file. Godot import, visual review and Android profiling
remain separate acceptance checks.
