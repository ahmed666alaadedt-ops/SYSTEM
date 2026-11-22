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
- `scripts/system_power_tower_manager.gd` defines a separate 100-floor progression track, level requirements, boss/elite floor cadence, rank bands, clear-time records, and XP reward events. `scripts/main.gd` connects its floor-clear reward event to the existing player progression.
- `scripts/hunter_guild_menu.gd` adds registration and start controls.
- `scripts/main.gd` creates the examination manager and connects the guild menu signals.

## Landmark architecture expansion — 20 November 2026

- The shared tower shell now adds four monumental facade fins, three stepped podium terraces, and an illuminated crown ring.
- The Power Tower exterior now has four tournament/champion display blades and three concentric arena terraces at its base, reinforcing its identity as a public combat venue.
- The Hunter Association Tower exterior now has two monumental association wings, a Hall of Honor display, and a crown spire.
- These are procedural architectural blockout elements, not final high-detail art assets. The champion boards currently display static titles; they are not yet connected to live player rankings or verified gate-clearing records.
- The Power Tower's 100-floor progression manager remains separate from the exterior. The arena terraces do not yet constitute explorable interior arenas. A later interior-scene milestone must provide multiple distinct arenas (duel, team combat, survival, boss trial, and ranked championship), spectator galleries, training halls, matchmaking, and verified reward/record flows.
- The Hunter Association interior likewise still needs navigable reception, registration, mission hall, examination administration, training, research, medical support, meeting rooms, and a dynamically updated global hunter honor gallery.

## Power Tower arena progression data

The 100-floor progression now assigns a distinct challenge profile by floor cycle:
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

The Power Tower now has a separate 100-floor progression manager with unlock order, level gates, boss/elite classification, rank bands, saved highest-floor and clear-time records, and a reward signal connected to player XP. Actual combat encounters, floor scenes, opponent AI, rankings, and a trusted combat-verification caller remain to be implemented.

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


## Canonical correction — Baghdad five towers versus the separate Power Tower — 22 November 2026

The older five-tower list above is superseded where it conflicts with this correction:

1. Hunter Association Tower.
2. Business & Investment Tower.
3. Shopping & Commerce Tower.
4. Entertainment & Sports Tower.
5. Technology & Innovation Tower.

The Power Tower is a separate optional challenge landmark and is not one of the five connected Baghdad district towers. The Hunter Guild headquarters remains positioned above the five-tower complex as a distinct elevated headquarters feature. The five-tower district must be completed first; the separate Power Tower is the next work phase afterward. The current source update changes the five-tower build sequence and adds distinct procedural skyline identity features, but it remains a visual blockout until interiors, access, gameplay interactions, navigation, collision, and Godot/Android verification are completed.


## User-approved skyline image reference and expanded tower facilities — 22 November 2026

Use the user's uploaded futuristic Baghdad skyline image as the current visual reference for the connected five-tower district: five clearly identifiable primary towers integrated into one immense elevated city; broad layered sky platforms and curved podium decks; multiple sculptural structural supports; landscaped roof terraces; luminous blue glass and cyan lighting with restrained gold trim; a central tall SYSTEM emblem/spire; multi-level pedestrian and vehicle links; and a wide open river corridor with bridges and the Baghdad skyline visible beyond. Treat the image as a style/composition reference, not a literal replacement of Baghdad geography. Keep the Tigris open and navigable, preserve Karkh/Rusafa identity, and protect Tahrir Square and the Freedom Monument.

The current procedural source pass adds named visual blockout facility zones by tower: Hunter registration, mission hall, Hall of Honor and clinic; business headquarters, investment exchange, conference center and hotel; shopping atrium, food court, restaurant/cafe gallery and a six-hall cinema layout with 24 visual seat markers per hall; entertainment atrium, esports/arcade, live-events hall, bowling/VR markers, observation-wheel and sky-pool markers; technology research labs, robotics/AI, innovation expo and digital library. It also adds a central SYSTEM spire marker and three shared sky-garden terrace meshes.

Implementation boundary: these are visual blockout meshes, labels and metadata only. Cinema playback, seats as usable objects, shop transactions, hotel booking, rides, pools, sports activities, elevators, doors, NPC services, interior navigation, complete collisions, and the central sky-garden gameplay are not yet interactive or validated. Do not describe the five-tower district as finished until those are implemented and tested in Godot and on Android.


## Tower podium and accessible facility shell update — 22 November 2026

Each of the five towers receives a three-level public podium/arrival hall with visible cylindrical floor plates, static floor collision, glass-pillar markers, accent rings and a tower-specific arrival sign. Facility zones use open-front room shells rather than solid placeholder blocks: each shell has a floor plate and collision, left/right/rear walls, and a raised entrance lintel that leaves the front open. The cinema's six hall layouts also receive floor/collision markers.

These are still blockout structures, not finished interiors. Functional elevators, emergency stairs, floor selection, service NPCs, interior navigation, retail/hotel/food transactions, cinema playback/tickets and recreation interactions remain to be implemented and validated.


## Vertical transport and floor wayfinding visuals — 22 November 2026

All five tower roots now include a visual vertical-transport blockout: four panoramic lift shafts with cabin markers, two protected stair-core markers, and a floor directory. Directory markers appear every 10 floors in tall towers and every 5 floors in shorter towers. These structures are not functional elevators or traversable emergency stairs; movement, floor selection, navigation, access control and emergency routing remain outstanding.
