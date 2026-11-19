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
| `hair_color` | Black, brown, blonde, white, silver/gray, red, blue/navy/cyan, purple, pink, green, orange/ginger, gold and magenta (English and Arabic aliases supported) |
| `hair_style` | Short, medium, long/very long, curly/afro, braided/dreadlocks, ponytail, twin tails, bun/topknot, bob, pixie, layered, spiky, side-swept, undercut; styles are not gender-locked, including long hair for men |\n| `eye_color` | Brown, green, gray, hazel, blue (Arabic aliases supported) |
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
    "hair_color": "blue",\n    "hair_style": "long",
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


## Generated model diversity update (2026-11-19)

The Blender generator now assigns deterministic hairstyle silhouettes from three style families per gender: layered/tied-back, flowing/fringe, and braid-like styles for female bases; textured crop, side-swept fringe, and tied-back side locks for male bases. It also varies eye spacing or nose-tip width in selected base identities. Elder bases receive subtle low-poly crow's-foot, under-eye, smile-fold, and forehead age-detail geometry.

The six base GLBs have been generated and passed the workflow's structural validation. This confirms file generation and structure, not final visual quality. Face variety is still a limited base-identity set, not a full morph-target sculpt system; hairstyle swapping in the live player creator is not yet wired.


The generated armature also stores `system_hair_style_index`, `system_face_variant_index`, and `system_age_detail_level` custom properties. These metadata tags identify the base variant for future runtime selection; they do not yet provide a live hairstyle picker in the player UI.


## Child character safety rule (2026-11-19)

Child profiles are normalized to the civilian occupation before either the imported GLB path or procedural fallback is configured. A child cannot be assigned guard, soldier, police, hunter, guild-fighter, or royal combat roles through profile data. If any caller requests an attack/combat/fight/battle activity for a child, the character controller safely resolves the request to idle. Adult combat activity remains unchanged.

Automated headless validation entry point:
`godot --headless --path SYSTEM-WORLD --script res://tools/validate_child_character_safety.gd`

This test verifies both sides of the rule: child combat is blocked and adult combat remains available. The test source is committed; execution in the Godot runtime must still be confirmed.


## Facial micro-animation generation update (2026-11-19)

The Blender source generator now creates two additional named clips for every adult, elder, and child base model:

- `Facial_Blink`: a short eyelid/eye-bone close-and-open cycle with a looping curve.
- `Facial_Talking`: subtle repeated jaw motion intended as a base for later speech animation.

The character showcase QA now requires both clips in addition to idle, walk, run, jump, and attack. These are generated animation assets, not yet a complete runtime facial animation controller: selecting them through the same AnimationPlayer can conflict with locomotion, so concurrent facial/body blending still needs an AnimationTree or a dedicated animation-layer solution. Audio phoneme synchronization is also still pending.


## Runtime expression and gaze controls (2026-11-19)

The canonical Godot NPC loader now supports additional `fear`, `confused`, and `determined` expression presets in addition to happy, angry, sad, surprised, talking, and blink. It also exposes `set_eye_direction(Vector2)`, clamped to a small natural gaze range for dialogue and attention systems. Character status reports whether all six expected head/jaw/eye/brow control bones are present. The character showcase QA invokes the expression and gaze APIs and rejects imported rigs missing any required facial control bone.

The generated blink/talking clips are still assets awaiting a blended runtime animation layer; the current expression API uses direct skeletal poses.
