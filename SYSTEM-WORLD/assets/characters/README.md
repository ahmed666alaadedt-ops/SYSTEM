# SYSTEM WORLD Humanoid Character Assets

This folder contains generated male and female GLB base models for the modern-world NPC population. The models are produced by the shared Blender generator at `SYSTEM-WORLD/tools/blender/generate_system_humanoids.py`.

Expected files:
- `SYSTEM_Humanoid_Male.glb`
- `SYSTEM_Humanoid_Female.glb`

The Godot loader uses these files when present and keeps a procedural fallback when they are absent. Automated validation checks the GLB container, weighted skeletal skin, joint count, five core animation clips, and a mobile triangle budget. Device-level visual and performance review is still required before calling the assets production-ready.


## Approved visual reference (2026-11-19)

The owner-approved SYSTEM WORLD character roster image is the canonical art-direction reference for:
- Distinctive male and female faces, age groups, body silhouettes, and natural facial variation.
- Detailed eyes with sclera, iris, pupil, and catchlight; nose structure and natural lips.
- Four separate wardrobe identities: modern, historical, mythic/fantasy, and Greed Island.
- Cinematic, realistic presentation while preserving mobile-friendly mesh and material budgets.

The Blender source generator now builds separate eye and mouth semantic mesh groups so eye colors and lip materials are not overwritten by hair-color changes. The generated base models remain reusable foundations; the reference image itself is not a game-ready mesh.

## Current generated model set

The generator produces six base GLB variants:
- Adult male and female.
- Elder male and female.
- Child male and female.

The current base set does not yet represent the full range of unique faces, body morphs, hairstyles, or world-specific outfits shown in the reference. Those require additional variants and runtime customization passes.
