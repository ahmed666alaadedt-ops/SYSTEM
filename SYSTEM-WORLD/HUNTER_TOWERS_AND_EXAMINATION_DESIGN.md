# SYSTEM WORLD — Hunter Towers and Global Hunter Examination

## Canonical design

Baghdad has **five connected district towers plus one separate Power Tower**. The five connected towers are Hunter Association, Weapons, Equipment and Elixirs, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation. The Power Tower is a separate destination, is not counted among those five, and must not join their skybridge or vehicle-deck loop.

The World Hunter Association Tower is the global Hunter headquarters and public symbol of the organization. It remains the tallest tower in the five-tower district (approximately 1,000 m in the current blockout). The separate Power Tower is a 200-floor challenge destination with its own entrance, progression, arenas, spectator facilities, and rewards. Its current exterior blockout is approximately 820 m tall with 200 visible floor bands, keeping the Hunter headquarters taller.

The Hunter examination is a separate seven-stage global qualification journey. It is not the Power Tower and cannot be substituted by clearing Power Tower floors.

## Current source implementation

- `scripts/baghdad_tower_landmarks_manager.gd` builds the five connected district towers plus the separate Power Tower, resolves foundations to nearby land where possible, and excludes Power Tower from the five-tower connection loop.
- `scripts/system_tower_entrance.gd` provides a ray-interactable entrance marker for each tower.
- `scripts/modern_world_region_manager.gd` creates the tower manager and registers both landmarks in the existing modern-world map manager as `LocationType.LANDMARK` (enum value 5).
- `scripts/system_hunter_exam_manager.gd` defines a seven-stage examination, candidate numbering, registration, sequential progression, save-state fields, and completion/failure signals.
- `scripts/system_power_tower_manager.gd` defines a separate 200-floor progression track, level requirements, boss/elite floor cadence, rank bands, clear-time records, and XP reward events. `scripts/main.gd` connects its floor-clear reward event to the existing player progression.
- `scripts/hunter_guild_menu.gd` adds registration and start controls.
- `scripts/main.gd` creates the examination manager and connects the guild menu signals.

## Landmark architecture expansion — 20 November 2026

- The shared tower shell now adds four monumental facade fins, three stepped podium terraces, and an illuminated crown ring.
- The Power Tower exterior now has four tournament/champion display blades and three concentric arena terraces at its base, reinforcing its identity as a public combat venue.
- The Hunter Association Tower exterior now has two monumental association wings, a Hall of Honor display, and a crown spire.
- These are procedural architectural blockout elements, not final high-detail art assets. The champion boards currently display static titles; they are not yet connected to live player rankings or verified gate-clearing records.
- The Power Tower's 200-floor progression manager remains separate from the exterior. The arena terraces do not yet constitute explorable interior arenas. A later interior-scene milestone must provide multiple distinct arenas (duel, team combat, survival, boss trial, and ranked championship), spectator galleries, training halls, matchmaking, and verified reward/record flows.
- The Hunter Association interior likewise still needs navigable reception, registration, mission hall, examination administration, training, research, medical support, meeting rooms, and a dynamically updated global hunter honor gallery.

## Power Tower arena progression data

The 200-floor progression now assigns a distinct challenge profile by floor cycle:
- Duel arena: one-on-one combat.
- Team battle arena: multi-opponent/team encounter.
- Survival arena: escalating waves.
- Elite gauntlet: successive stronger opponents.
- Championship arena: timed ranked sequence.
- Every tenth floor overrides the cycle with a boss-trial profile.

Floor data now exposes arena type/name, Arabic rules text, opponent count, wave count, and whether the result is marked for ranked treatment. This is progression metadata only: no arena interior scene, opponent spawning, team matchmaking, wave director, or server-verified ranking has been implemented yet.

## Seven-stage Hunter Examination

The examination is a difficult, multi-city journey. It tests judgment, observation, navigation, teamwork, survival, and combat restraint—not only damage output.

| Stage | Location | Core challenge |
|---|---|---|
| 1 | Baghdad — Mesopotamian heritage site | Recover the correct artifact, interpret inscriptions, identify false clues, and avoid traps |
| 2 | Cairo — buried market | Navigate a layered maze with shifting routes, limited supplies, and misleading signs |
| 3 | Alexandria — lighthouse and coast | Navigate a storm, restore signal mechanisms, and rescue separated candidates |
| 4 | Paris — catacombs | Solve sound and logic puzzles while moving quietly through monitored passages |
| 5 | Babylon — ancient ruins | Read the guardian mechanism and survive a high-risk guardian trial |
| 6 | Tokyo — urban districts | Complete a changing pursuit and observation course without endangering civilians |
| 7 | Highland frontier | Complete a long survival and teamwork route under harsh weather and resource pressure |

