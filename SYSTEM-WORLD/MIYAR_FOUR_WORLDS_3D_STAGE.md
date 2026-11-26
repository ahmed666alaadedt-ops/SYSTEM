# Miyar animated guide for the four worlds

## Added in this checkpoint
- A standalone Godot 4.3 3D scene in the canonical SYSTEM-WORLD project.
- Reuses the existing rigged female GLB character loader and keeps one Miyar identity.
- Uses the existing idle-breathing animation, periodic blink and facial expression controls.
- Four 3D portal gates, touch-friendly world buttons, Arabic dialogue, per-world outfit palettes, and a short approach-and-return presentation movement.
- Uses the platform's Arabic TTS voice when one is available; subtitle text remains visible as a fallback.

## Integration status
- The 3D scene and its validator are added to the canonical Godot project.
- The current Android Compose world-selection screen has not yet been replaced or embedded with this scene. That Android host integration and HONOR 50 visual/audio testing are still required.
- Mouth movement is a simple jaw pose timed approximately to TTS duration, not phoneme-accurate lip sync.
- World outfits use the existing appearance system; four separate high-detail garment meshes are not claimed.

## Required QA
- Godot import and scene launch.
- Confirm the rigged GLB and idle-breathing animation are loaded rather than a procedural fallback.
- Visual/audio QA on Android and integrate the 3D scene into the actual world-selection screen.
