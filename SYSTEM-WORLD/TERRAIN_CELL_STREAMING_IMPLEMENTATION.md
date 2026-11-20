# SYSTEM WORLD — Terrain Cell Streaming Implementation

**Updated:** 2026-11-20  
**Canonical project:** `SYSTEM-WORLD/`  
**Status:** independent cell-streaming component is now instantiated by the canonical modern-continent manager, replacing its active monolithic terrain visual/collision path. Headless tests cover seams, load priority, collision, unload and canonical wiring. CI result still requires checking.

## Why this exists

The existing `ModernContinentManager._build_continent()` still creates a single terrain ArrayMesh and one full-world HeightMapShape3D. It must not be enlarged to represent municipal Baghdad. The first implementation step is an independent cell lifecycle component that can be validated before replacing the current terrain path.

## New component

`scripts/modern_world_cell_streaming_manager.gd` — `ModernWorldCellStreamingManager`

Current capabilities:
- Stable integer cell coordinates from world-space X/Z and a fixed regional origin.
- Configurable square cell size and terrain sample spacing; defaults are 200 m cells and 20 m samples.
- A shared world-space sampling contract: adjacent cells request the same coordinate along their common edge, so the sampled edge heights are deterministic and identical.
- Player-centered desired-cell set, queued loading and unloading, and a one-cell-operation-per-frame budget. The player's current cell is prioritized ahead of background loads/unloads.
- Separate visual mesh and per-cell HeightMapShape3D collision nodes.
- Collision only for the configured near-cell radius.
- LOD tier classification (near/mid/far) is exposed as metadata only.

## Important limitations — do not mark as complete

- The new component is not yet instantiated by `WorldManager._create_modern_city()`.
- The existing monolithic terrain visual/collision is still the active canonical terrain path.
- LOD mesh decimation and crack-free edge stitching are not enabled. The current component deliberately keeps a common sampling interval rather than introducing mismatched edge vertices.
- Roads, rivers, coastlines, bridges and navigation are not yet split into cell-owned segments. They still need a deterministic clipping/ownership contract with shared boundary vertices and stable feature IDs.
- **This is not yet the real-scale Baghdad map.** The current continent remains a 3 km × 2.2 km fictional prototype. Baghdad's municipal OSM GeoJSON pack is still not imported into the runtime, and the municipal boundary is approximately 861 km² pending official validation.
- No physical Android memory/frame-time test has been run.

## Required next implementation sequence

1. Add automated headless tests for coordinate-to-cell mapping, edge sample identity, partial world bounds, load/unload queues and collision bounds.
2. Replace the monolithic terrain generation in `ModernContinentManager` with a source-sampling API plus cell manager, while preserving `get_terrain_height()` for existing callers.
3. Add cell-aware clipping for roads, rivers, waterways and bridges. A feature crossing a cell boundary must share the exact same projected boundary point in both cells and retain one stable source ID.
4. Add stitched LOD transitions (or skirts with measured visual limits) before enabling lower-resolution meshes.
5. Add region-scoped navigation data and collision budget/streaming policies.
6. Integrate a small, reviewed Baghdad test area using the versioned licensed GeoJSON pack; compare against the same geographic projection and inspect coverage before scaling to the municipal boundary.
7. Only after those checks pass, bind building footprints to cells and start detailed building asset production.

## Mobile baseline

The initial 200 m cell / 20 m source-grid defaults are a prototype budget, not a final performance claim. Keep the per-frame operation budget small and measure on a physical Android device before increasing radii, collision density or sample resolution.
