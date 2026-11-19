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


## XSX Real-Player Party Mission Registration (2026-11-18)

- `functions/src/hunter_guild_missions.ts` — server-validated XSX mission publication, available mission listing, leader-only party registration, and assignment listing.
- `functions/src/index.ts` exports the four mission callables.
- `app/src/main/java/com/system/irtqaa/FirebasePlayerPartyRepository.kt` — Android mission-board and registration calls.
- `app/src/main/java/com/system/irtqaa/SystemPlayerPartyScreen.kt` — mission board section and leader-only team registration.
- `SYSTEM-WORLD/XSX_PARTY_MISSION_BACKEND.md` — backend schema, validation and deployment/test requirements.
- Mission/assignment Firestore documents remain client-write denied by the existing catch-all rule.
- Roster snapshots contain only registered Firebase player UIDs and profile display names; no NPC is accepted or substituted.
- Godot mission dispatch, gameplay contribution verification, completion and rewards are not connected yet. Cloud Functions deployment and Android runtime testing remain pending.


## XSX Verified Mission Contribution Ledger (2026-11-18)

- `functions/src/hunter_guild_contributions.ts` — leader-started mission sessions, game-server-only verified gameplay event ingestion, per-player contribution totals, duplicate-event protection, rate limiting and game-server-only session completion.
- `functions/src/index.ts` exports session start, event record, contribution listing and session finish callables.
- `app/src/main/java/com/system/irtqaa/FirebasePlayerPartyRepository.kt` — Android session start and contribution listing client.
- `app/src/main/java/com/system/irtqaa/SystemPlayerPartyScreen.kt` — leader start button and verified contribution scoreboard.
- `XSX_VERIFIED_CONTRIBUTION_SYSTEM.md` — event rules, weights, trust model and deployment requirements.
- No client gameplay event submission endpoint is exposed. No NPCs are included. No rewards are granted.
- Dedicated game-server identity, Godot bridge, Firebase deployment and runtime testing remain pending.


## Android / Godot Runtime Bridge (2026-11-19)

- `scripts/system_android_bridge.gd` — engine-side bridge contract for queued
  world-entry requests, outbound world-state/result signals and startup arguments.
- `project.godot` registers the bridge as `SYSTEMAndroidBridge`.
- `scripts/main.gd` connects the bridge to the canonical `WorldManager`,
  publishes active-world changes and accepts external startup entry only into
  the modern world. Other world entry requests are directed to the Baghdad
  Star Gate travel flow.
- Native Android host/plugin, Godot AAR export, Gradle embedding, Firebase
  session adapter and device verification remain pending. This is not yet a
  live Android-to-Godot transport.


- `app/src/main/java/com/system/irtqaa/SystemGodotMessageRouter.kt`
  - Transport-independent Android message router for the versioned Godot
    protocol; modern-only external world requests; Firebase UID supplied by
    the authenticated host; inbound message direction and payload validation.
  - Not yet instantiated by an Activity or connected to a live Godot transport.


## Approved Character Visual Standard and Facial Pipeline (2026-11-19)

- `CHARACTER_DESIGN_STANDARD.md` — owner-approved roster reference and four-world character art direction.
- `tools/blender/generate_system_humanoids.py` — enhanced procedural facial geometry: separate sclera, iris, pupil, catchlight, eyelid, nose bridge/tip, nostrils and natural lip parts; mouth parts are exported as a separate semantic mesh group from hair.
- `assets/characters/README.md` — records the approved reference, generated base-model coverage, and remaining asset gaps.
- The generator change triggers `.github/workflows/system-world-humanoid-characters.yml` to regenerate six adult/elder/child male/female GLB base models, validate their GLB structure/skin/animation/triangle budgets, and copy them into both Godot project asset folders.
- This commit updates the source generator and documentation only. Generated GLBs, CI completion, Godot import, visual review, and Android device validation must be confirmed separately.


- `assets/characters/CHARACTER_CUSTOMIZATION_PROFILE.md` — documents the profile fields currently supported by the canonical NPC loader: age group, body type, height, skin tone, hair color, eye color, face shape, and job-based outfit palette.
- `scripts/npc_character_model.gd` — now selects adult/elder/child male/female GLB paths and applies profile-based body proportions, skin/hair/iris colors, and head-shape scaling. The procedural fallback remains available when a GLB is missing.
- The same runtime controller exposes `set_facial_expression()` presets (including fear, confusion, and determination), `set_eye_direction(Vector2)`, and reports whether all six facial control bones are present. `SYSTEM-WORLD-3D/tools/validate_character_showcase.gd` now checks these controls.
- `tools/validate_child_character_safety.gd` — headless QA for civilian-only child profiles and blocked child combat activities; confirms adult combat requests remain available.
- Runtime customization is partial: face morphs are head-bone scale presets, not independent facial morph targets; hairstyle switching, facial blendshapes, and world-specific clothing meshes remain pending. Child profiles are now forced to civilian occupation in imported and fallback models, and combat activity requests resolve to idle.


