# SYSTEM WORLD — Continuation Status

**Last updated:** 2026-11-22  
**Active development branch:** `work/baghdad-system-integration`  
**Latest verified gameplay/code commit:** `83db22c01e7ecf1addd01ce01cbb1b341bd1fdc8`  
**Latest tracker documentation commit:** `1c65159f6b8831c12897565ed716166dd104a6d0`  
**Main branch SHA:** `dff4e9d377ffaae6845e6f401c47346e51ea5619`  
**Canonical runtime:** `SYSTEM-WORLD/` (Godot 4.3)

## Branch integrity

- `work/baghdad-system-integration` is the active work branch.
- Latest comparison after the tracker update: branch is **551 commits ahead and 3 commits behind** `main`; history remains diverged.
- Do not merge, rebase, or synchronize automatically. The owner has not authorized any main-branch integration.
- No files were deleted in this work slice.
- No changes were made to `main`.

## Completed Baghdad OSM source association

1. `tools/geospatial/associate_baghdad_entrances.py`
   - Associates source entrance nodes with building footprints using the metric local coordinate system.
   - Reassembles clipped building fragments before spatial matching.
   - Writes association metadata into the exact runtime ZIP, including status, OSM building ID, distance, reason, and manifest schema version 1.
   - Sets `runtime_pack_annotated` only after the ZIP annotation succeeds.
2. `tools/geospatial/test_associate_baghdad_entrances.py`
   - Covers accepted, ambiguous/review, restricted, rejected, successful ZIP annotation, and atomic failure behavior.
3. Source workflow `44982341557`
   - Passed the OSM boundary/cell-pack build, entrance association, and real-cell connectivity audit.
   - Ran **30 Python unit tests successfully**.
   - Sample 5×5 / 200 m cell pack: 30 source entrances; 25 accepted, 3 review, 2 rejected.
   - Source artifacts: diagnostics `14738480893`; boundary candidate `14737529276`.

## Completed physical doors and building interiors

Code validated on commit `83db22c01e7ecf1addd01ce01cbb1b341bd1fdc8`:

1. `scripts/baghdad_osm_cell_streamer.gd`
   - Exposes only accepted/restricted entrance associations; review/rejected points do not become public doors.
   - Projects accepted source entrances onto suitable building wall edges and creates an actual wall opening only where placement clearance is available.
   - Splits wall and roof meshes so the roof can be hidden while a player is inside.
   - Builds frame posts, lintel, hinged leaf, moving collision body, interaction area, and stable links to the source entrance/building IDs.
   - Creates category-based procedural interiors with a floor, collision, warm light, and furnishing layouts for detached houses, apartments, shops/commercial buildings, schools, healthcare buildings, hotels, mosques, churches, and general buildings.
2. `scripts/baghdad_osm_door_interaction.gd`
   - First interaction opens the door; the next enters the building.
   - Entry activates interior collision and hides the roof.
   - Interaction from inside exits, disables interior collision, restores the roof, and closes the door.
   - Restricted doors remain closed and deny public access.
3. `tools/validate_baghdad_osm_runtime.gd`
   - Validates the source association, linked building, wall-opening evidence, physical leaf collision, and interaction area.
   - Tests door open, enter, exit, roof restoration, and collision activation/deactivation.
   - Includes a synthetic restricted-door denial test because the current sample cell has no restricted source door.

## Verified run evidence

- Canonical Android workflow **44982486123** passed on exact checkout commit `83db22c`.
- It passed Godot 4.3 import, Baghdad OSM runtime validation, main-scene headless launch, character companion checks, NPC society checks, and Android APK export.
- Runtime marker from `baghdad-osm-runtime.log`:
  - source points in cell 0:2: **21**
  - linked runtime markers: **19**
  - accepted associations: **19**
  - physical doors: **19**
  - successful interior entry/exit transitions: **19**
  - synthetic restricted-door denial: passed
- APK artifact: `14738163484`.
- Validation log artifact: `14738088974`.
- Canonical run: https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/44982486123

## Evidence boundaries / not complete

- The 5×5 metric cell pack is a 1 km × 1 km proof sample, not all Baghdad.
- The 19 physical doors and transitions refer to entrance-bearing cell 0:2, not the whole municipal region.
- The current sample had no restricted source door; restriction denial was validated with a synthetic runtime case and the Python association tests.
- The current interiors are starter shells, not complete architectural interiors, multi-room layouts, multi-floor apartment simulations, or fully functional shops.
- Player-camera ray-target selection and map discovery for the new physical door roots still need an explicit live-player integration test.
- Cell boundary/unload/reload while a player is inside a building still needs validation.
- No physical Android device visual/performance test has been performed.
- The headless dummy renderer emits repeated `mesh_get_surface_count` null-mesh messages during teardown after the Baghdad success marker; the canonical workflow still exits successfully. Investigate if this appears in normal rendered gameplay; do not mistake it for a failed entrance/interior assertion.

## Exact next actions

1. Continue on `work/baghdad-system-integration` only.
2. Add and validate player-camera ray selection and map-discovery registration for the physical door interaction root.
3. Validate streaming retention and state restoration when the player enters an interior near a cell boundary, then exits and the cell unloads/reloads.
4. Expand category interiors into multi-room/multi-floor layouts and connect shop counters/inventories to the existing business/economy systems.
5. Continue the remaining Baghdad queue from `MODERN_WORLD_COMPLETION_TRACKER.md`; inspect existing code and validators before changing anything.
6. Update this checkpoint after the next coherent verified stage.
7. Never merge into, rebase onto, or modify `main` without explicit owner approval.

**Resume instruction:** continue from this file and the latest commit on `work/baghdad-system-integration`. Do not restart the project, do not repeat completed work, and do not ask the owner to repeat the project vision.