The design can include candidate-number competition and controlled attempts to obtain another candidate's number in a dedicated later stage. Any such mechanic must have clear rules, prevent permanent account theft, and be judged as part of the examination rather than as an unrestricted griefing feature.

## Candidate numbering and persistence

- Registration allocates a sequential candidate number beginning at 1001.
- The candidate number is saved locally with the current registration record.
- Completed stage IDs and examination state are written to `user://system_hunter_exam.cfg`.
- Stage order is enforced by the manager.
- A provisional license signal is emitted only after all seven stage IDs have been completed.

## Important implementation boundary

The current work creates the procedural tower blockouts, entrance interaction markers, menu registration/start controls, and the examination progression data manager. It does **not** yet create the explorable interior floors, the seven physical stage environments, the actual maze geometry, puzzle devices, guardian AI encounters, city-to-city travel sequences, server-authoritative candidate verification, anti-cheat checks, or a production Hunter-license card. The entrance currently reports an interaction; it does not yet load a tower interior scene.

The Power Tower now has a separate 200-floor progression manager with unlock order, level gates, boss/elite classification, rank bands, saved highest-floor and clear-time records, and a reward signal connected to player XP. Actual combat encounters, floor scenes, opponent AI, rankings, and a trusted combat-verification caller remain to be implemented.

The stage completion method is an integration hook for a future trusted objective-verification system. A non-empty evidence string is not sufficient security for an online competitive game. Before live multiplayer, completion and candidate-number records must be validated by an authoritative server.

## Production sequence

1. Build and validate the tower blockouts and land placement in Godot.
2. Create separate interior scenes for the Hunter Association headquarters and Power Tower.
3. Build each examination stage as a playable environment with objective triggers, puzzles, traps, navigation, NPC candidates, and safe failure/retry rules.
4. Connect travel transitions between the modern and historical city maps.
5. Add official license/card issuance, Hunter ranks, examination records, and rewards to the existing player/account progression systems.
6. Add server-side candidate numbering, stage verification, anti-cheat, and multiplayer synchronization.
7. Add cinematic art, character animations, environmental audio, and mobile performance/LOD passes.

## Verification boundary

GitHub writes and source-level connections are confirmed for this update. No Godot parser, editor import, runtime scene, Android build, multiplayer test, or visual inspection was performed in this session. The tower geometry and examination progression are prototypes, not a finished playable exam or completed tower experience.


## Baghdad Five-Tower Connected City — approved spatial direction — 20 November 2026

The five-tower concept is a connected urban district, not five isolated landmarks. Treat it as one continuous vertical city woven into central Baghdad and spanning the Karkh–Rusafa river corridor.

### Geographic placement and protected landmarks
- Place the district in central Baghdad between the Karkh and Rusafa banks of the Tigris, with major parts of the complex on both sides of the river.
- The Tigris must remain visibly flowing beneath and through the composition as a real open river corridor. Do not roof over, fill, or visually hide the river.
- Preserve the Tigris waterfront, river navigation corridor, riverbanks, and the legibility of the two historic sides of Baghdad.
- Tahrir Square (Sahat al-Tahrir) is a mandatory protected landmark on the Rusafa side. Preserve the square's recognizable open public-space identity and the Freedom Monument; do not replace, bury, cover, or visually overwhelm either landmark with tower podiums or elevated structures.
- Integrate the five-tower district with the existing city fabric and roads rather than treating it as a detached island or replacing central Baghdad.

### Connected-city form
- The five towers remain five distinct primary towers, each with its own silhouette and identity, but are joined into one coherent complex by elevated skybridges, multi-level pedestrian promenades, public terraces, and carefully placed cross-river connections.
- Connections must create a walkable network across the Karkh and Rusafa sides while keeping the Tigris open below. River-crossing links should be elegant bridges or high-level connectors with clear navigation clearance; do not place solid building masses across the river.
- Build a multi-level urban experience: ground-level public streets and plazas; mid-level retail, services, and indoor promenades; upper-level sky gardens, recreation decks, and observation spaces.
- The five rooftops and podium terraces should connect into large shared gardens and entertainment districts, with some independent zones for each tower. Include parks, restaurants, cafes, pools, sports courts, event plazas, viewing decks, and family recreation areas.
- Provide clear public routes, emergency/service access, transit connections, accessible paths, and wayfinding. The complex must feel like a functioning city district, not only a decorative mega-structure.

