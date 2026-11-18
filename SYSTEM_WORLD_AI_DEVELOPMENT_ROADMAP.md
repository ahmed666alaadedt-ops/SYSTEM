# SYSTEM WORLD — AI Development Roadmap
> Baseline audit: 2026-11-18  
> Repository: `ahmed666alaadedt-ops/SYSTEM`  
> Audited branch: `main`  
> Audited baseline commit: `1b0eb82dcd2961fdc3d33e67afb76604f4878d21`

## 1. Project authority and preservation rules

- `SYSTEM-WORLD/` is the canonical Godot game project.
- `SYSTEM-WORLD-3D/` remains preserved as a separate prototype and source of reusable work.
- Do not delete, rename, or wholesale replace either project.
- Reuse prototype systems only after checking their scene dependencies, scripts, resources, input mappings, and runtime behavior.
- Keep the four worlds independent: modern realistic, historical/civilizations, fantasy/mythic, and Greed Island.
- Treat a feature as **implemented** only when its source is connected; as **integrated** only when it is connected to the canonical project; and as **verified** only after a real Godot run/build and functional test.

## 2. Baseline audit — verified repository facts

### Canonical project: `SYSTEM-WORLD/`

- Godot project entry: `SYSTEM-WORLD/project.godot`.
- Main scene: `SYSTEM-WORLD/MainScene.tscn`.
- Main scene attaches `scripts/main.gd` and the portal, hunter guild, social chat, clan, progression, and account UI scripts.
- The project uses the Godot 4 project format and the `gl_compatibility` renderer setting, a sensible starting point for broad mobile compatibility.
- The main script creates the world, wildlife, NPC society, map, time, player, interaction, mobile controls, and mission reward managers.
- `world_manager.gd` creates four world roots and selects the modern world at startup.
- The time manager listens for world changes and reconfigures the sky/time environment.
- The official NPC society manager is instantiated by the canonical main script. The fantasy settlement manager also has an NPC-society integration path.
- The hunter guild menu emits `mission_accepted`; the main script connects it to the mission reward manager.
- Mission rewards currently use three fixed mission IDs and XP values. The public completion method expects a trusted verifier, but the inspected code does not yet show a complete objective-verification authority or server-side validation path.

### Prototype: `SYSTEM-WORLD-3D/`

- Its Godot project entry is `SYSTEM-WORLD-3D/project.godot`.
- Its configured run scene is `res://scenes/premium_command_center.tscn`.
- It contains separate world/command-center scenes and scripts for an assistant stage, Android world bridge, NPC society, and save handling.
- Its `scripts/main.gd` is a standalone 3D town foundation: it creates terrain, town, player, UI, NPC manager, and save manager.
- Its NPC manager creates twelve visible capsule-placeholder residents with simple work/rest/eat/social routines. This is useful as a prototype for behavior flow, not as a finished character system.
- The prototype command-center script contains a placeholder method for Miyar; the existence of an assistant stage does not prove a finished animated character asset.

### Assets and runtime verification

- The audited repository contains no committed production-ready 3D character/monster/environment model library in either project folder.
- The Blender environment workflow has produced small environment prototype artifacts in CI, but those are workflow artifacts, not yet integrated runtime assets in the canonical project.
- The successful native Android workflow builds the separate Android app; it does not prove that the Godot open-world game has been exported and run.
- No completed end-to-end Godot Android game build/runtime test was established by this audit.

## 3. Important integration findings

1. **Keep the two NPC implementations distinct until reconciled.** The canonical project uses a record-oriented society simulation with life histories, relationships, needs, and persistence. The prototype has visible placeholder residents and simple movement schedules. They share a purpose but are not drop-in replacements.
2. **NPC presentation is incomplete.** The prototype residents are primitive capsule visuals, not rigged human models with animation, clothing, facial detail, or voice.
3. **Mission verification is a security boundary.** Mission acceptance and XP reward plumbing exist, but a trusted objective evaluator and authoritative persistence must be designed before rewards can be treated as verified.
4. **World visuals are still procedural foundations.** Roads, buildings, terrain pieces, lighting, and environment systems in scripts do not equal a finished large-scale open world.
5. **Scene integration must be explicit.** Every imported system needs a dependency map covering its scene, scripts, resources, autoloads, input actions, signals, and save data.

