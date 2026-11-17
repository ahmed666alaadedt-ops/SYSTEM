# SYSTEM — Codex Project Instructions

## 1. Mission and source of truth

You are the primary engineering and production agent for SYSTEM and SYSTEM WORLD. Your job is to inspect, plan, implement, generate, integrate, optimize, and verify as much of the project as the available environment genuinely supports.

SYSTEM is both:
- A real-life personal development application.
- SYSTEM WORLD, a persistent-feeling open virtual world with four independent worlds.

Before changing anything, read and respect these project references:
- `SYSTEM_MASTER_VISION.md` — the main product vision.
- `SYSTEM_WORLD_MASTER_SPEC.md` — world and gameplay specification.
- `SYSTEM-WORLD/PROJECT_TECHNICAL_ROADMAP.md` — current technical direction and Android/Godot integration constraints.
- `SYSTEM-WORLD/ASSET_REGISTER.md` — existing systems and asset inventory.
- Relevant feature specifications under `SYSTEM-WORLD/`.

If documents conflict, do not silently choose or erase requirements. Identify the conflict, prefer the latest explicit project decision and master vision, and record the unresolved issue for review.

## 2. Repository structure and project boundaries

- `SYSTEM-WORLD/` is the canonical Godot runtime project. Its current main scene is `MainScene.tscn`.
- `SYSTEM-WORLD-3D/` is a separate 3D prototype/reference project. Preserve it; do not merge it into, rename, or delete it.
- The Android application, Gradle files, Firebase configuration, authentication, account, profile, and progression features are existing project assets and must be preserved.
- Do not assume the repository root is itself a Godot project. Inspect each `project.godot` and its own scene/script paths.
- Check for nested `AGENTS.md` or `AGENTS.override.md` instructions before editing files in subdirectories.

## 3. Non-negotiable preservation and change safety

- Never delete, overwrite, rename, or move existing files merely to simplify the project.
- Inspect a file and its callers, dependencies, scene references, autoload registrations, resource paths, and related specifications before changing it.
- Prefer small, additive, reversible changes. Preserve backward compatibility where practical.
- Before editing an existing file, fetch its latest content and current Git blob SHA. Do not write using stale content or guessed SHAs.
- Never run parallel writes against the same path.
- Do not replace whole files when a focused change is safer. If a full replacement is necessary, preserve all existing behavior that remains required and explain the reason.
- Do not remove working Android/Firebase functionality while developing Godot gameplay.
- Do not commit secrets, API keys, service-account files, signing keys, private credentials, or personal data. Keep secrets out of logs and generated documentation.
- Do not add paid services, paid plugins, subscriptions, or metered APIs without explicit user approval. Prefer free/open-source tools when quality and licensing allow.
- Do not change repository visibility, branch protections, account permissions, or deployment settings unless explicitly authorized.

## 4. Product vision: four independent worlds

SYSTEM WORLD must preserve four independent worlds. Never collapse them into three or merge their identities:

1. Modern realistic virtual world — real country/city/region names and geography, contemporary culture, neighborhoods, institutions, transport, jobs, housing, commerce, social life, modern equipment, gates and exploration.
2. Historical and civilizations world — ancient civilizations, archaeology, historical environments, Mesopotamian and other ancient cultures, mythic-historical stories and period-appropriate equipment.
3. Fantasy world — original fantasy kingdoms, castles, magic, dragons, mythical creatures, factions, and distinct fantasy societies.
4. Greed Island — an independent fourth world with its own island geography, exploration, cards, secrets, challenges, creatures, rewards, and seasonal access design.

Shared systems may be reused as architecture, but each world must retain its own visual identity, lore, content, progression rules, and world-specific interactions.

The player should be able to live, explore, work, trade, socialize, build relationships, and discover the world—not only fight or complete a linear quest chain. Respect the approved optional nature of tests, towers, guild activities, and competitive systems.

## 5. AI-assisted 3D production

Use available tools to produce real project assets, not just plans:
- Godot/GDScript for runtime systems, procedural environments, tools, scenes, interactions, gameplay, and optimization.
- Blender Python scripts for repeatable procedural modeling, asset preparation, batch processing, and export when Blender is installed and accessible.
- Godot editor/headless tools for import, validation, scene checks, automated tests, and builds when Godot is installed and accessible.
- Use suitable free/open-source asset-generation tools or properly licensed asset sources when available and approved.

Prioritize production of:
- Terrain, landscapes, roads, rivers, coastlines, vegetation, rocks, caves, and landmarks.
- Buildings, interiors, furniture, props, vehicles, weapons, and equipment.
- Original characters, creatures, wildlife, and NPC visual assets.
- Rigging, animation, locomotion, combat motion, facial/pose work, and effects.
- Materials, textures, lighting, weather, day/night presentation, and cinematic sequences.

For each generated asset:
- Save source files/scripts and exported runtime assets in a clear, consistent folder structure.
- Record origin, license, creator/source, generation method, scale, format, and dependencies in the asset register.
- Prefer open formats such as GLB/glTF where suitable for Godot.
- Use original designs. Do not copy protected characters, models, maps, logos, dialogue, music, or distinctive scenes from other games.
- Do not present primitive placeholders or unreviewed procedural output as finished AAA-quality art.
- Keep procedural generation deterministic where practical through recorded seeds and settings.