- Facial rig extension: `tools/blender/generate_system_humanoids.py` adds `jaw`, `eye.L/R`, and `brow.L/R` control bones and assigns mouth, eye, and brow mesh groups to them.
- The Blender generator now exports `Facial_Blink` and `Facial_Talking` clips for all six base models; `SYSTEM-WORLD-3D/tools/validate_character_showcase.gd` requires both clips in its character QA. Concurrent facial/body blending and phoneme-synced lip movement remain pending.
- `scripts/npc_character_model.gd` exposes `set_facial_expression(expression)` for basic bone-driven happy, angry, sad, surprised, talking, and blink poses. This is not yet a blendshape or audio-driven lip-sync implementation.
- `assets/characters/CHARACTER_CUSTOMIZATION_PROFILE.md` documents the supported expression presets and validation limits.


- Character diversity pass: `tools/blender/generate_system_humanoids.py` now generates three deterministic hairstyle silhouette families across male/female base identities, minor face-proportion variation, and subtle age-line geometry for elder bases.
- Automated Blender generation and GLB structural validation completed successfully for the six base models in workflow run `44509211756`; generated artifact: `system-world-rigged-humanoid-characters`.
- New diversity pass commit `e36fca6c36ed6e201a1c30854e3f5983336d5248` is queued for a fresh generation and Godot validation run; its output is not yet confirmed.


## Expanded Runtime Hair Customization (2026-11-19)

- `scripts/npc_character_model.gd` in the canonical `SYSTEM-WORLD` project and `SYSTEM-WORLD-3D/scripts/npc_character_model.gd` in the preview project expose independent `set_hair_color()` and `set_hair_style()` controls.
- Hair palette includes natural shades and fantasy colors: black, brown, blonde/yellow, white, silver/gray, red, blue/navy/cyan, purple, pink, green, orange/ginger, gold and magenta.
- Runtime hairstyle silhouettes include short, medium, long, curly/afro, braided/dreadlocks, ponytail, twin tails, bun/topknot, bob, pixie, layered, spiky, side-swept and undercut. Styles are not gender-locked; long hairstyles are supported for male characters.
- The preview showcase now presents a male character with long hair. Automated showcase QA tests long male hair geometry and multiple fantasy hair colors.
- These are runtime-generated accessory meshes attached to the head bone, not a finished salon/customization UI. Player-facing UI, save/load integration, hair strand physics and final visual review remain pending.


## Live Player Appearance Creator (2026-11-19)

- `SYSTEM-WORLD-3D/scripts/player_profile_button.gd` now provides a scrollable player creator with 18 hairstyle choices and 17 hair colors, including fantasy shades and very long hair for male characters.
- Player appearance is saved and restored locally with `user://system_player_profile.cfg`.
- `SYSTEM-WORLD-3D/scripts/player_character_3d.gd` now uses the shared rigged character loader for both GLB and procedural fallback, preserving the same hairstyle and color controls.
- `SYSTEM-WORLD-3D/scripts/command_center.gd` creates the player avatar and applies each confirmed profile to the live 3D character.
- `SYSTEM-WORLD-3D/tools/validate_character_showcase.gd` includes player-level QA for male long hair, hairstyle geometry, and the expanded hair-color palette.
- Cloud profile synchronization and final in-game visual review remain future work; the current profile save is local to the device.


## Gender-Specific Player Hairstyle Lists (2026-11-19)

- The player creator filters hairstyle choices when the player selects male or female appearance.
- Men's list includes modern barber styles (Fade family, Taper Fade, Undercut, Buzz Cut, Crew Cut, Textured Crop, French Crop, Quiff, Pompadour, Slick Back, Side Part, Spiky) and long men's options (long/layered/wavy/curly, ponytail, man bun, braids, dreadlocks).
- Women's list remains separate and includes short, medium, long, curly, braided, bob, pixie and other styles.
- Runtime character loaders recognize the modern haircut identifiers and map them to the currently implemented procedural geometry. Exact high-detail barber silhouettes remain to be produced as dedicated hair assets.
- Showcase QA checks the gender-specific lists and verifies long men's options are present while feminine-only examples are not offered in the men's list.


## Runtime Hair Silhouette Expansion (2026-11-19)

- Added dynamic hair color/style handling to the 3D preview procedural humanoid fallback.
- Added runtime mesh silhouettes for fade family, short crops, quiff/pompadour, slick-back/side-part, and long styles.
- Imported character loader maps the men's barber menu into separate fade, quiff and slick-back groups.
- Character showcase QA now exercises men's haircut options on both imported player character and procedural fallback; CI result pending for the latest commit.


## Canonical Godot Runtime Validation CI (2026-11-19)

- `.github/workflows/canonical-godot-validation.yml` runs on changes under
  `SYSTEM-WORLD/` and supports manual dispatch.
- The workflow downloads the project's Godot 4.3 baseline, verifies the
  canonical `project.godot` and `MainScene.tscn`, performs a headless editor
  import/parse pass, then launches the canonical main scene headlessly for a
  bounded number of frames.
- Import and runtime logs are uploaded as a GitHub Actions artifact even when
  a later validation step fails.
- This workflow validates the canonical runtime project separately from the
  existing `SYSTEM-WORLD-3D/` Android preview workflow.
- The workflow source is committed; its first run and all Godot runtime results
  must be read from GitHub Actions before claiming the canonical project passes.