### Five tower identities
1. Hunter Association Tower — hunter registration, mission hall, examination administration, guild services, and Hall of Honor.
2. Weapons, Equipment and Elixirs Tower — all weapon classes, swords, spears, axes, bows, firearms, shields, helmets, armor, combat outfits, equipment upgrades, Nen-acquisition and Nen-development elixirs, healing elixirs, and strength, speed, endurance, and energy elixirs.
3. Shopping and Commerce Tower — connected malls, shops, restaurants, cinemas, and indoor public promenades.
4. Entertainment and Sports Tower — amusement, sports, pools, family activities, festivals, and recreation.
5. Technology and Innovation Tower — research campuses, laboratories, robotics, engineering, digital services, startup incubators, and technology exhibitions.

The Power Tower is a standalone 200-floor challenge destination outside the five-tower district. It has its own map marker and entrance and must never be linked into the five-tower skybridge/vehicle-deck network.

### Visual and gameplay rules
- From multiple city viewpoints, the player should be able to recognize the five-tower skyline as one connected Baghdad landmark, while still distinguishing all five towers.
- Ground-level views must preserve meaningful views toward the Tigris and the Freedom Monument/Tahrir Square. Use setbacks, view corridors, and controlled tower heights/placement to avoid hiding protected landmarks.
- The riverfront and Tahrir Square remain explorable public spaces with their own activities; they are not merely scenery around the towers.
- Do not claim the real Baghdad skyline or landmarks have been physically altered. This is the fictional future version of Baghdad inside SYSTEM WORLD.
- This section establishes the approved design direction only. It does not mean the complete district, bridges, interiors, or river engineering are already implemented in Godot.


### Vehicle circulation, comfort, and recreation expansion — 20 November 2026
- The district is intended to support cars entering from Baghdad streets, climbing dedicated ramps, crossing elevated vehicle decks, and reaching tower parking/drop-off levels. Separate pedestrian promenades and sky gardens keep walking routes safe and pleasant.
- The five connected identities are Hunter Association, Weapons/Equipment/Elixirs, Shopping/Commerce, Entertainment/Sports, and Technology/Innovation. The former Business and Investment Tower was replaced by the Weapons, Equipment and Elixirs Tower on 22 November 2026. The Power Tower remains a standalone destination outside the five-tower skybridge/vehicle-deck network.
- The connected district's eventual facilities include hotels, rest areas, clinics/medical support, restaurants, cafes, retail, cinemas, amusement rides, water attractions, swimming pools, rooftop gardens, sports courts, family spaces, public plazas, parking, emergency access, and service routes.
- The vehicle ramps and elevated decks added to the procedural manager are architectural blockout geometry only. They do not yet provide drivable road navigation, vehicle physics, traffic rules, parking interactions, or tested collision/clearance.
- Amenity decks are placeholder geometry and metadata, not finished pools, rides, shops, hotels, or interactive interiors.
- The Tigris river channel and navigation corridor must remain open below cross-river connections. Tahrir Square and the Freedom Monument remain protected, recognizable, explorable landmarks; no tower deck or bridge may cover or visually erase them.


## Baghdad tower identity architecture pass — 22 November 2026

- Add distinct procedural exterior identity details to the five connected towers: Hunter Association wings and Hall of Honor frame; crossed-blade armoury insignia and equipment display plinths; stepped retail gallery rings; entertainment arena bowl and event screen; technology antennae and innovation ribbon.
- Preserve the Power Tower as a separate landmark with tournament blades and a champion crown ring; it is not part of the five-tower connection loop.
- Store floor count, approximate height and connected-district membership as tower metadata for later directory/elevator integration.
- These identity structures remain procedural blockout geometry. They do not create finished interiors, elevators, shops, equipment inventories, elixir crafting, or playable arena floors.

## Tower entrance directory data — 22 November 2026

Every Baghdad tower entrance exposes its configured floor count, approximate exterior height, and whether it belongs to the connected district. Interacting with a tower displays a short Arabic directory for its planned departments. This is an information directory only; it does not create an explorable floor, elevator ride, or interior scene.

## Public lobby pavilion prototype — 22 November 2026

Each Baghdad tower landmark now creates an open ground-level lobby pavilion outside the tower shaft collision, with a collidable floor, canopy, four support columns, a directory kiosk and a tower-name sign. The kiosk is ray-interactable and shows the tower's Arabic department directory. These are first-pass blockouts only; reception staff, finished interiors, elevator cars, floor scenes and real vertical travel are not yet implemented.

