# SYSTEM WORLD — Character Customization Profile

**Status:** Runtime profile fields implemented in the canonical NPC loader; Godot import and device validation pending.

This document records the profile fields currently read by `SYSTEM-WORLD/scripts/npc_character_model.gd`. It does not claim that every planned visual control is already available in the player-facing character creator.

## Supported profile fields

| Field | Accepted values / behavior |
|---|---|
| `name` | Display name used to name the character node |
| `gender` or `appearance` | Male/female text values; Arabic and English aliases |
| `age` | Numeric age; under 18 selects child, 60+ selects elder |
| `age_group` | `child`, `adult`, or `elder` (Arabic aliases supported) |
| `body_type` or `body` | Average, slim, heavy, athletic, muscular; changes model width/depth scale |
| `height_type` | Short, average, tall; changes model height scale |
| `skin_tone` | Fair, olive, tan, dark (Arabic aliases supported) |
| `hair_color` | Black, brown, blonde, white/gray, red (Arabic aliases supported) |
| `eye_color` | Brown, green, gray, hazel, blue (Arabic aliases supported) |
| `face` | Balanced/default, sharp, soft, broad, long, round; adjusts head-bone scale |
| `job` or `occupation` | Selects civilian, hunter, guard, or royal outfit palette |

## Example profile

```gdscript
var character_profile := {
    "name": "SYSTEM Resident 001",
    "gender": "female",
    "age": 28,
    "age_group": "adult",
    "body_type": "athletic",
    "height_type": "average",
    "skin_tone": "olive",
    "hair_color": "black",
    "eye_color": "hazel",
    "face": "soft",
    "job": "hunter"
}
```

## Asset selection

The loader selects one of six generated GLB base models:
- Adult male / female.
- Elder male / female.
- Child male / female.

If the selected GLB is missing or cannot be loaded, the existing procedural Godot fallback remains active. The generated GLB workflow copies validated base models into both the canonical `SYSTEM-WORLD` project and the preserved `SYSTEM-WORLD-3D` prototype.

## Planned, not yet implemented

- Full independent morph controls for jaw, cheekbones, nose, lips, ears, and eye spacing.
- Runtime hairstyle library and hair physics.
- Facial blendshapes for expressions, blinking, and speech synchronization.
- World-specific historical, mythic, and Greed Island clothing meshes (the current role palettes are not a substitute).
- Player-facing customization UI wired to save/load and cloud profile data.
- Visual QA and performance testing on target Android devices.

## Validation boundary

A successful source commit or GLB structural validation does not prove Godot import, animation playback, facial quality, or Android performance. Those checks must be run in the actual project environment.


## Skeletal facial controls added (2026-11-19)

The Blender generator now adds independent facial control bones:
- `jaw` for basic mouth/jaw articulation.
- `eye.L` and `eye.R` for independent eye control.
- `brow.L` and `brow.R` for eyebrow pose control.

Face geometry is assigned to these bones in semantic groups: left/right eye assemblies, left/right brows, and jaw-driven mouth parts. The canonical Godot NPC loader exposes `set_facial_expression(expression)` with basic presets: happy, angry, sad, surprised, talking, and blink (Arabic aliases are accepted for the presets).

**Limit:** These are skeletal pose presets, not facial blendshapes or a phoneme/lip-sync system. The current blink preset is an immediate pose and needs an animation/timing driver for natural periodic blinking. The current talking preset is a static jaw pose and needs audio/phoneme synchronization for speech.
