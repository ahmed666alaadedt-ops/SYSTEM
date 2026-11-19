# SYSTEM WORLD — Character Visual Design Standard

**Status:** Approved visual reference  
**Reference:** User-approved character roster image supplied on 2026-11-19  
**Scope:** All four worlds; this document defines the visual target and production requirements. It does not claim that 3D assets or runtime systems have already been implemented.

## 1. Visual direction

Use the approved image as the canonical visual reference for the character roster:
- High-detail, realistic, cinematic 3D human characters.
- Distinct male and female character designs and recognizable individual identities.
- Broad variation in facial structure, age, body shape, skin tone, hair, and presentation.
- Detailed eyes, skin, pores, wrinkles, scars, and other natural facial features where appropriate.
- Full-body designs with believable anatomy, clothing construction, materials, and proportions.
- Characters must remain readable and visually coherent in gameplay, not only in portrait renders.

The image is a style and design reference, not a finished 3D asset, rig, texture set, or game-ready character.

## 2. Four-world wardrobe direction

### Modern world
Contemporary, practical, and futuristic clothing; civilian outfits, professional uniforms, hunter equipment, and tactical gear. Preserve the recognizable real-world cultural identity of locations.

### Historical world
Clothing, armor, hairstyles, accessories, and equipment must be appropriate to the selected civilization and period. Avoid mixing unrelated historical cultures into a generic costume.

### Mythic world
Mythic and fantasy clothing, armor, ornaments, and silhouettes. Magical visual effects may complement the design but must not replace readable material and anatomical detail.

### Greed Island
Distinctive seasonal and rare outfits, rewards, and equipment. Rarity may affect ornamentation and effects, but should not make every character share one silhouette.

## 3. Character diversity and customization

The character creation and NPC pipelines should support controlled variation in:
- Face shape, jaw, cheeks, nose, lips, ears, eyebrows, and eye shape.
- Iris color, hair style, hair length, and hair color.
- Skin tone and natural surface details.
- Height, proportions, body build, and age category.
- Clothing layers, footwear, accessories, armor, and color variants.

Variation must be curated and anatomically plausible. Avoid obvious duplicate faces and repeated NPC outfits in nearby groups.

## 4. Facial performance

Prepare facial rigs and expression controls for:
- Blinking, eye direction, and gaze tracking.
- Speech and lip synchronization.
- Smiles, frowns, anger, fear, sadness, surprise, and subtle idle expressions.
- Age-appropriate wrinkles and facial movement.

## 5. Body rigging and animation

Game-ready characters should use compatible skeletons and animation retargeting where practical. Required animation families include idle, walk, run, sprint, jump, land, turn, interact, talk, combat, hit reaction, and world-specific actions. Hand and finger articulation should be supported for close interactions and cinematic scenes.

## 6. Technical production requirements

- Create and author assets in a suitable 3D pipeline such as Blender.
- Use PBR materials for skin, hair, cloth, leather, metal, and other surfaces.
- Prepare facial and body rigs before importing into Godot.
- Provide level-of-detail variants and sensible texture budgets for Android.
- Keep higher-quality asset variants possible for future PC and console targets.
- Test deformation, facial animation, material response, and performance in the actual Godot project.

## 7. Character categories

The production pipeline should cover player characters, story characters, hunters, civilians, merchants, guards, workers, and other NPCs. Named story characters should have authored identities; ambient NPCs may use controlled procedural variation while remaining consistent with their region, role, and world.

## 8. Acceptance checklist

A character is not considered game-ready until:
- The 3D mesh and materials are present in the project.
- The skeleton and required animations work.
- Facial expressions and speech controls work when required.
- Clothing and equipment deform correctly.
- The character is tested in its intended world and lighting.
- Performance is acceptable on the target Android quality tier.

## 9. Implementation boundary

Approval of this standard records the design decision only. It does not mean the reference image has been converted into 3D models, imported into Godot, or integrated into gameplay. Those tasks must be completed and verified separately.
