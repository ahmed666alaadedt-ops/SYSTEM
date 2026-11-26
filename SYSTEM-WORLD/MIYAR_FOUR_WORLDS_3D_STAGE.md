# Miyar animated guide for the four worlds

## Implemented in this checkpoint
- A standalone Godot 4.3 3D scene in the canonical SYSTEM-WORLD project.
- The Android Compose world-selection page now offers a direct full-screen launch of this 3D scene.
- Reuses the existing rigged female GLB character loader and keeps one persistent Miyar identity.
- Uses the existing idle-breathing animation, periodic blink, skeletal jaw pose during speech, and a short walk-to-gate presentation movement.
- Four separate emissive 3D world gates, touch-friendly selection buttons, Arabic subtitles, per-world appearance palettes, and a confirm-to-enter action.
- Arabic voice is routed through the Android TextToSpeech host plugin on Android; Godot platform TTS is used as a non-Android fallback when supported.
- Confirming a world selection hands the selected ID through a trusted internal bridge and starts the canonical MainScene. External Android launches remain modern-only except for opening the selection stage.

## Remaining quality and QA limits
- The jaw movement is approximate timing, not phoneme-accurate lip synchronization.
- World outfits use the existing appearance system; four separate high-detail garment meshes are not claimed.
- Automated validation must prove the rigged female GLB and idle-breathing clip load, not merely the fallback model.
- Android APK build, Godot runtime validation, actual HONOR 50 display/audio QA, touch responsiveness, and frame-rate review must pass before calling this release-ready.
