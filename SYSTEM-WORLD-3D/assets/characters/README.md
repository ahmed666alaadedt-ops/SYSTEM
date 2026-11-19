# SYSTEM WORLD — Humanoid Character Assets

This folder receives the generated base humanoid models used by the 3D world.

## Base models
- `SYSTEM_Humanoid_Male.glb`
- `SYSTEM_Humanoid_Female.glb`

The Blender generator is maintained at:
`SYSTEM-WORLD/tools/blender/generate_system_humanoids.py`

## Rig and animation targets
The exported models are expected to include:
- A deforming body mesh and combined face/hand/outfit mesh groups, all with vertex weights
- A hierarchical 40-joint humanoid armature, including hands and finger joints
- Embedded PBR materials
- Five animation clips: `Idle_Breathing`, `Walk_Cycle`, `Run_Cycle`, `Jump_Animation`, and `Attack_Animation`

## Runtime use
`scripts/npc_character_model.gd` loads the GLB when present and otherwise uses the procedural Godot rig as a fallback. NPC profession selects an outfit palette. The same base models are intended for NPC populations and the future player character creator. Face, hands and outfit details are grouped into a small number of weighted meshes to reduce per-NPC draw calls. Runtime palettes vary skin tone, hair and profession-based clothing.

## Validation
The character workflow checks:
- GLB 2.0 container structure
- Embedded geometry and buffers
- At least one skeletal skin with weighted JOINTS/WEIGHTS attributes
- At least ten joints
- The five core animation clips
- A mobile triangle budget (target: 85,000 triangles or fewer)

A successful automated export is not a substitute for visual review on the target Android device. Facial expressions, cloth simulation, advanced skin shaders, detailed hands, and cinematic motion capture remain future quality passes.