## Floor zoning and public lobby directory — 22 November 2026

The five connected towers and the separate Power Tower now carry explicit floor-range/department zoning data. The Weapons, Equipment and Elixirs Tower reserves its uppermost floor for restricted rare/legendary elixir storage and places Nen research, healing, equipment upgrading, armour and weapon departments on separate floor ranges. Each tower's lobby directory sign displays its own floor zoning. These are design metadata and exterior/lobby blockouts, not completed explorable floors, shops, staffed reception, or elevator gameplay.

## Enclosed tower lobby and lift-core shell — 22 November 2026

The six tower landmarks now generate an enclosed ground-level lobby blockout with side walls, split front and rear walls, a clear front entrance, a reception counter, security-gate frame, directory kiosk, floor zoning sign, and a closed visual lift-core door. The lift door is deliberately non-functional and collidable until a real shaft opening, elevator car, floor scenes, and safe arrival/exit transitions are implemented.

## Automated Baghdad tower validation and land-placement correction — 22 November 2026

A dedicated Godot validation script now instantiates the canonical main scene and checks all six tower landmark IDs, exactly five connected district members, standalone 200-floor Power Tower, lobby floor/reception/lift-door collision blockouts, directory signs and interactable kiosks, floor-zoning metadata, Weapons/Elixirs categories, and Technology public display mapping. The first run found that the Shopping Tower's requested plot was on water; the tower manager now searches a wider local radius and places it on nearby land. The rerun passed in GitHub Actions run 45035977040. The Shopping Tower's 264 m relocation still needs visual review against the intended Baghdad district footprint and protected landmarks.

## Android build evidence — 22 November 2026

The canonical SYSTEM WORLD Android APK export and artifact upload passed in GitHub Actions run 45035977001 for the Baghdad tower changes. This confirms the project can be exported to an APK; the generated build still requires installation and visual/gameplay/performance inspection on a physical Android device.


## Baghdad tower operations and NPC-managed services — 22 November 2026

The first runtime operations layer now connects the six tower lobbies to the existing civilian NPC society.

- Four adult NPC employees are assigned to each tower: three tower-specific service roles and one dedicated advertising manager. Their identities, occupations and employer/location fields are stored through the existing society records. They remain civilian employees and do not perform player missions, puzzles or combat.
- Lobby employees are visible and ray-interactable. Their service panel exposes tower-specific inventory catalogs and purchase/sale actions.
- The initial local wallet is saved separately from progression. Purchases add items to the existing player inventory; selling removes owned inventory quantities and credits the local wallet. This is a prototype economy only: no online trading, server authority, anti-duplication or real-money value is claimed.
- Each tower receives internal lobby campaign text and an external tower campaign display. A tower's advertising NPC is named on the rotating local campaign. These are in-world demo campaigns, not paid external advertising or an ad-network integration.
- Floor rooms are generated on demand inside each tower's shell. The first pass supplies floor collision, perimeter barriers, department signs, service kiosks and an elevator transition. Previously visited active rooms are unloaded when moving to another floor to control mobile scene cost.
- The first-pass rooms are procedural reusable interiors, not individually authored final environments. Department activities, furnishing interactions, crafting, equipment equipping and elixir effects remain future work.

## Power Tower first playable combat loop — 22 November 2026

- The existing progression manager remains the source of truth for sequential 200-floor access, level gates, boss cadence, rank bands, saved clear records and XP values.
- The tower operations manager now creates the requested floor room and spawns combat opponents from the floor's opponent/wave data. The reusable opponent actor pursues the player, attacks at close range, accepts damage from the modern combat raycast and emits a defeat signal.
- Clearing an entire wave advances to the next wave. Clearing the final wave calls the existing floor-clear confirmation hook, which records time/rank and grants XP through the main scene's existing reward connection.
- Every tenth floor is a boss trial; boss actors receive a larger health/damage profile and a first-pass boss arena platform. Duel, team, survival, elite, championship and boss-trial profiles receive different procedural obstacle layouts.
- If the player is wounded during a Power Tower run, the active attempt is abandoned without a clear reward and the player is returned to the tower lobby.
- The 200th floor is configured as a boss trial and can be generated by the same on-demand floor system.
- This is a first playable vertical slice, not a finished competitive tower: no authoritative multiplayer, matchmaking, anti-cheat combat verification, live online rankings, spectator systems, individually handcrafted 200 arenas, or production balance pass is claimed. Physical Android gameplay/performance inspection remains required.


