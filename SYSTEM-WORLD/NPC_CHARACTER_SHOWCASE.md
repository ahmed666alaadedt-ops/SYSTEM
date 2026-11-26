# SYSTEM WORLD — NPC Character Showcase

The canonical Android app home screen includes **معرض الشخصيات ثلاثي الأبعاد**. It launches a dedicated Godot scene built from the same NPC character loader used by the live NPC population.

The showcase contains 12 sample residents across the modern, historical, fantasy and Greed Island worlds. It exercises all six tracked base GLB variants: adult male/female, elder male/female and child male/female. Each sample uses a distinct profile for skin, hair, eyes, face preset, body profile and hairstyle. Existing civilian-only restrictions for children remain active.

Inside the showcase:
- **تشغيل المشي** toggles the imported walk/idle clips.
- **تغيير التعابير** cycles the supported skeletal facial presets.
- **تدوير الشخصيات** rotates the lineup for a side/profile inspection.
- **العودة للعبة** returns to the canonical main scene.

This is a review stage, not a claim that the NPC art has reached GTA production quality. The current outfit system still applies world/profession palettes to shared clothing geometry; dedicated garment meshes, armour silhouettes, facial blendshapes, natural blink timing, phoneme lip-sync, final visual review and Android device performance review remain outstanding.

Automated validation checks that all 12 showcase actors load imported GLBs, all six base age/gender assets are represented, all four world IDs are exercised, and idle/walk animation clips are present.
