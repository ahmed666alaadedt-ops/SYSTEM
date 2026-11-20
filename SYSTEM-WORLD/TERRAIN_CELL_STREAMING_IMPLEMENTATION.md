# SYSTEM WORLD — Terrain Cell Streaming Implementation

**Updated:** 2026-11-20  
**Status:** The cell streamer is instantiated by the canonical modern-continent manager and replaces its active monolithic terrain visual/collision path. Headless tests cover adjacent seams, player-cell priority, collision toggling, unload, clipping endpoints and canonical wiring. CI execution still needs confirmation.

## Active integration

`scripts/modern_continent_manager.gd` now calls `_setup_terrain_streaming()` instead of `_build_continent()` from `_ready()`. The new streamer samples the same deterministic `_get_height(x, z)` function, while the public `get_terrain_height()` API falls back to that sampler when the old baked grid is empty. Existing forests, cities and world systems can continue querying terrain heights.

## Cell streamer

`scripts/modern_world_cell_streaming_manager.gd` — `ModernWorldCellStreamingManager`

- Integer cell IDs from world-space X/Z using a stable regional origin.
- Current prototype settings: 200 m cells, 20 m sample spacing, load radius 2, collision radius 1.
- Adjacent cells sample identical world-space coordinates along shared edges.
- Player-centered desired-cell set, queued loading/unloading and one cell operation per frame.
- Player's current cell is prioritized before background operations.
- Separate visual mesh and HeightMapShape3D collision per cell.
- Collision shapes are enabled inside the near-cell radius and toggled as the player moves; samples are retained while the visual cell remains loaded.
- Terrain vertex colors and generated mesh normals are preserved.

## Road and water boundary utility

`scripts/system_world_cell_geometry_clipper.gd` adds deterministic Liang–Barsky clipping for X/Z polylines against a cell rectangle. The headless test checks that two adjacent cells calculate the same shared endpoint for a line crossing their common edge.

This is a geometry primitive only: current city road, river, coast, bridge and navigation meshes have **not** yet been migrated to cell-owned clipped segments.

## Headless validation

`tools/validate_terrain_cell_streaming.gd` is wired into `.github/workflows/canonical-godot-validation.yml`. It checks:
- Stable cell coordinate mapping and the configured 3×3 desired set.
- Player's current cell loads first.
- Adjacent terrain cells produce matching edge heights.
- Near/far collision toggling and reactivation.
- Cell unloading.
- Canonical continent instantiates the streamer and does not instantiate the old monolithic terrain visual/collision.
- Adjacent cells produce the same clipped polyline boundary point.

**CI status:** [Canonical Godot validation run 44707771587](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/44707771587) completed successfully for commit `5292a22e4330a3e11574d91e80c6b81d3a875384`. Godot import/parse, terrain streaming seam/lifecycle/partial-edge tests, existing safety/geography/gate tests and headless main-scene launch all passed.

**Canonical Android APK with Baghdad OSM cells:** [Build run 44710045959](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/44710045959) completed successfully. It downloaded/unpacked the OSM pack, passed the Baghdad OSM runtime geometry test, headless main-scene launch, companion and NPC checks, then exported and uploaded artifact `SYSTEM-WORLD-canonical-android-debug-apk` (ID `14616337943`, 35.6 MB). This confirms export and automated headless checks, not on-device performance or visual acceptance.

## Important scope limitation

**This is not yet the real-scale Baghdad map.** The current connected continent remains a 3 km × 2.2 km fictional prototype. Baghdad's municipal OSM GeoJSON pack is not imported into the runtime. The candidate municipal boundary is approximately 861 km² and still requires official boundary validation and a metric projection pipeline. The 200 m cells currently stream the existing prototype terrain only; they do not prove full-scale Baghdad coverage.

## Remaining implementation sequence

1. [x] Replace the active monolithic terrain visual/collision path with player-centered independent cells while preserving the terrain sampling API.
2. [x] Add headless seam, priority, partial-edge-cell, collision-toggle, unload, clipping and canonical-wiring checks; canonical Godot validation run 44707771587 passed.
3. [ ] Expand tests for partial world bounds, rapid cell-boundary movement, queue churn and memory/collision budgets.
4. [ ] Migrate roads, rivers, waterways, coastlines and bridges to cell-owned clipped segments with stable source feature IDs and shared boundary points.
5. [ ] Add stitched LOD transitions (or validated skirts) before enabling lower-resolution geometry. Current LOD is metadata only.
6. [ ] Add region-scoped navigation data and mobile collision budgets.
7. [ ] Import and validate a small real Baghdad test area from the versioned licensed GeoJSON pack using a metric projection. Check roads, Tigris waterways, bridges and building footprint coverage.
8. [ ] Only after those checks pass, bind building footprints to cells and begin detailed building asset production.

## Mobile baseline

The 200 m cell / 20 m sample settings are a prototype baseline, not a final performance claim. No physical Android memory, frame-time, heat or battery test has been run. Measure on the target phone before increasing cell radii, collision density or terrain sample resolution.
