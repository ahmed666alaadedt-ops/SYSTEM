# Baghdad Towers — Shopping Arsenal, Airfield, and Hunter Entrance
Status: approved design specification — 2026-11-24
Branch: `feature/baghdad-five-plus-power-tower-20261122`

## Canonical Baghdad layout
- Baghdad's public complex contains **five towers**. The Hunter Association Tower is the highest/overlooking tower above the five-tower complex, as established in the approved visual layout; it is not a sixth ordinary shopping/business tower.
- The Power Tower remains a separate, independent 200-floor challenge tower and is not part of Baghdad's five-tower complex.
- Preserve all existing tower interiors, jobs, NPCs, restaurant/hotel services, evacuation exits, and progression. Extend existing systems; do not replace completed work.
- Include a real, functional **aircraft landing pad / helipad** as part of the Baghdad tower complex. It must be visibly built into the architecture, have safe approach/landing clearance, a player-accessible arrival/departure interaction, and connect to the world's travel/transport system. It is gameplay infrastructure, not decorative scenery.

## Shopping and Trade Tower — specialist floors
The existing Shopping Tower already defines weapons merchant and elixir pharmacist roles. Expand those existing vendor/floor systems rather than creating a duplicate shop system.

Create distinct, explorable specialist floors/sections with NPC merchants, item displays, stock, prices, purchase/equip flows, and inventory integration:

1. **Weapons floors:** swords, daggers, axes, maces, spears, polearms, bows, crossbows, arrows/bolts, shields, and other historically inspired melee/ranged equipment.
2. **Modern equipment floors:** modern firearms and compatible equipment where permitted by the world's progression/rules, tactical gear, protective equipment, and modern combat tools.
3. **Armor and clothing floors:** historical armor, fantasy armor, shields, modern combat suits, ballistic/resistant protective outfits, helmets, gloves, boots, and upgrade/repair services.
4. **Elixir and consumables floors:** distinct, clearly described products such as Nen-style energy elixir, stamina/energy elixir, strength elixir, recovery elixir, resistance elixir, and rare high-tier elixirs. Use original SYSTEM lore and names; do not imply real-world medical effects.
5. **Skill and technique marketplace:** rare, unusual, specialized, and advanced skills/techniques offered by qualified vendors under eligibility, mastery, scarcity, and price rules. Skills must be acquired through the existing progression/learning system; buying a skill must not bypass prerequisites or verified unlocks.

All categories must respect world-specific equipment rules: modern weapons/gear belong to the modern world; historical weapons belong to historical settings; magical/fantasy equipment belongs to fantasy settings. The shop can expose catalogues across categories but must clearly label compatibility and prevent invalid equipment use. Stock, economy, and rewards must remain balanced.

## Hunter Association Tower and hidden examination entrance
- The Hunter Association Tower is the uppermost authority building in the Baghdad complex. Mayar is its president and presents verified Hunter Association awards at formal ceremonies.
- Preserve the already implemented hidden underground test route, its three-inscription puzzle, registration prerequisite, and physical transition into the lower passage. Do not make the entrance openly visible or directly accessible from the street.
- The entrance should be discovered through environmental clues and exploration within the tower complex. An original restaurant-based interaction may serve as the concealed trigger: a specific unusual order/request, service interaction, or hidden clue causes access to a concealed passage only after the required puzzle and registration conditions are met.
- The inspiration is the feeling of a secret entrance/examination in a hunter adventure story, not a reproduction of an anime scene, dialogue, characters, or exact mechanism. Keep SYSTEM's own story, puzzle, and implementation.
- Once unlocked, preserve the actual physical entrance and passage transition; do not replace it with a text-only message.

## Scope and implementation discipline
- This file records the complete approved design scope; it is not proof that every item is already implemented.
- Before changing runtime code, inspect current branch/commit and the existing tower scripts, scenes, vendors, test scripts, and checkpoint. Identify what is already complete and list only missing pieces.
- Implement missing parts incrementally on `feature/baghdad-five-plus-power-tower-20261122` and its existing draft PR #38. Never merge to `main` without explicit user approval.
- Add functional tests for helipad access/arrival, specialist shop catalogues and purchases, equipment compatibility, elixir/skill prerequisites, and the hidden examination entrance conditions.
- Do not report Baghdad Towers complete until all relevant Godot operation tests pass and the Android export/artifact workflow succeeds.