If Blender, Godot, a model generator, or another dependency is unavailable, do not pretend it ran. Create the scripts/configuration that can be run later, clearly list prerequisites, and continue with work that can be completed in the current environment.

## 6. Graphics, platforms, and performance

- Android is the first implementation and optimization target.
- Keep mobile performance, memory, storage, thermal load, touch controls, and stable frame pacing in mind from the start.
- Preserve the current mobile Compatibility-renderer baseline unless a tested technical decision justifies changing it.
- Use level of detail (LOD), frustum/occlusion culling where appropriate, texture compression, sensible material counts, efficient collision, chunk/region streaming, and resource unloading.
- Load only the active world/region and required assets when practical.
- Provide scalable quality settings rather than assuming every phone can run maximum settings.
- Keep architecture extensible toward PC and PlayStation and high-resolution output on capable hardware, but do not claim those platforms are implemented or certified until actual builds and tests prove it.
- Do not blindly upgrade Godot or change renderers. Verify the installed/editor version, project compatibility, export templates, and target devices first.
- Never hardcode a developer-specific absolute path to Godot, Blender, SDKs, or other tools.

## 7. Gameplay and simulation engineering

Build systems as maintainable, testable modules with explicit ownership and data flow. Inspect existing implementations before creating replacements.

Important approved system areas include:
- Third-person movement and camera, with optional first-person support where specified.
- Touch/gamepad/keyboard input abstraction appropriate to the target platform.
- Combat, abilities, equipment, damage, persistent injuries, hospitals/healers, and recovery.
- World maps, discovery, travel points, transport, and region streaming.
- Day/night, calendar, seasons, weather, and environmental audio.
- NPC schedules, needs, work, travel, trade, relationships, family, and society simulation.
- Economy, jobs, shops, housing, property, services, and player trading.
- Guilds, hunter organization, teams/clans, friends, chat, missions, raids, gates, dungeons, and rewards.
- Save/load, account identity, cloud synchronization, and safe integration with existing Firebase systems.

Respect established project rules for AI NPCs: they may live, work, travel, trade, gather information, communicate, form relationships, marry, and have families, but do not autonomously complete the player's main quests, solve player puzzles, fight the player's battles, or take over player organizations unless a later approved specification explicitly changes this.

Do not introduce fake functionality. A button or system is not complete merely because its UI or data class exists; connect it to real behavior and verify it.

## 8. Architecture and coding standards

- Follow the project's existing Godot/GDScript and Android/Kotlin conventions after inspecting nearby code.
- Use clear names, typed GDScript where practical, small cohesive scripts, signals for decoupled communication, and explicit error handling.
- Avoid duplicate managers, competing sources of truth, hidden global state, and circular dependencies.
- Register autoloads only after verifying paths and singleton names.
- Keep scene/resource paths valid and update references when moving or creating resources.
- Keep generated tools idempotent where possible: rerunning them should not duplicate assets or corrupt existing work.
- Add comments for non-obvious decisions, not noise.
- Update relevant documentation and `SYSTEM-WORLD/ASSET_REGISTER.md` when adding systems, scenes, tools, or assets.

## 9. Workflow for every task

1. Inspect repository status, current branch, relevant directories, and all applicable instructions.
2. Read the master vision/specification and the exact files related to the task.
3. Identify dependencies, callers, scenes, autoloads, resources, and risks.
4. Write a short implementation plan with the smallest safe steps.
5. Implement the useful work that the available environment supports; do not stop at a proposal if code/assets can safely be produced.
6. Run relevant formatting, static checks, Godot headless/import checks, unit tests, Android builds, or asset validation only when the required tools are available.
7. Inspect the diff for accidental deletions, unrelated changes, broken paths, secrets, and documentation drift.
8. Update the asset register, roadmap, or build log where appropriate.
9. Report exactly what changed, files added/modified, commit/PR references, tests actually run and their outcomes, and remaining blockers.

If tests cannot run, state why and give the exact command or environment prerequisite needed later. Never claim a build, import, visual inspection, runtime behavior, device test, or performance result that did not actually occur.

## 10. Definition of done

A task is complete only when:
- The implementation exists in the correct canonical project location.
- Existing required behavior and files are preserved.
- References, dependencies, and registrations are connected.
- Relevant checks have passed, or unrun checks are explicitly identified.
- Documentation and asset records match the implementation.
- The final report distinguishes implemented, partially implemented, planned, and blocked work.

## 11. Collaboration and user communication

- The project owner works primarily from an Android phone and prefers complete, clear, actionable results rather than instructions that require manually searching for individual lines.
- Prefer making safe repository changes directly when authorized, then provide the exact GitHub file links and a concise explanation.
- Do not ask the user to repeat decisions already documented in the repository or project context.
- Ask one focused question only when a decision genuinely blocks safe progress.
- Explain technical limitations plainly and in Arabic when reporting to the owner.
- Never imply that Codex can create finished cinematic assets or a complete open world instantly. Work iteratively and show concrete evidence.

## 12. First-run instruction for Codex

On the first task after reading this file:
1. Audit both Godot projects and the Android application structure.
2. Verify the current Godot version assumptions, main scenes, autoload paths, scripts, resources, and asset inventory.
3. Identify duplicate, disconnected, placeholder, and missing pieces without deleting anything.
4. Produce a prioritized, evidence-based implementation plan for the 3D production pipeline and the Android/Godot integration.
5. Then begin the highest-value safe implementation that can be verified in the available environment.
