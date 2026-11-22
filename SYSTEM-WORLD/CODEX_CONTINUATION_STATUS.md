# SYSTEM WORLD — Continuation Status

**Last updated:** 2026-11-22  
**Active development branch:** `work/baghdad-system-integration`  
**Latest source/workflow commit before this checkpoint refresh:** `980cb44ce641a77a1dbaae3dbb7f67bd9ac533cc`  
**Canonical runtime:** `SYSTEM-WORLD/` (Godot 4.3)  
**Main branch policy:** do not edit, merge into, rebase onto, or otherwise change `main` without the owner's explicit instruction.

## Branch integrity

- The requested development branch exists and is the active work branch.
- At the latest comparison, `work/baghdad-system-integration` was 532 commits ahead and 3 commits behind `main`, with a diverged history.
- Do not merge or rebase automatically. Preserve the branch's existing work and continue only on this branch.
- No files were deleted in the current work slice.

## Last completed implementation slice

The immediate queue item was evidence-based association of Baghdad's source-mapped entrance nodes with their actual OSM building footprints. The following source changes were committed on the active branch:

1. `tools/geospatial/associate_baghdad_entrances.py`
   - Added atomic ZIP annotation so each entrance feature carries its association status, building OSM ID, measured distance and reason in the exact runtime cell pack.
   - Added manifest association schema version 1.
2. `tools/geospatial/test_associate_baghdad_entrances.py`
   - Added tests for embedding accepted/rejected associations and for preserving the original pack if an entrance lacks an association decision.
3. `scripts/baghdad_osm_cell_streamer.gd`
   - Requires association schema version 1 before creating entrance markers.
   - Exposes only accepted or restricted associations; review/rejected candidates do not become runtime entrance interactions.
   - Links each entrance to the matching building collision body in the same streamed cell and stores source entrance IDs on the building.
   - Keeps restricted entrances non-public and preserves source access/wheelchair metadata.
4. `tools/validate_baghdad_osm_runtime.gd`
   - Adds a runtime validation pass for entrance-bearing cell 0:2, matching entrance markers to building IDs and checking restricted access behavior.
5. `.github/workflows/verify-baghdad-osm-source.yml`
   - Runs association and pack annotation, validates the annotated artifact, uploads the association report and cell pack, and listens to the active integration branch.
6. `MODERN_WORLD_COMPLETION_TRACKER.md` and `ASSET_REGISTER.md`
   - Record implementation status and explicitly keep physical doors/interiors and CI/device verification open.

## Evidence and validation boundary

- Earlier source association analysis on the 5×5 / 200 m sample contained 30 source entrance points: 25 accepted, 3 review and 2 rejected.
- Earlier full municipal analysis contained 188 entrance points and 41,463 building footprints: 148 accepted, 11 review, 3 restricted and 26 rejected.
- These earlier reports predate the new runtime-pack annotation and must not be presented as validation of the newly annotated pack.
- The source workflow now triggers on `work/baghdad-system-integration`, watches the association tool/tests and runtime validator paths, and publishes the annotated pack/report. Its artifact should trigger the canonical Android workflow through the existing `workflow_run` handoff.
- The new Python annotation tests and Godot entrance-runtime assertions still require confirmed GitHub Actions results on the updated branch head.
- No local Godot executable is available in the current working environment; do not claim a local Godot run or Android device test.
- The 5×5 cell pack covers only a 1 km × 1 km proof area, not all Baghdad.

## Explicitly not complete

- No physical door frame/leaf or wall opening has been built for these OSM entrances.
- No open/close door animation, permission-enforced entry transition, interior scene, multi-floor apartment/shop, or full building enterability is established by this slice.
- Baghdad's 5×5 OSM runtime sample is not the full municipal map.
- Physical Android visual/performance inspection has not been performed.

## Exact next actions

1. Inspect the GitHub Actions run created by the latest push to `work/baghdad-system-integration`.
2. Confirm the source workflow's geospatial unit tests, association report, annotated pack validation and uploaded artifact.
3. Confirm the canonical Android workflow downloaded that exact artifact and passed Godot 4.3 import, Baghdad entrance runtime validation, headless main-scene startup and APK export. Fix actual failures on this branch only.
4. After CI passes, build the next safe gameplay slice: verified entrance geometry and doorway placement with wall openings, collision clearance, access restrictions, and a real enter/exit path. Do not fabricate entrances for buildings without accepted source/manual evidence.
5. Continue the Baghdad landmark/tower, stadium, hunter examination, Power Tower, arena and motorsport work from the existing implementation and validators; inspect before modifying and do not repeat completed work.
6. Update this checkpoint and the relevant tracker after each coherent verified stage.

**Resume instruction:** continue from this file and the latest commit on `work/baghdad-system-integration`. Do not restart the project, do not ask the owner to repeat the vision, and do not modify `main`.
