# SYSTEM WORLD Project Catalog

**Last inspected:** 2026-11-20  
**Repository:** https://github.com/ahmed666alaadedt-ops/SYSTEM  
**Branch:** `main`  
**Initial audit baseline:** `9f75f6bf3aecf096c9658320149a3816d18b631f`  
**Latest stabilization commit at update:** `84569f1be3a6c910f28d4d1114d7449aaaf034a7`

This is the central index for the existing SYSTEM application and SYSTEM WORLD projects. It is an inventory, not a claim that the game is complete.

## Project boundaries

| Project | Role | Current repository inventory |
|---|---|---|
| `SYSTEM-WORLD/` | Canonical Godot runtime | 130 files, 92 GDScript files, 1 saved scene, 6 character GLBs |
| `SYSTEM-WORLD-3D/` | Separate 3D prototype/reference | 86 files, 54 GDScript files, 9 saved scenes, 6 character GLBs |
| `app/` | Android Compose/Firebase application | 149 files, 135 Kotlin files |

Both Godot projects must remain separate. The Android application remains the owner of authentication, account/profile data and Firebase-backed app services until a verified Godot host integration exists.

## Authoritative references

- `AGENTS.md` — mandatory engineering and preservation rules.
- `SYSTEM_MASTER_VISION.md` — overall product vision and four-world structure.
- `SYSTEM_WORLD_MASTER_SPEC.md` — gameplay specification; contains a world-count wording conflict that must be reconciled.
- `SYSTEM-WORLD/PROJECT_TECHNICAL_ROADMAP.md` — Godot/Android technical direction.
- `SYSTEM-WORLD/ASSET_REGISTER.md` — 3D asset/system inventory; some counts need refreshing.
- `SYSTEM-WORLD/PRODUCTION_AUDIT.md` — earlier 2026-11-17 audit.
- `SYSTEM-WORLD/PRODUCTION_AUDIT_2026-11-20.md` — current evidence-based audit.
- `SYSTEM-WORLD/CHARACTER_AND_CITY_3D_STATUS_2026-11-19.md` — character and city visual status.
- `SYSTEM-WORLD/MODERN_WORLD_COMPLETION_TRACKER.md` — modern-world acceptance checklist.
- `SYSTEM-WORLD/REAL_EARTH_GEOGRAPHY_AND_NPC_LIFE.md` — current real-Earth geography decision.

## Current verified repository facts

- Canonical Godot entry: `SYSTEM-WORLD/project.godot` → `res://MainScene.tscn`.
- Separate prototype entry: `SYSTEM-WORLD-3D/project.godot` → `res://scenes/premium_command_center.tscn`.
- The canonical Godot project declares 10 autoloads; the prototype declares 7.
- Both projects have six tracked humanoid GLB models (adult, elder and child; male and female).
- No environment/building GLB, glTF, FBX, OBJ or BLEND production assets were found in the inspected repository tree.
- The modern city/building layer is currently procedural placeholder geometry, not a finished building kit.
- The modern-world real-Earth registry currently contains only a provisional Baghdad geographic anchor.
- Android Compose/Firebase and the Godot game currently build/export separately; native AAR embedding and live transport remain unverified.

## Current CI evidence at inspected commit

The following GitHub Actions runs for commit `9f75f6bf` completed successfully on 2026-11-19:
- Canonical Godot import/parse, child-safety QA and bounded headless main-scene launch.
- Godot project validation, including missing-mesh diagnostics.
- Canonical Godot Android APK export.
- Existing Android application APK build.
- Separate SYSTEM WORLD Android export workflow.

A successful headless launch or APK export does not prove visual quality, full gameplay completeness, real-world geographic accuracy, physical-device performance, or that the Android Compose app embeds the Godot runtime.

## Post-audit stabilization

- The master specification now defines exactly four total worlds and makes Baghdad the only interworld Star Gate hub.
- The canonical project icon points to the tracked SVG asset; the Android export workflow no longer copies preview artwork into the runtime project.
- The Baghdad city anchor is now read from the provisional WGS84 registry; the other thirteen city centers remain prototype coordinates.
- Greed Island's return point is an extraction beacon, not a Star Gate, and the island defaults to closed outside an explicitly opened season.
- Runtime QA scripts now cover the Baghdad geography anchor and Baghdad-only Star Gate placement. Latest CI status must be checked before treating the new gate QA as passed.
- A Geofabrik Iraq OSM snapshot and Baghdad Municipality boundary have been recorded as source candidates only. `SYSTEM-WORLD/data/geography/GEOSPATIAL_IMPORT_PLAN.md` documents licensing, attribution, quality caveats and import gates; no source geometry has been imported.
- `.github/workflows/verify-baghdad-osm-source.yml` downloads the pinned OSM snapshot, verifies its checksum, extracts relation 5638803 with referenced members, and validates the administrative boundary tags. Its first run is pending/in progress; do not claim the relation has been verified until the run finishes.

## Audit rule

Do not begin new city/building production until the current assets, scripts, scene links, geographic source data, world integration, collisions/navigation, visual quality and Android performance requirements have been audited and recorded. Preserve existing files; any cleanup must be reference-aware and separately reviewed.
