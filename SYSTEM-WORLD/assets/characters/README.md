# SYSTEM WORLD Humanoid Character Assets

This folder contains generated male and female GLB base models for the modern-world NPC population. The models are produced by the shared Blender generator at `SYSTEM-WORLD/tools/blender/generate_system_humanoids.py`.

Expected files:
- `SYSTEM_Humanoid_Male.glb`
- `SYSTEM_Humanoid_Female.glb`

The Godot loader uses these files when present and keeps a procedural fallback when they are absent. Automated validation checks the GLB container, weighted skeletal skin, joint count, five core animation clips, and a mobile triangle budget. Device-level visual and performance review is still required before calling the assets production-ready.