## 4. Development sequence

### Phase A — Stabilize the canonical project
- Read every script referenced by the main scene and every autoload.
- Build a dependency map from the main scene through world managers, player, UI, NPCs, map, time, and save systems.
- Detect missing resources, duplicate class names, stale paths, invalid signal connections, and scripts that are never instantiated.
- Add a repeatable headless Godot validation workflow for the canonical project.
- Do not change gameplay behavior until the baseline import and parse checks are reproducible.

### Phase B — Integrate the world foundation
- Verify world switching, spawn positions, player transfer, map state, day/night cycle, weather, and fast-travel flow.
- Define shared interfaces for all four worlds so each world can provide terrain, settlements, NPCs, activities, enemies, and discovery points without leaking state into another world.
- Import Blender-generated environment prototypes only after visual inspection, scale checks, collision setup, material checks, and mobile performance profiling.

### Phase C — Player and character pipeline
- Establish a consistent character specification: skeleton, scale, materials, facial setup, clothing slots, animation naming, collision capsule, LODs, and mobile texture budgets.
- Create one original player character and one original NPC as pipeline proofs.
- Verify idle, walk, run, turn, jump, combat, hit reaction, death, and interaction animations before producing large character batches.
- Keep Android quality scalable; reserve higher-detail assets for stronger platforms.

### Phase D — NPC society and living world
- Reconcile the canonical society simulation with the prototype's visible resident movement.
- Separate simulation records from presentation nodes.
- Add deterministic schedules, navigation, work, trade, travel, relationships, family lifecycle, needs, and persistence.
- Preserve the rule that civilian NPCs do not solve player puzzles, complete player missions, or participate in player-only combat objectives.
- Test save/load, offline progression rules, population limits, and performance before expanding the population.

### Phase E — Missions, combat, and progression
- Replace sample-only missions with data-driven mission definitions.
- Connect mission objectives to actual world events and interactions.
- Implement trusted completion checks, anti-duplication, persistence, and server authority before any valuable reward.
- Add combat state, injuries, healing, equipment, abilities, and progression in testable increments.

### Phase F — Stories, dialogue, and world content
- Create an original narrative bible and a world/region/location database.
- Generate quests and dialogue from approved lore and gameplay constraints.
- Keep the four worlds' histories, technologies, weapons, magic rules, and economies distinct.
- Add cutscenes and cinematic presentation after the underlying quest and character systems are stable.

### Phase G — Production assets and optimization
- Produce terrain, buildings, interiors, foliage, creatures, equipment, and animation assets in repeatable batches.
- Use a consistent import pipeline and asset naming convention.
- Add collision, navigation, LODs, occlusion, texture compression, streaming, and memory budgets.
- Profile on a real Android device and scale quality by device capability.

## 5. AI agent work protocol

For every task, the agent must:

1. Read the relevant existing files and their dependencies before editing.
2. State the exact files it plans to add or change and why.
3. Preserve existing behavior unless the task explicitly changes it.
4. Prefer small, reviewable changes over replacing whole subsystems.
5. Run available static/import/build checks and report the exact command and result.
6. Separate generated assets, integrated assets, and verified playable features in its report.
7. Never claim a feature works merely because a script or scene exists.
8. Never delete or overwrite existing project content without explicit approval.
9. Keep a change log and identify remaining risks and manual device tests.

## 6. First implementation backlog

Priority order:

1. Validate the canonical project import and scene startup in Godot headless mode.
2. Produce a complete dependency map for `MainScene.tscn` and all eight configured autoloads.
3. Verify the player, camera, mobile controls, and world switching in a real runtime.
4. Verify NPC society creation, visual representation, simulation updates, and save/load.
5. Verify map discovery, fast travel, time/weather, and all four world roots.
6. Replace the three sample hunter missions with a data-driven mission/objective structure.
7. Establish the first rigged character and animation pipeline.
8. Import and validate the four Blender environment prototypes.
9. Expand world content only after the foundations above pass.

## 7. Current status

This document records an audit and development plan. It does **not** mean that the listed future phases have been completed. No existing project file was changed as part of the baseline audit. The next code changes should be made as small, reviewable additions to `SYSTEM-WORLD/`, while preserving `SYSTEM-WORLD-3D/`.
