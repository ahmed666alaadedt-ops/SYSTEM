# SYSTEM WORLD — Hunter Towers and Global Hunter Examination

## Canonical design

The modern-world Baghdad region contains two distinct tower landmarks:

1. **World Hunter Association Tower** — the monumental headquarters and public symbol of the global Hunter organization. It is intended to be the tallest tower in the world. The current procedural blockout uses an approximate 1,000 m height and 200 visible floor bands.
2. **Power Tower** — a separate optional challenge arena for individual progression, ranked battles, increasingly difficult opponents, and rewards. The current procedural blockout uses an approximate 168 m height and 28 visible floor bands.

The towers are separate gameplay identities. The Power Tower is not the Hunter examination, and the Hunter examination is not a Power Tower floor run.

## Current source implementation

- `scripts/baghdad_tower_landmarks_manager.gd` builds both landmark silhouettes near Baghdad and resolves each requested foundation to nearby land where possible.
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
| 1 | Baghdad outskirts | Endurance pursuit, tracking checkpoints, resource control and civilian safety |
| 2 | Babylon frontier | Fieldcraft, ingredient gathering, knowledge checks and cooking |
| 3 | Baghdad examination tower | Multi-route tower, linked puzzles, decisions and team coordination |
| 4 | Island wilderness | Survival, water, food, shelter, weather and extraction |
| 5 | Freeport district | Strategy, evidence gathering, deception detection and negotiation |
| 6 | Hunter arena | Individual duels emphasizing control, defense and rule compliance |
| 7 | Classified SYSTEM location | A secret rotating final trial combining observation, judgment and cooperation |

The physical Baghdad association tunnel now displays seven numbered stage gates, a registration interaction, a public notice interaction and a start/resume interaction. These gates are a candidate-facing route and briefing blockout; they do not mean the seven remote challenge environments are already built.

The design can include candidate-number competition and controlled attempts to obtain another candidate's number in a dedicated later stage. Any such mechanic must have clear rules, prevent permanent account theft, and be judged as part of the examination rather than as an unrestricted griefing feature.

## Candidate numbering and persistence

- Registration allocates a sequential candidate number beginning at 1001.
- The candidate number is saved locally with the current registration record.
- Completed stage IDs and examination state are written to `user://system_hunter_exam.cfg`.
- Stage order is enforced by the manager.
- The manager enforces the seven-stage order and saves candidate identity, attempt number, completed stages, failure time and permanent-license state.
- A failed candidate may register for the next weekly examination cycle; the retry timestamp is exposed to the guild UI.
- The permanent `HUNTER_LICENSE` signal is emitted only after all seven stage IDs have been completed.

## Important implementation boundary

The current work creates the procedural tower blockouts, entrance interaction markers, menu registration/start controls, a seven-gate tunnel briefing route, and a persistent seven-stage examination progression manager. It does **not** yet create the explorable interior floors, the seven physical stage environments, the actual maze geometry, puzzle devices, guardian AI encounters, city-to-city travel sequences, server-authoritative candidate verification, anti-cheat checks, or a production Hunter-license card. The entrance currently reports an interaction; it does not yet load a tower interior scene.

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
1. Power Tower — combat arenas, training, tournaments, champion displays, and spectator facilities.
2. Hunter Association Tower — hunter registration, mission hall, examination administration, guild services, and Hall of Honor.
3. Business Tower — company headquarters, offices, investment, trade, and professional services.
4. Shopping Tower — connected malls, shops, restaurants, cinemas, and indoor public promenades.
5. Entertainment Tower — amusement, sports, pools, family activities, festivals, and recreation.

### Visual and gameplay rules
- From multiple city viewpoints, the player should be able to recognize the five-tower skyline as one connected Baghdad landmark, while still distinguishing all five towers.
- Ground-level views must preserve meaningful views toward the Tigris and the Freedom Monument/Tahrir Square. Use setbacks, view corridors, and controlled tower heights/placement to avoid hiding protected landmarks.
- The riverfront and Tahrir Square remain explorable public spaces with their own activities; they are not merely scenery around the towers.
- Do not claim the real Baghdad skyline or landmarks have been physically altered. This is the fictional future version of Baghdad inside SYSTEM WORLD.
- This section establishes the approved design direction only. It does not mean the complete district, bridges, interiors, or river engineering are already implemented in Godot.