## Elevator cabin and Power Tower final sovereign trial — 22 November 2026

- The lobby floor selector now uses a visible elevator cabin with a floor, roof, side glazing, sliding doors and an animated vertical transition for both the player and cabin.
- The elevator marker on an interior floor reopens the floor selector, allowing another floor to be selected or a return to the lobby. The active generated floor is unloaded after the player exits to the lobby.
- Power Tower floor 200 is now the unique FINAL_BOSS / SYSTEM SOVEREIGN trial. Its boss uses a larger gold visual, a higher health profile, and a periodic shockwave attack; its arena has a larger central boss platform.
- Power Tower rewards now include routine tokens, milestone fragments, boss cores and the unique sovereign crown/core reward for floor 200.
- The final floor's level gate is 90, so it remains reachable within the existing 100-level progression cap.
- These are procedural gameplay foundations. Final boss animation/telegraph phases, authored arena environments, balance testing, multiplayer matchmaking, server-authoritative ranking and physical Android inspection remain open.


## Equipment, elixir and Nen service behavior — 22 November 2026

The Weapons/Equipment/Elixirs Tower employee panel now exposes first-pass functional progression effects:

- Owned weapons can be equipped in a weapon slot. Swords, spear, axe, bow and modern firearm items apply their configured damage bonuses to light/heavy combat hitscan attacks.
- Shields, armour and helmets apply bounded defense bonuses to incoming combat damage. Outfits have a dedicated slot; visible 3D attachment models and weapon-specific animations remain future work.
- Strength elixir adds damage for 120 seconds; speed elixir increases movement for 120 seconds; endurance elixir adds defense for 120 seconds; energy elixir reduces attack cooldown for 120 seconds; rare/legendary elixir applies a stronger combined effect for 180 seconds.
- Healing elixir restores 30 combat health in the field but intentionally does not clear the persistent wound flag. Full recovery still requires the hospital treatment system.
- Nen acquisition elixir unlocks Nen and starts control rank 1. Nen control elixirs advance the rank up to 5. This stores progression state only; actual Nen aura techniques, personalized abilities and skill trees remain future work.
- Equipped items cannot be sold until unequipped. Equipment slots, Nen state and active effects are included in progression save data.
- All current prices/effects are first-pass local balance values. Crafting, recipe discovery, stock supply chains, online transaction authority and final gameplay balance remain open.


## NPC vendor economy, crafting and Power Tower final challenge — 22 November 2026

- Vendor stock is saved locally per product. Purchases reduce stock; sales return accepted items to the NPC vendor's stock. Prices respond to stock levels, and vendors restock every five real-time minutes.
- The Weapons Tower first floor now contains an interactive blacksmith forge and elixir laboratory, each connected to the assigned NPC employee service.
- NPC staff panels expose recipes and ingredient counts. Players can buy raw materials and craft weapons, shields, armour, helmets, outfits and core elixirs. Nen-control and rare/legendary recipes have level/Nen requirements.
- Power Tower milestones and bosses provide crafting materials; the 200th-floor sovereign trial grants the unique crown, sovereign core, rare core and Nen fragment, plus a large SYSTEM credit reward.
- All six lobby lift doors and generated public-floor service kiosks are interactive. The Power Tower lobby includes a local 200-floor progress board.
- Final boss combat now includes a visible shockwave warning and three phases at 50% and 20% health thresholds.
- The stock, wallet, progression and Power Tower records are local-device systems at this stage. Online transaction authority, cloud synchronization, cross-player leaderboards, matchmaking, visible equipment attachments, full Nen abilities and physical Android review remain unfinished.


## Power Tower survival and championship objectives — 22 November 2026

- Survival arena floors use a timed survival objective (50–120 seconds based on floor progression) with sequential enemy waves. Defeating the final wave early does not finish the floor; the player must survive until the timer ends.
- Championship arena floors use a timed clear objective (110–200 seconds). All waves must be defeated before time expires; failure abandons the attempt and keeps the same floor available for retry.
- Each arena shows its objective and live countdown on a 3D display. The challenge timer begins after the elevator reaches the arena, not while the player is travelling.
- The Godot validator now iterates all 200 floor profiles and checks level gates, boss cadence, opponent/wave data, rewards and survival/championship objective timing.


The Power Tower lobby board also shows the player's highest cleared floor, next floor, progression rank, completion percentage and personal best clear time. This is a local personal record; global online rankings remain a future server-backed feature.
