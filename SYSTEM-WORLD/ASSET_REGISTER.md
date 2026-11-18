# SYSTEM WORLD — 3D Asset Register

## Purpose
Central inventory of existing 3D systems, scenes,
maps, NPC systems and procedural environments.
Do not recreate existing work without checking this file.

## Official Runtime Project
SYSTEM-WORLD/

Main scene:
- MainScene.tscn

Core integration:
- scripts/main.gd
- scripts/world_manager.gd
- scripts/world_map_manager.gd
- scripts/world_map_ui.gd
- scripts/world_map_ui_bootstrap.gd

## Maps
- world_map_manager.gd
- world_map_ui.gd
- world_map_ui_bootstrap.gd
- modern_world_discovery_manager.gd
- world_interaction_manager.gd

Map UI bootstrap is registered in project.godot.
Map manager and discovery systems are created by main.gd.

## NPC and Society
- ai_npc_society_manager.gd
- npc_player_interaction_manager.gd
- fantasy_settlement_manager.gd
- NPC life, work, travel, relationships and family data
- Resident and settlement registration

NPC visual models must be checked separately
from NPC simulation and interaction logic.

## Procedural Environments
- forest_manager.gd
- mountain_manager.gd
- waterways_manager.gd
- marine_environment_manager.gd
- marine_life_manager.gd
- wildlife_manager.gd
- fantasy_world_manager.gd
- historical_world_manager.gd
- greed_island_manager.gd

## Separate 3D Preview Project
SYSTEM-WORLD-3D/

Scenes:
- main.tscn
- command_center.tscn
- premium_command_center.tscn
- miyar_character.tscn
- adam_character.tscn
- fantasy_world.tscn
- historical_world.tscn
- portal_test.tscn

Scripts:
- 31 GDScript files in scripts/

## Existing Visual References
- assets/1000220666-1.png
- assets/ui/file_0000000053f081f4ab5d3e27245ce7a9.png

## Verification Notes
- Procedural geometry exists in GDScript.
- No standalone GLB, GLTF, FBX, OBJ or BLEND
  model files were found in the current repository tree.
- This does not mean procedural 3D geometry is absent.
- Miyar and Adam scenes have model attachment points.
- Do not delete, rename or merge either project.
- Preserve all existing work and continue from it.

## Pending Visual Audit
- Inspect generated map geometry in Godot.
- Inspect NPC visual appearance and animations.
- Confirm all scene references and runtime links.
- Separate finished assets from prototypes.


## AI-Assisted Production Tools (2026-11-17)

- `tools/blender/generate_system_world_environment.py`
  - Deterministic Blender 4.x source generator for a low-poly terrain tile,
    road spine, vegetation/rocks and a world-specific landmark.
  - Four separate presets: modern, historical, fantasy and Greed Island.
  - Exports editable BLEND, runtime GLB and seed/settings metadata JSON.
  - Source added; Blender export has **not** yet been executed in the current
    environment because Blender is unavailable.
- `tools/validate_glb.py`
  - Python standard-library GLB 2.0 structural validator.
  - Checks header/chunks, embedded resources, buffer views/accessors, mesh
    primitives and estimated triangle count.
  - Includes a generated-fixture self-test; Godot import validation remains
    a separate required step.
- `tools/README.md`
  - Documents generator usage, import workflow and Android-oriented constraints.
- `PRODUCTION_AUDIT.md`
  - Evidence-based repository, toolchain and asset-pipeline audit.

No generated GLB or finished art asset is registered yet. Add each exported
asset here only after generation, GLB validation, Godot import and visual review.


- `tools/blender/run_environment_pipeline_test.py`
  - Acceptance runner for Blender generation across one or all four world presets.
  - Checks non-empty BLEND/GLB/JSON outputs and runs the GLB structural validator.
  - Writes a JSON report and distinguishes passed, failed and Blender-unavailable
    outcomes. Runner source is committed; its execution remains pending because
    Blender and a local repository checkout are unavailable in this environment.


## Authenticated Player Parties (2026-11-18)

- `PLAYER_PARTY_BACKEND.md` — design and implementation status.
- `functions/src/player_party.ts` — authenticated, transaction-backed party and invitation callables.
- `app/src/main/java/com/system/irtqaa/FirebasePlayerPartyRepository.kt` — Android Firebase Functions client.
- `app/src/main/java/com/system/irtqaa/SystemPlayerPartyScreen.kt` — Android player-party interface.
- `firestore.indexes.json` — compound index for pending incoming party invitations.
- `MainActivity.kt` exposes the player-party section.
- Cloud Functions deployment, two-account end-to-end testing, real-time presence and Godot runtime integration remain pending.
- Existing Firestore client-write denial remains in place; party writes are server-side only.