### Vehicle circulation, comfort, and recreation expansion — 20 November 2026
- The district is intended to support cars entering from Baghdad streets, climbing dedicated ramps, crossing elevated vehicle decks, and reaching tower parking/drop-off levels. Separate pedestrian promenades and sky gardens keep walking routes safe and pleasant.
- The five primary identities are fixed within the five-tower composition: Power Tower, Hunter Association Tower, Business Tower, Shopping Tower, and Entertainment Tower. The Power Tower and Hunter Association Tower are full independent towers within the connected district, not extra towers perched on top of other buildings.
- The connected district's eventual facilities include hotels, rest areas, clinics/medical support, restaurants, cafes, retail, cinemas, amusement rides, water attractions, swimming pools, rooftop gardens, sports courts, family spaces, public plazas, parking, emergency access, and service routes.
- The vehicle ramps and elevated decks added to the procedural manager are architectural blockout geometry only. They do not yet provide drivable road navigation, vehicle physics, traffic rules, parking interactions, or tested collision/clearance.
- Amenity decks are placeholder geometry and metadata, not finished pools, rides, shops, hotels, or interactive interiors.
- The Tigris river channel and navigation corridor must remain open below cross-river connections. Tahrir Square and the Freedom Monument remain protected, recognizable, explorable landmarks; no tower deck or bridge may cover or visually erase them.


## Superseding canonical decision — independent Power Tower and five-tower district — 21 November 2026

This section supersedes any earlier tower-identity or spatial wording in this document that conflicts with the following approved decision. Earlier descriptions remain historical design notes only.

### The five connected district towers
1. Hunter Association Tower — the association's public-facing tower and guild services.
2. Business Tower — companies, offices, investment, trade, and professional services.
3. Shopping Tower / Weapon Armory & Nen Awakening — retail, restaurants, cinemas, weapon services, Nen awakening and control-potion services.
4. Entertainment Tower — sports, pools, family activities, festivals, and recreation.
5. Technology and Innovation Tower — research laboratories, engineering, robotics, AI, digital services, startup incubators, and public technology experiences.

The five towers form one connected Baghdad network, but they do not all sit on the same local ring. Hunter Association, Business, Entertainment, and Technology & Innovation remain the four core towers around the Baghdad sky-ring. The Shopping/Weapon-and-Nen Tower is the fifth primary tower and is positioned as an outpost above Republic Bridge, over the Tigris crossing between Al-Karkh and Al-Rusafa. A dedicated elevated express skyway links this outpost back to the four-core ring, and two separate access ramps reach it from the Karkh and Rusafa banks. The Power Tower is not one of the five and must never be included in their district loops.

### Global Hunter Association headquarters above the district
The main World Hunter Association headquarters is a distinct elevated headquarters building placed above the shared five-tower district. It is not located on top of Power Tower and is not counted as a sixth primary tower. The Hunter Association Tower remains one of the five district towers and provides the guild's public-facing tower identity; the elevated headquarters is the central global administration hub.

### Independent Power Tower
Power Tower remains a separate, optional combat-arena landmark at a clearly detached location in Baghdad. Preserve its existing 200-floor progression manager, floor unlocks, boss/elite cadence, challenge profiles, XP reward integration, and save data. Keep it independent of the five-tower complex physically and in connection generation. Its future playable interiors, opponent AI, matchmaking, ranked verification, and spectator facilities remain separate implementation milestones.

### Implementation and verification boundary
The source-level implementation now distinguishes the four-core sky-ring, the fifth Republic Bridge Shopping/Weapon-and-Nen outpost, and the independent Power Tower. The outpost relocation is conditional on the verified OSM manifest; its playable lobby/interior is retained, while the four core tower transforms remain unchanged. The OSM builder and verifier define the river cutout, bridge anchor, two bank approaches and land-only skyway support plan. Low municipal ground is surfaced at least 0.25 m above the global sea plane; the outer terrain blends over 600 m to a river-safe baseline of max(city-anchor height, 34.0 m), without changing the four core tower sites. Current-head Godot parser/runtime validation, live visual review, collision/navigation traversal and Android performance are still pending. Source elevations are game-world assumptions until a reliable DEM/survey is integrated.


### Headquarters vertical placement and access update — 21 November 2026

The Global Hunter Association headquarters must sit above the highest roofline among the five connected district towers, not at a fixed low elevation within the tower cluster. The current procedural blockout computes the highest district roof at runtime and positions the headquarters sky podium above it. A dedicated elevated access deck links the highest district tower roof to the headquarters platform; this bridge is separate from the five-tower pedestrian/vehicle connection loop. The headquarters is registered as its own map location and is no longer included in the five-tower landmark array or the public tower advertising-board loop.


## Power Tower — approved 200-floor progression update — 21 November 2026

