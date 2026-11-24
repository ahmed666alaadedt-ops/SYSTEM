# Baghdad Towers — Shopping Arsenal, Airfield, and Hunter Entrance
Status: approved design specification — 2026-11-24
Branch: `feature/baghdad-five-plus-power-tower-20261122`

## Canonical Baghdad layout
- Baghdad's connected vertical district has **exactly five towers**: Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation. They form one elevated urban district across the Karkh–Rusafa corridor.
- The Hunter Association Tower uses the verified Republic Bridge/Tigris coordinates as its geographic center, but its physical base stands on the uppermost circular Baghdad sky-city crown platform at 419.2 m above the local reference level. It is the tallest, central, functional tower above the four surrounding district towers; the Republic Bridge and Tigris remain visible and traversable below.
- The elevated city/district is a distinct, traversable urban layer integrated with the five towers; retain the river channel and bridge identity beneath/through the district.
- The Power Tower remains a separate, independent 200-floor challenge destination away from the Baghdad five-tower district. It is never counted among the five and never connected to their skybridge/transport loop.
- Preserve all existing tower interiors, jobs, NPCs, restaurant/hotel services, evacuation exits, and progression. Extend existing systems; do not replace completed work.
- Build the Hunter Association Tower's **uppermost rooftop helipad above the tower** with safe approach/landing clearance, a player-accessible arrival/departure interaction, and a working connection to the world's travel/transport system. It is gameplay infrastructure, not decorative scenery.
- The Hunter tower must have prominent internal-facing and external-facing advertising facades/screens integrated into its architecture; advertising surfaces must be visible from both the elevated city and the outside skyline.

## Shopping and Trade Tower — specialist floors
The existing Shopping Tower already defines weapons merchant and elixir pharmacist roles. Expand those existing vendor/floor systems rather than creating a duplicate shop system.

Create distinct, explorable specialist floors/sections with NPC merchants, item displays, stock, prices, purchase/equip flows, and inventory integration:

1. **Weapons floors:** swords, daggers, axes, maces, spears, polearms, bows, crossbows, arrows/bolts, shields, and other historically inspired melee/ranged equipment.
2. **Modern equipment floors:** modern firearms and compatible equipment where permitted by the world's progression/rules, tactical gear, protective equipment, and modern combat tools.
3. **Armor and clothing floors:** historical armor, fantasy armor, shields, modern combat suits, ballistic/resistant protective outfits, helmets, gloves, boots, and upgrade/repair services.
4. **Elixir and consumables floors:** distinct, clearly described products such as Nen-style energy elixir, stamina/energy elixir, strength elixir, recovery elixir, resistance elixir, and rare high-tier elixirs. Use original SYSTEM lore and names; do not imply real-world medical effects.
5. **Skill and technique marketplace:** rare, unusual, specialized, and advanced skills/techniques offered by qualified vendors under eligibility, mastery, scarcity, and price rules. Skills must be acquired through the existing progression/learning system; buying a skill must not bypass prerequisites or verified unlocks.

All categories must respect world-specific equipment rules: modern weapons/gear belong to the modern world; historical weapons belong to historical settings; magical/fantasy equipment belongs to fantasy settings. The shop can expose catalogues across categories but must clearly label compatibility and prevent invalid equipment use. Stock, economy, and rewards must remain balanced.

## Five-tower elevated public gardens — user-confirmed scope

- Each of the five connected Baghdad civic towers (Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, Technology and Innovation) has exactly three dedicated elevated public sky gardens.
- Each garden is a walkable ring promenade around the tower shaft, with physical floor collision and clear central-shaft clearance.
- Every garden includes transparent perimeter safety rails, planted beds, trees, benches, path lighting, Arabic/English identity signage, and a nearby interaction trigger mapped to its host tower and floor.
- The three garden decks are distributed across lower, middle and upper tower levels and reached through the host tower's floor/elevator system; do not treat decorative rooftop garden meshes as completion.
- The five-tower gardens are part of the connected Baghdad district. The standalone Power Tower is excluded.
- Garden validation must check all fifteen garden instances, their floor collisions, railings, landscaping, seating and interaction/floor metadata in Godot.

## Hunter Association Tower and hidden examination entrance
- The Hunter Association Tower is one of the five connected Baghdad district towers and is specifically located above Republic Bridge on the Tigris riverfront. Mayar is its president and presents verified Hunter Association awards at formal ceremonies.
- Preserve the already implemented hidden underground test route, its three-inscription puzzle, registration prerequisite, and physical transition into the lower passage. Do not make the entrance openly visible or directly accessible from the street.
- The concealed examination entrance is accessed from inside the Shopping and Commerce Tower restaurant, using an original secret restaurant interaction inspired by the idea of a hidden Hunter exam entrance. The player must discover the correct restaurant clue/interaction; the existing three-inscription riddle and Hunter Association registration prerequisite remain mandatory. The restaurant is the concealed access point, not a replacement for the puzzle or registration.
- The inspiration is the feeling of a secret entrance/examination in a hunter adventure story, not a reproduction of an anime scene, dialogue, characters, or exact mechanism. Keep SYSTEM's own story, puzzle, and implementation.
- Once unlocked, preserve the actual physical entrance and passage transition; do not replace it with a text-only message.

## Canonical layout correction — user-confirmed 24 November 2026

This section supersedes any older wording in this file or related design notes that conflicts with it:

- Exactly five connected Baghdad towers form one elevated city district: Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation.
- The Hunter Association Tower is the central tallest tower above the Baghdad upper city, physically seated on the uppermost circular sky platform (platform surface 419.2 m). Its geographic center remains aligned with the verified Republic Bridge/Tigris reference below. The tower replaces the former decorative central S-spire and carries the XSX guild emblem on all four exterior faces. Its helipad is above the tower, and advertising facades face both inward toward the elevated city and outward toward Baghdad.
- The Hunter examination tunnel is below the district, but its concealed player entry is inside the Shopping Tower restaurant. Keep the ordered three-inscription puzzle, registration gate, physical descent, and seven-stage exam.
- Shopping/Commerce retains the already-developed weapons, armor, modern armored outfits, elixirs including Nen awakening/control/recovery types, skill manuals/marketplace, restaurants, hotel services, and other existing departments. Entertainment retains pools and sports/recreation facilities.
- The Power Tower is a separate standalone destination away from this district and is not part of the five towers.

## Scope and implementation discipline
- This file records the complete approved design scope; it is not proof that every item is already implemented.
- Before changing runtime code, inspect current branch/commit and the existing tower scripts, scenes, vendors, test scripts, and checkpoint. Identify what is already complete and list only missing pieces.
- Implement missing parts incrementally on `feature/baghdad-five-plus-power-tower-20261122` and its existing draft PR #38. Never merge to `main` without explicit user approval.
- Add functional tests for helipad access/arrival, specialist shop catalogues and purchases, equipment compatibility, elixir/skill prerequisites, and the hidden examination entrance conditions.
- Do not report Baghdad Towers complete until all relevant Godot operation tests pass and the Android export/artifact workflow succeeds.
