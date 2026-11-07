# SYSTEM WORLD — Technical Roadmap

Last reviewed: 2026-11-07

## 1. Official project decisions

- SYSTEM-WORLD is the official Godot game project.
- SYSTEM-WORLD-3D remains a prototype and reference project.
- Never delete existing project files or systems without review.
- The Android application keeps account, Firebase, profile and progression systems.
- Godot becomes the runtime for the playable 3D worlds.
- The entire playable game is intended to be 3D.
- Landscape orientation is the official mobile orientation.
- Third-person camera, movement, combat, exploration and touch controls are core requirements.

## 2. Godot version

- The exact version previously used by this project is not yet verified.
- Target stable version for compatibility review: Godot 4.7.2.
- Do not use Godot 4.8 beta as the production baseline.
- Do not upgrade the existing project blindly.
- First import a clean copy and verify scripts, scenes, assets and autoloads.
- Preserve the original project if compatibility problems appear.

## 3. Current verified project status

- SYSTEM-WORLD/project.godot is a Godot 4 project.
- Main scene: res://MainScene.tscn.
- MainScene.tscn has a Node3D root.
- The project uses the Compatibility renderer for mobile.
- Viewport is 1280x720.
- Godot project orientation is landscape.
- Android Manifest already locks the Activity to landscape.
- Android MainActivity currently launches a Jetpack Compose application.
- Android Gradle currently contains Compose and Firebase dependencies.
- Godot embedding into the Android application has not yet been verified.
- A Node3D root does not mean the entire game is already implemented in 3D.

## 4. Android and Godot integration

Follow the official Godot Android embedding workflow:

1. Identify and verify the compatible Godot editor version.
2. Import and validate the canonical Godot project.
3. Configure an Android export preset.
4. Match Android and Godot orientation.
5. Export the Godot project as an Android AAR using Gradle.
6. Add the generated AAR files and required dependencies to the Android app.
7. Integrate the Godot engine lifecycle into the Android application.
8. Preserve existing Firebase authentication and account systems.
9. Keep Android responsible for app-level services and Godot responsible for 3D gameplay.
10. Build and verify an APK on a physical Android device.

Important:
- Only one Godot engine instance is supported per Android process.
- Handle Android lifecycle, pause/resume and orientation correctly.
- Do not hardcode a developer-specific absolute Godot executable path.
- Do not claim integration is complete until an APK launches and is tested.

## 5. Mobile 3D performance

- Keep Compatibility renderer as the initial mobile baseline.
- Build small optimized 3D areas first.
- Expand maps gradually.
- Use level of detail, culling and mobile-friendly lighting.
- Optimize textures, shadows and memory usage.
- Load only the selected world and region.
- Test on HONOR 50 class hardware.
- Keep mobile controls comfortable and readable in landscape.

## 6. The four 3D worlds

### Modern realistic world
- Real geographic places and cities.
- Accurate local culture and environments.
- Modern weapons.
- Nen-inspired personal abilities.
- Realistic services, markets, hospitals and daily life.

### Historical and civilizations world
- Historical cities and civilizations.
- Historically inspired weapons and combat.
- Exploration, movement and discoveries.
- Distinct architecture and cultural environments.

### Fantasy world
- Connected kingdoms and regions.
- Elves, humans, beastfolk and magic communities.
- Magic, mythical creatures and fantasy traversal.
- Independent cultures, economies and societies.

### Greed Island
- Floating island.
- Seasonal access system.
- Independent regions and exploration.
- Rare rewards, quests and discoveries.
- AI NPC society and daily life.

Every world must ultimately contain:
- 3D terrain and environments.
- 3D buildings and objects.
- Lighting and shadows.
- Collision and navigation.
- Interactive characters and NPCs.
- World-specific gameplay systems.

Temporary placeholder geometry is acceptable during development, but must not be presented as finished artwork.

## 7. Preservation rules

- Do not delete SYSTEM-WORLD-3D.
- Do not discard existing Android or Firebase features.
- Preserve existing mobile controls unless a verified issue requires changes.
- Prefer additive, reversible changes.
- Inspect a file before replacing it.
- Keep world design and AI-NPC specifications in their dedicated files.
- A written plan is not proof of implementation.
- Mark a feature complete only after code exists and its behavior is verified.

## 8. Implementation milestones

- [ ] Identify the compatible Godot version.
- [ ] Import and validate SYSTEM-WORLD.
- [ ] Verify scripts, scenes, assets and autoloads.
- [ ] Configure Android AAR export.
- [ ] Embed Godot into the existing Android application.
- [ ] Preserve account and Firebase functionality.
- [ ] Launch the 3D scene on a real Android device.
- [ ] Verify landscape, touch controls and camera.
- [ ] Develop the four worlds progressively.
- [ ] Verify performance and save/restore behavior.

## 9. Official documentation

https://docs.godotengine.org/en/latest/tutorials/platform/android/embedding_in_android_projects.html

https://docs.godotengine.org/en/latest/tutorials/export/android_gradle_build.html

https://godotengine.org/download/archive/