The Power Tower progression target is now **200 floors**. This supersedes earlier 100-floor progression wording above.

### Floor regions
- Floors 1–20: Frontier Forests.
- Floors 21–40: Warrior Citadels.
- Floors 41–60: Beast Wilds.
- Floors 61–80: Shifting Labyrinths.
- Floors 81–100: Elite Proving Grounds.
- Floors 101–120: Elemental Frontiers.
- Floors 121–140: Lost Kingdoms.
- Floors 141–160: Giant Territories.
- Floors 161–180: Mythic Reaches.
- Floors 181–200: Apex Trials.

Every floor is described by runtime progression data as a large explorable region, with an environment profile, challenge type, arena rules, reward values, and three ordered checkpoint IDs. Every tenth floor is a boss trial; floor 200 is the final tower trial. These are data contracts and progression metadata; they do not prove that 200 unique explorable 3D maps or boss encounters have been built.

### Retry and rewards
- Entry is free.
- A player must clear floors in order and meet the floor's level requirement.
- Three ordered checkpoints are recorded per floor by the trusted objective controller.
- Defeat/abandonment clears the active attempt but preserves the last reached checkpoint; retry resumes from that checkpoint.
- A verified floor clear awards XP and local-only virtual Tower Credits. Credits are not cash, cannot be purchased for real money, and cannot be withdrawn.
- The existing `floor_cleared(floor_number, reward_xp, rank)` signal remains unchanged for compatibility. A new `floor_rewarded(reward_data)` signal carries the Tower Credits result.
- Current save data remains in `user://system_power_tower.cfg`; prior highest-floor and clear-time data are retained.

### Implementation boundary
The progression manager now supports 200-floor metadata, ten 20-floor region bands, 20 boss floors, ordered checkpoints, checkpoint-preserving retries, XP and Tower Credits rewards, and floor-unlock progression. A Godot headless validation script covers these contracts and is wired into the canonical Godot validation workflow. Physical checkpoint triggers, actual unique floor environments, opponent spawning/AI, live spectator crowds, multiplayer matchmaking, and authoritative online verification remain separate implementation work.


## Power Tower arena, crowd and spectator wagering — 21 November 2026

- Fighter registration/entry is free; the arena manager returns an entry fee of zero.
- Matches support SINGLE and TEAM categories at the manager contract level.
- The venue can receive 28 visible placeholder NPC spectators who sway as a lightweight crowd blockout. This is not final character art, full animation, or advanced crowd AI.
- NPC spectators can submit non-monetary predictions and trigger crowd-cheer events. They do not create currency or betting pools.
- Betting is spectator-only, uses local virtual SYSTEM Credits, has a 10-credit minimum and 1,000-credit ticket maximum, one local ticket per match, and disallows fighters betting on their own match.
- Betting closes before match start. A pari-mutuel pool is distributed proportionally to winning tickets; cancelled matches refund accepted stakes.
- Local prototype settlement uses the existing local vehicle wallet and is device-only. It is not a shared online wallet.
- Remote/player-to-player wagering remains disabled until authenticated server-authoritative multiplayer escrow, anti-cheat, dispute handling, and regional compliance exist. Real-money bets, purchases, cash-outs, and cash prizes are prohibited.
- Main scene now creates the arena manager, supplies the local wallet, and attaches it to the existing independent Power Tower venue when the player enters the tower.
- Validation covers free entry, fighter self-bet rejection, remote wager rejection, minimum bet, one-ticket rule, lock-before-start, pool payout conservation, NPC non-monetary predictions, and cancellation refunds.

- NPC crowd prediction now drives a lightweight cheering/sway response in the visible crowd blockout.
- If a match ends with no winning spectator tickets, accepted local virtual stakes are refunded rather than retained by the venue.


## Implementation checkpoint — Baghdad examination tunnel entrance — 22 November 2026

The Baghdad landmark tunnel now has a collision-backed floor, side walls and roof, ceiling lighting, a guide line, and seven numbered stage-gate frames. Its candidate entrance barrier starts closed and is opened only after the existing `HunterExamManager.begin_exam()` reports success; the main interaction resolves the access controller through the tunnel root's parent landmark manager. The integration validator exercises the closed → open → closed barrier state and verifies all seven numbered frames.

**Scope boundary:** the seven frames are currently physical stage markers, not completed challenge doors or challenge environments. Sequential stage progression, challenge-scene loading, trusted evidence verification, examiner operations, live traversal and Android visual review remain future work. Godot 4.3 workflow `45013118196` passed on code commit `cb14ed58fa84a8c5d9b37fc3a12661cb1281d638`.
