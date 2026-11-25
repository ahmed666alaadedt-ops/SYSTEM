# Baghdad Towers — Shopping Arsenal, Airfield, and Hunter Entrance
Status: approved design specification — 2026-11-24
Branch: `feature/baghdad-five-plus-power-tower-20261122`

## Canonical Baghdad layout
- Baghdad's connected vertical district has **exactly five towers**: Hunter Association, Business and Investment, Shopping and Commerce, Antiques and Heritage, and Technology and Innovation. They form one elevated urban district across the Karkh–Rusafa corridor.
- The Hunter Association Tower uses the verified Republic Bridge/Tigris coordinates as its geographic center, but its physical base stands on the uppermost circular Baghdad sky-city crown platform at 419.2 m above the local reference level. It is the tallest, central, functional tower above the four surrounding district towers; the Republic Bridge and Tigris remain visible and traversable below.
- The elevated city/district is a distinct, traversable urban layer integrated with the five towers; retain the river channel and bridge identity beneath/through the district.
- The Power Tower remains a separate, independent 200-floor challenge destination away from the Baghdad five-tower district. It is never counted among the five and never connected to their skybridge/transport loop.
- Preserve all existing tower interiors, jobs, NPCs, restaurant/hotel services, evacuation exits, and progression. Extend existing systems; do not replace completed work.
- Build the Hunter Association Tower's **uppermost rooftop helipad above the tower** with safe approach/landing clearance, a player-accessible arrival/departure interaction, and a working connection to the world's travel/transport system. It is gameplay infrastructure, not decorative scenery.
- The Hunter tower must have prominent internal-facing and external-facing advertising facades/screens integrated into its architecture; advertising surfaces must be visible from both the elevated city and the outside skyline.

## Public population, families and visitor density
- The five connected Baghdad towers must feel like busy, inhabited public destinations, not empty architectural shells.
- Maintain **100 visible customer/visitor NPCs in each tower (500 total)** across the Hunter Association, Business and Investment, Shopping and Commerce, Antiques and Heritage, and Technology and Innovation towers.
- Each tower's public population includes **20 children, 20 elderly visitors and 60 adults**, with distinct age-appropriate character models and varied appearances.
- Children are civilians, do not fight or enter the Hunter Examination as candidates, and remain linked to visible adult guardians/family groups while visiting.
- Children do not make independent purchases; their accompanying adult guardian handles family purchases.
- Visitors follow daily routines across lobby cafes, shopping/service areas, lounges and public spaces; two visitors may ride the elevator with the player to an active floor while the rest of the population remains present in the public lobby.
- Use visual/animation LOD for distant visitors to protect Android performance, while preserving the full nearby crowd around the player.
- The independent Power Tower is excluded from the 500-customer count and retains its separate challenge audience/staff systems.

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

## Hunter Association Tower and the single continuous examination tunnel
- The Hunter Association Tower is one of the five connected Baghdad district towers and is the central tallest tower above the upper city, aligned over Republic Bridge and the Tigris. Mayar is its president and presents verified Hunter Association awards at formal ceremonies.
- The active discovery and recruitment point is the Hunter Association Tower lobby. On arrival, the player receives a clear Arabic invitation to become a Hunter, with explicit accept/decline choices. Declining leaves registration unchanged and allows a later choice.
- After acceptance, the player follows the visible Hunter Guild guide. The guide escorts the player from the tower to the one permanent underground examination tunnel beneath the district.
- The candidate serial is allocated and saved only when the player reaches the tunnel. Re-entry reuses the same serial; no duplicate number is allocated.
- The examination is one continuous tunnel competition with three ordered physical checkpoints, 500 individually tracked background candidates and five named interactive rivals. Do not describe or implement it as a multi-stage journey.
- The Shopping and Commerce Tower restaurant keeps its independent ordering, dining, waiter and chef lifecycle. It is not the active examination entrance and must not be replaced by a hidden restaurant puzzle, meal gate, private room or restaurant elevator.
- Keep the tunnel concealed from ordinary street access and preserve the physical guide-led transfer; do not replace it with a text-only message.
- The inspiration is the broad feeling of a hunter qualification adventure, not a reproduction of any anime scene, dialogue, characters or exact mechanism. Keep SYSTEM's own story and implementation.

## Canonical layout correction — user-confirmed 25 November 2026

This section supersedes any older wording in this file or related design notes that conflicts with it:

- Exactly five connected Baghdad towers form one elevated city district: Hunter Association, Business and Investment, Shopping and Commerce, Antiques and Heritage, and Technology and Innovation.
- The Hunter Association Tower is the central tallest tower above the Baghdad upper city, physically seated on the uppermost circular sky platform (platform surface 419.2 m). Its geographic center remains aligned with the verified Republic Bridge/Tigris reference below. The tower replaces the former decorative central S-spire and carries the XSX guild emblem on all four exterior faces. Its helipad is above the tower, and advertising facades face both inward toward the elevated city and outward toward Baghdad.
- The Hunter examination tunnel is below the district. The approved player route starts with the Hunter Tower arrival invitation, accept/decline registration choice, and visible guild-guide escort to one continuous tunnel competition; allocate the persistent candidate serial only at tunnel arrival.
- Shopping/Commerce retains the already-developed weapons, armor, modern armored outfits, elixirs including Nen awakening/control/recovery types, skill manuals/marketplace, restaurants, hotel services, and other existing departments. Pools and sports/recreation remain independent public leisure facilities; they are not a sixth Baghdad tower and are not part of the Antiques and Heritage Tower.
- The Power Tower is a separate standalone destination away from this district and is not part of the five towers.

## Scope and implementation discipline
- This file records the complete approved design scope; it is not proof that every item is already implemented.
- Before changing runtime code, inspect current branch/commit and the existing tower scripts, scenes, vendors, test scripts, and checkpoint. Identify what is already complete and list only missing pieces.
- Implement missing parts incrementally on `feature/baghdad-five-plus-power-tower-20261122` and its existing draft PR #38. Never merge to `main` without explicit user approval.
- Add functional tests for helipad access/arrival, specialist shop catalogues and purchases, equipment compatibility, elixir/skill prerequisites, and the hidden examination entrance conditions.
- Do not report Baghdad Towers complete until all relevant Godot operation tests pass and the Android export/artifact workflow succeeds.


## Final canonical correction — 25 November 2026

This section is authoritative and supersedes any historical Entertainment/Sports tower wording in older project notes:

- The five connected Baghdad district towers are exactly: Hunter Association, Business and Investment, Shopping and Commerce, Antiques and Heritage, and Technology and Innovation.
- Antiques and Heritage Tower is the fourth tower. Its runtime ID is `antiques_heritage_tower_baghdad`, its scene node is `AntiquesHeritageTower`, and it has 34 floors.
- Swimming pools, gardens, sports, cinema, bowling, arcade and other leisure activities are independent public recreation facilities in the Baghdad district. They are not a separate tower and must not be counted among the five towers.
- The Power Tower is an independent 200-floor challenge destination and is never included in the five-tower count.
- The 500 public customers remain distributed as 100 in each of the five canonical towers; Power Tower spectators and staff are separate.
- The three sky gardens per tower belong to the five canonical towers (15 total); there are no Power Tower sky gardens in this district count.
- Keep this document as an approved scope specification, not a claim that every gameplay system is complete. Hotel cloud synchronization, live advertising-provider integration, production marketplace deployment/cross-device testing and physical Android QA remain separate release gates.
