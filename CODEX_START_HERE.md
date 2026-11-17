# SYSTEM WORLD — First Codex Task

Read the repository-root `AGENTS.md` completely before doing anything.

You are now working on the existing SYSTEM repository. Do not create a replacement project and do not delete, rename, or merge the two Godot projects.

## Mission

Perform a real, evidence-based technical audit of the current project and then begin the safest high-value implementation step for an AI-assisted 3D production pipeline.

## Phase A — Inspect before editing

1. Inspect the repository tree and identify the Android app, Firebase integration, canonical Godot project, 3D prototype, scripts, scenes, assets, build workflows, and documentation.
2. Confirm that `SYSTEM-WORLD/` is the canonical runtime project and `SYSTEM-WORLD-3D/` is a separate prototype/reference project.
3. Read:
   - `SYSTEM_MASTER_VISION.md`
   - `SYSTEM_WORLD_MASTER_SPEC.md`
   - `SYSTEM-WORLD/PROJECT_TECHNICAL_ROADMAP.md`
   - `SYSTEM-WORLD/ASSET_REGISTER.md`
4. Inspect both `project.godot` files, main scenes, autoload registrations, script references, and actual asset formats.
5. Search for existing Blender files, GLB/glTF, FBX, OBJ, textures, rigs, animations, procedural-generation scripts, and disconnected or duplicate systems.
6. Check which tools are actually installed and usable in this execution environment: Godot editor/headless binary, Blender, Android SDK/Gradle, and any existing asset-generation utilities. Record versions and executable availability. Do not assume availability.
7. Identify broken paths, missing resources, parse/import errors, or unconnected systems only when supported by inspection or executable checks.

Do not make code changes during this inspection phase unless a tiny read-only-safe diagnostic requires a temporary file outside the repository. Do not alter project settings merely to make an audit pass.

## Phase B — Deliver the audit

Create or update a concise report at `SYSTEM-WORLD/PRODUCTION_AUDIT.md` containing:
- Verified repository/project structure.
- Tool availability and versions.
- Existing 3D scenes, assets, procedural systems, and their real status.
- Missing production-pipeline capabilities.
- Risks and dependencies for Android/Godot integration.
- A prioritized, phased roadmap with acceptance criteria.
- Exact checks performed and their results.
- Items that could not be verified.

Do not label planned, placeholder, or disconnected features as complete.

## Phase C — Begin the first safe implementation

After the audit, choose one high-value task that can genuinely be implemented and verified with the available tools. Prefer establishing a repeatable asset-production foundation over generating a huge unfinished map.

Possible first deliverables, depending on actual tool availability:
- A Blender Python procedural asset-generation script with deterministic parameters and export to GLB.
- A Godot procedural environment/terrain tool with a small test scene and documented controls.
- A validated asset folder convention and automated asset-register workflow.
- A Godot headless validation script/workflow for project import, resource paths, and scene checks.

The first implementation must:
- Be additive and isolated.
- Use original project-owned designs or properly licensed inputs.
- Include clear run instructions and required tool versions.
- Include a small test/example output where the tools allow it.
- Avoid paid services and new paid dependencies.
- Be optimized with Android constraints in mind.
- Not claim visual quality, runtime success, or performance without actual evidence.

## Phase D — Verify and report

Run only checks supported by installed tools. Inspect the diff and confirm no unrelated files were removed or changed. Update `SYSTEM-WORLD/ASSET_REGISTER.md` and the roadmap if the implementation changes the real project status.

Finish with:
1. What was inspected.
2. What was implemented.
3. Exact files added/changed.
4. Commands/checks actually run and results.
5. What remains blocked and why.
6. The next single recommended task.

If a critical decision or unavailable tool blocks implementation, stop at the evidence-based audit and report the blocker clearly. Do not fabricate assets, test results, or successful builds.
