
## City underworld exchange and faction contract board — 21 November 2026

- [x] Add an underworld-exchange service point to each generated city service registry, with the city identity attached to its interaction marker.
- [x] Add an Arabic in-world faction board showing each city's original factions, district, influence, heat, player standing and recorded rivals.
- [x] Add player contract issuance from the board for courier delivery, public evidence collection, district scouting and civilian-route protection.
- [x] Display the player's active/completed faction contracts by city and keep the NPC-completion restriction in the faction manager.
- [x] Extend faction and civic-venue validators to check the board UI and underworld-exchange service registration.
- [ ] Add actual hideout interiors, named gang NPCs, patrol/territory routines, recruitment, alliance negotiation, dynamic turf events and authored mission objectives.
- [ ] Replace local evidence tokens and local faction persistence with server-authoritative quest evidence, synchronized reputation and multiplayer-safe conflict rules.
- Note: the board issues player-owned contract records; objective world interactions and gang combat/territory gameplay are not yet fully implemented.


## Baghdad rare-antiquities bazaar — in-world player market UI integration — 21 November 2026

- [x] Initialize the rare-antiquities manager from the main game scene and connect it to the player's existing local SYSTEM Credits wallet.
- [x] Seed three NPC auction-house lots on first market initialization, each with a one-hour local bidding window.
- [x] Add an in-world Arabic market panel with open auction listings, rarity/current bid/time remaining, artifact catalogue, era and provenance notes, a player bid control, and the player's acquired-artifact list.
- [x] Open the market panel from the Baghdad rare-antiquities bazaar interaction marker; the panel is not exposed as a global shortcut.
- [x] Adapt the market panel to the mobile viewport and extend the validator to check the UI can open and that the public auction board is seeded.
- [ ] Add NPC seller personas, expert appraisal dialogue, museum loans/exhibitions, collection set bonuses, fraud investigations and evidence-based provenance verification.
- [ ] Add safe, server-authoritative ownership, escrow, bid clocks, transaction replay protection and account synchronization before any online trading.
- Note: auctions, balances and inventory are still local-device prototype data. No real-money purchases, withdrawals, or online marketplace are enabled.

# Baghdad landmark completion scope — authoritative priority — 21 November 2026

The immediate building-completion milestone is specifically the set of Baghdad landmarks and venues below. Do not divert the active workstream into unrelated gameplay systems or generic city-service buildings until these locations are ready for main-map integration.

## Required Baghdad landmarks and venues

- [ ] **Five connected Baghdad towers and shared district:** Hunter Association, Business, Shopping, Entertainment, and Technology & Innovation towers; complete recognizable exterior architecture, district connections, accessible entrances, tower-specific interiors, vertical circulation, collision/navigation, and map location registration.
- [ ] **Hunter Association headquarters:** retain its elevated position above the five-tower complex; finish the headquarters rooms, public services, examiner spaces, and the Hunter Examination tunnel connection. NPCs are examiners and staff, never exam candidates.
- [ ] **Independent Power Tower:** keep it detached from the five-tower complex; preserve the 200-floor design, and build the physical playable floor environments, entrance/lobby, vertical transition, checkpoints, and exploration spaces. The 200-floor progression data alone does not mean the 200 physical floors are built.
- [ ] **Football stadium:** complete the venue around the pitch with stands, access gates, concourses, locker rooms, officials/media spaces, lighting, spectator circulation, and playable match access.
- [ ] **Motorsport circuit:** complete the actual track venue, pit lane, garages, paddock, race control, grandstands, access gates, safety barriers, checkpoints, and player/vehicle access.
- [ ] **Hunter Examination tunnel:** finish the physical candidate arrival, registration, briefing, waiting, examiner control, stage gates, lighting, signage, and safe route into the examination. Candidates are players; NPCs operate and examine.
- [ ] **City advertising:** finish the physical billboards, tower facade displays, street screens, stadium displays, and public-result boards as visible city fixtures. Keep commercial live-ad integration disabled until its compliance requirements are met.
- [ ] **Rare antiques market and auction venue:** finish the exterior, stalls, indoor auction hall, appraisal rooms, secure display, seller/buyer access, and exploration/interactions.
- [ ] **Archaeological sites and historic ruins:** build distinct discoverable physical sites with researched visual identity, access paths, environmental storytelling, and map markers; do not treat a museum interior as a substitute for outdoor archaeological locations.
- [ ] **Mosques and churches:** finish distinct culturally respectful exteriors and interiors, courtyards/approaches, accessible entrances, visitor paths, lighting, and map markers.

## Integration gate

- [ ] Every listed landmark has finished-enough exterior and interior geometry for exploration, collision/navigation, entrance and exit flow, and a stable location ID.
- [ ] Add each completed site to the main world map and region streaming lifecycle only after its own validation passes.
- [ ] Validate all landmarks together in Godot before calling the Baghdad integration milestone complete.

**Status rule:** procedural meshes, metadata, first-pass blockouts, and source-level manager wiring are foundations only; they are not production-complete buildings or proof of playable map integration.

# Tower layout decision update — 21 November 2026

The current approved Baghdad layout supersedes older five-tower identity lists below: the connected district contains Hunter Association, Business, Shopping, Entertainment, and Technology & Innovation towers. Power Tower is a separate detached landmark and is excluded from all district connection loops. The Global Hunter Association headquarters is an elevated building above the shared district; it is not on Power Tower and is not counted as a sixth primary tower. Source changes are committed, but Godot/runtime/Android verification remains open.

# SYSTEM WORLD — Modern World Completion Tracker

This is the acceptance checklist for the modern-world map. The project must not be described as complete, and work must not move to the portal phase, until every required item is implemented, connected, and verified in Godot on the target platforms. A visual placeholder is not accepted as a completed gameplay system.

## Current verified repository foundations

- [x] Fourteen city labels and eight district labels per city are defined in modern_world_region_manager.gd; only Baghdad is currently connected to the provisional WGS84 registry anchor, while the other thirteen centers remain prototype-layout coordinates.
- [x] Each city style index generates a distinct original civic landmark silhouette to improve skyline and local identity.
- [x] Ten rural settlement seeds are defined.
- [x] City road strips, plaza markers, green-belt markers, airport/rail visual hubs, and map discovery registration exist.
- [x] Baghdad tower landmarks are created by the region manager.\n- [x] Tower exteriors now include stepped podiums, facade fins and illuminated crowns; the Power Tower adds tournament display blades and concentric arena terraces, while the Hunter Association Tower adds monumental wings and a Hall of Honor display. These remain architectural blockouts; interior arenas, live champion data and playable headquarters rooms are not complete.\n- [x] Power Tower's 200-floor data model now cycles through duel, team, survival, elite-gauntlet and championship challenge profiles, with every tenth floor assigned a boss trial. This is challenge metadata; spawning, playable arena rooms, matchmaking and server-verified rankings remain open.
- [x] City road-tunnel visual prototypes are generated where terrain sampling finds a continuous, sufficiently level land alignment; rejected sites are skipped.
- [x] Rural village anchors are retained and first-pass access-road meshes are generated when a continuous all-land route to a city is found.
- [x] Every resolved district receives batched visual road-grid, sidewalk, and pedestrian-crossing meshes.
- [x] Land-valid city race-circuit prototypes receive outer safety-barrier geometry, curb strips, a start/finish gantry, pit-garage block, and grandstand tiers.
- [x] Airport visual prototypes include passenger halls, terminal wings, apron markings, and control towers.
- [x] Rail visual prototypes include passenger platforms, canopies, concourses, and departure signage.
- [x] Harbor visual prototypes include cargo warehouses, loading aprons, and freight-container yards.
- [x] Terrain-checked access-road meshes are attempted for airports, stations, and harbors; water-crossing candidates are skipped.
- [x] Accepted bridge spans receive visual side railings and marker lights.
- [x] Inter-city corridor prototypes include dashed center and lane-edge markings.
- [x] Generated inter-city highway surfaces now have matching static triangle-mesh collision bodies; this is a source-level implementation and still needs Godot runtime/Android driving-surface validation.
- [x] Generated inter-city corridor segments attempt roadside rest-stop scenery with market, fuel canopy, EV chargers and parking markings on adjacent land.
- [x] City centers attempt elevated boulevard flyover prototypes with ramps, barriers, lane markings and support piers when the alignment remains on land.
- [x] Harbor prototypes receive a waterfront promenade with benches, bollards and signage.
- [x] Procedural city street fixtures now cover the generated boulevard and ring-road corridors, with plaza lantern fixtures.
- [x] A capped pool of 24 shadowless dynamic lights is moved to the nearest street fixtures around the player; fixture meshes use emissive materials.
- [x] Ambient traffic catalog now contains eight visual archetypes per resolved city, up to 112 vehicles for fourteen cities.
- [x] Existing day/night, sky/weather, ambience, terrain, water, forest, mountain, marine, and wildlife managers remain in the project.
- [ ] None of the above has been confirmed by a Godot runtime or Android visual/performance test in this work session.

## City and district completion gates

- [x] Acquire and verify a current BBBike/OSM Iraq snapshot, extract Baghdad Municipality relation 5638803, and export eight boundary-clipped GeoJSON layers with source checksum, ODbL attribution and feature counts (workflow run 44697711925; artifact 14610809943).
- [ ] Complete official-boundary comparison, source-coverage review, road topology/turn connectivity checks, district-boundary sourcing and elevation-data acquisition; only then approve the Baghdad data pack for production use.
- [ ] Extend the WGS84 registry and region projection pipeline to each additional city only when its approved geographic data pack is available; do not promote prototype coordinates to real locations.
- [ ] Replace the 2.24 km × 1.58 km procedural continent prototype with a streamed real-scale region architecture before loading the approximately 36.0 km × 34.1 km Baghdad municipal area.
- [ ] Validate 1 km region-cell streaming, cross-cell roads/water, LOD, collision/navigation streaming, memory and frame-time budgets on Android.
- [ ] Replace generic block clusters with distinctive city architecture, skyline silhouettes, landmarks, local street furniture, signage, vegetation, and cultural details.
- [ ] Build connected, navigable street grids inside every district, including sidewalks, crossings, curbs, intersections, traffic islands, signs, barriers, and collision.
- [x] Add first-pass discoverable service-location definitions for hospitals, police/fire stations, hotels, markets, garages, schools, universities, football stadiums, shopping streets, restaurants, banks, malls, pharmacies, bakeries, cafes, fuel/charging stations, public parks, bus stations, post offices, libraries, rail stations, harbor terminals, cinemas, and fitness centers.
- [x] Add discoverable mosque, church, city history museum, and rare-antiquities bazaar service definitions; the active city's first-pass exteriors include a mosque dome/minarets, church nave/bell towers, museum portico, and ten antique-stall placeholders.
- [x] Add a local city-faction registry with three original faction roles per generated city, district/influence/heat metadata, player standing, incident history, and explicit exclusion of hospitals, schools, universities, mosques, churches and child-safe spaces.
- [ ] Complete worship-venue and museum interiors, culturally researched city-specific architecture, schedules, exhibits, accessibility and full visit interactions.
- [ ] Implement the rare-antiquities bazaar catalogue, provenance, appraisal, NPC dealers, auctions, inventory transfers, fraud investigation and save/load transaction ledger.
- [ ] Connect faction records to authored NPC members, territory encounter schedules, mission boards, evidence-led investigations, legal consequences and server-authoritative multiplayer persistence.\n- [ ] Turn these service-location prototypes into fully functioning interiors, jobs, inventories, transactions, medical/legal services, public transport schedules, and interactive recreation.
- [ ] Add residents, pedestrians, vendors, workers, schedules, crowds, public services, and city activity that responds to time and weather.
- [ ] Make the ten rural settlements functional and connect them to roads, services, farms, orchards, fields, and local economies.




## Baghdad worship and museum interior blockout pass — 21 November 2026

- [x] Add first-pass interior floor and spatial props to mosque, church, city museum and rare-antiquities bazaar service buildings.
- [x] Add mosque prayer-row carpet and column placeholders; church nave pews, altar and stained-glass placeholder; museum display pedestals/cases; bazaar display cabinets.
- [x] Remove the solid full-building collision shell for these four interior blockouts so the spaces can be entered during the prototype phase.
- [ ] Replace pass-through placeholder shells with proper door openings, wall/roof collision, accessibility, navigation, lighting, acoustics, cultural review and complete interior art.
- [ ] Add respectful optional visitor interactions, museum exhibit descriptions/collections, worship-venue schedules and local NPC behavior.
- Note: these are first-pass interior geometry placeholders, not researched, production-ready sacred or museum environments.

## Baghdad motorsport park and city faction gameplay follow-up — 21 November 2026

- [x] Add a Godot validator for dedicated-track entry, owned vehicle class eligibility, ordered checkpoint progression, three-lap completion, local reward and personal-record scope.
- [x] Keep circuit AI opponent vehicle/controller prototypes connected to race-start and player-driving signals for supported circuit events.
- [ ] Complete track-grade vehicle physics, reliable checkpoint crossing at speed, AI collision/overtaking/pit strategy, grid staging, race countdown, flags, penalties, damage, repairs and mobile race HUD.
- [ ] Run the new race validator and verify the AI race physically in Godot 4.3 and on Android; source-level wiring is not runtime proof.
- [x] Extend the existing city-faction registry with reciprocal same-city rivalries and player-only faction contracts for courier delivery, public evidence collection, district scouting and civilian-route protection.
- [x] Persist faction contracts and validate that an NPC cannot complete a player-owned contract through the local API.
- [ ] Add authored gang NPCs, hideouts, territory schedules, recruitment/membership, faction-specific interiors, investigation chains and server-authoritative multiplayer consequences.
- Note: contract evidence tokens and all faction state remain local prototype safeguards, not anti-cheat or secure online authority.

## Baghdad rare-antiquities bazaar — auction prototype — 21 November 2026

- [x] Add an original fictional artifact catalogue with rarity, era, appraisal state, museum reference value and provenance notes.
- [x] Add local auction creation, timed bidding, seller self-bid prevention, minimum-increment enforcement, outbid escrow refunds, reserve-price handling and settlement; listed player artifacts are escrowed to prevent duplicate listings and returned if unsold.
- [x] Add local inventory ownership transfers and a capped transaction ledger saved on the device.
- [x] Add a Godot validator for catalogue metadata, auction creation, escrow and invalid-bid rejection.
- [ ] Connect the bazaar building's interaction marker to an in-world market UI and the player's persistent inventory/economy.
- [ ] Add NPC appraisers/dealers, museum exhibition loans, collection bonuses, fraud/evidence investigations, and authenticated server-side ownership/escrow.
- [ ] Add a production-safe auction clock and transaction recovery; current timer and persistence are local-device prototype only.
- Note: artifact names and lore are original fictional SYSTEM items; this is functional inspiration from collectible/auction gameplay, not copied anime assets or names.

## Baghdad football stadium match prototype — 21 November 2026

- [x] Add a physical RigidBody3D football with spherical collision and a player interaction area.
- [x] Add home/away goal trigger zones, score state, a visible scoreboard and a five-minute local match timer.
- [x] Add stadium match-control and ball-kick interactions; entering the stadium initializes the local match manager.
- [x] Add a Godot 4.3 automated validator for match start, nearby-player kick, goal scoring and timer state.
- [ ] Add complete player and goalkeeper teams, locomotion/ball possession AI, tackling, passing, shooting controls, goalkeeper logic, referee, fouls, throw-ins, corners, penalties, offside and substitutions.
- [ ] Add team selection, local tournaments, season schedules, crowd reactions, replay/highlight systems and server-authoritative multiplayer.
- [ ] Run Godot runtime physics tests and Android touch/performance validation.
- Note: the current pass is a local playable ball-and-score prototype, not a complete football simulation or full 11-v-11 match.

## Baghdad football stadium — structural venue validation — 21 November 2026

- [x] Godot 4.3 civic venue validator passed for the stadium's pitch, spectator stands, four access gates, concourses, walk-in team/referee/medical/media rooms, player tunnel, floodlights and scoreboard.
- [ ] Inspect player navigation and visual scale in the live Baghdad scene; full 11-v-11 simulation and multiplayer remain separate completion gates.

## Baghdad motorsport circuit — physical pit and spectator facilities — 21 November 2026

- [x] Separate the north-side paddock, service apron and pit lane from spectator structures to avoid overlapping footprints.
- [x] Replace eight decorative garage blocks with eight walk-in pit garage interiors containing collision-backed floors/walls, open vehicle entries, tool cabinets, tire racks, workbenches, lighting and stable interaction IDs.
- [x] Add pit-lane context detection, entry/exit gate triggers and a 60 km/h pit-lane speed-limit metadata value.
- [x] Build a collision-backed race-control tower with an open entrance, interior console/monitors, upper observation deck, railings and stairs.
- [x] Build four marshal posts with platforms, shelter, flag racks and stable location/interaction IDs.
- [x] Add collision-backed south/east/west spectator stands, seat rows and south-stand stair access.
- [x] Add a dedicated Godot validator for the track facilities to the branch validation workflow.
- [ ] Validate actual player/vehicle traversal, pit speed enforcement, pit-stop service interactions, marshal NPCs, race timing and complete event simulation; the circuit remains a physical blockout, not a production-ready race simulation.

## Global road, bridge, and race gates

- [ ] Complete a continuous, optimized inter-city and rural road graph; current corridor and village-access meshes are visual prototypes and some routes are intentionally skipped.
- [ ] Convert the first-pass tunnel props and urban flyovers into connected, terrain-integrated and collision-tested routes; add complete bridge, overpass, underpass, ramp, coastal-road, mountain-pass, junction, and drainage networks. Bridge railings and marker lights are visual details only.
- [ ] Add road markings, lane graph, traffic rules, traffic lights, pedestrian crossings, speed zones, signs, and collision.
- [ ] Add race circuits, street races, checkpoints, timing, results, rewards, leaderboards, and safe reset/respawn rules.
- [ ] Implement fuel/charging, repair, garages, service stations, towing, parking, and roadside incidents; current rest-stop props are visual only.

## Vehicle completion gates

- [ ] Replace ambient-only movement with lane-aware traffic AI, intersection logic, yielding, parking, emergency dispatch, and traffic-density streaming.
- [ ] Add actual drivable vehicle physics and controls with mobile input, camera modes, suspension, braking, steering, collision, damage, and recovery.
- [ ] Add player vehicle ownership, secure purchase/sale, garage inventory, vehicle persistence, customization, keys, summon/park flow, and recovery.
- [ ] Connect ownership and vehicle state to authenticated accounts and an authoritative multiplayer backend; local save alone is not sufficient for shared-world ownership.
- [ ] Add network interest management so only nearby relevant player vehicles are replicated and rendered.
- [ ] Verify vehicle counts, physics cost, network load, and frame rate at Android quality tiers.

## Global lighting completion gates

- [ ] Extend fixture placement to all secondary streets, alleys, bridges, tunnels, stairways, parks, waterfronts, airports, ports, stations, parking structures, and rural roads.
- [ ] Add building entrances, interiors, apartment windows, shopfronts, signs, billboards, neon districts, traffic signals, headlights, brake lights, and emergency lighting.
- [ ] Use baked/static lighting where suitable, emissive distant fixtures, and a small nearby dynamic-light budget; avoid thousands of shadow-casting realtime lights.
- [ ] Add per-city and per-district lighting profiles, sunset/sunrise transitions, weather/fog response, and wet-road reflections.
- [ ] Validate night readability and performance on low-, mid-, and high-tier Android devices; provide scalable quality presets.

## Transport, ports, and waterways

- [ ] Turn airport and rail visual hubs into usable terminals with routes, schedules, boarding, fares, arrivals, and map integration; current terminal geometry is scenery only.
- [ ] Build ports, docks, marinas, cargo terminals, ferry routes, ship lanes, navigable vessels, and coastal logistics.
- [ ] Add usable passenger/cargo ships, aircraft and trains only after their controls, collisions, route logic, and save/network behavior are implemented.
- [ ] Connect bridges and waterways to the actual continent terrain and validate every crossing.

## World life and environment

- [ ] Complete NPC schedules, needs, jobs, family/social life, local commerce, and crowd behavior without allowing NPCs to perform player-only main quests.
- [ ] Complete regional soundscapes: crowds, markets, engines, horns, river/water, forest insects, birds, aircraft, ships, weather, and interiors.
- [ ] Complete weather effects, wet surfaces, puddles, fog, dust, wind response, climate-appropriate snow, and seasonal changes.
- [ ] Complete wildlife species, animation, habitats, population limits, and player/world interactions.
- [ ] Complete injury services, hospitals, police/jail consequences, reputation, and emergency response.

## Map streaming, mobile performance, and verification

- [ ] Implement region/cell streaming and LOD for geometry, NPCs, traffic, audio, lighting, foliage, and interiors.
- [ ] Define device quality tiers and memory/CPU/GPU budgets.
- [ ] Verify discovery, waypoints, fast travel, transport, collisions, save/load, and world transitions.
- [ ] Run Godot parser checks, scene startup tests, gameplay tests, and Android device tests; fix all errors and regressions.
- [ ] Inspect every city and the inter-city routes in-game, by day and night, on foot and in vehicles.
- [ ] Only after every required gate is checked and the final build is reviewed may the modern-world map be declared complete and portal work begin.

## Honesty rule

A checked repository foundation does not mean a finished gameplay feature. Visual meshes are not drivable vehicles; terminal-shaped meshes are not usable transport; road strips are not a connected road network; fixture meshes are not complete city lighting; and code committed to GitHub is not runtime-tested until Godot actually runs it.

- Added a first procedural mosque landmark pass for Baghdad OSM Muslim worship point amenities, plus one emissive demo billboard prototype per generated city. Live advertising remains disabled pending a secure approved provider integration; polygon mosque coverage and Godot/Android runtime validation remain outstanding.
- Expanded modern-city service prototypes to include schools, university, football stadium, shopping street, restaurant, bank and mall alongside existing hospital, police, fire, hotel, market and garage. Added city service interaction markers, a visible stadium pitch/stands/goals, school courtyards and shopfronts. Functional gameplay and Godot/Android runtime validation remain outstanding.


## Baghdad connected five-tower city — design direction recorded 20 November 2026

- [ ] Build the five distinct landmark towers as one connected vertical urban district spanning central Baghdad's Karkh–Rusafa corridor.
- [ ] Keep the Tigris visibly open and flowing beneath the district; preserve the river channel, riverfront access, navigation clearance, and views.
- [ ] Preserve Tahrir Square and the Freedom Monument as recognizable, explorable public landmarks on the Rusafa side; do not cover, replace, or overwhelm them.
- [ ] Connect the five towers with skybridges, elevated promenades, public terraces, and carefully designed cross-river links while keeping the river unobstructed below.
- [ ] Create a multi-level public district with ground streets/plazas, mid-level shopping and services, and upper sky gardens/recreation decks.
- [ ] Implement the five identities: Power Tower, Hunter Association Tower, Business Tower, Shopping Tower, and Entertainment Tower.
- [ ] Add accessible pedestrian routes, transit access, emergency/service circulation, wayfinding, and clear public connections to the existing Baghdad street network.
- [ ] Validate the district in Godot from Karkh, Rusafa, Tigris riverfront, and Tahrir Square viewpoints; ensure the Freedom Monument and river remain visually legible.
- Design approval/documentation is recorded in `HUNTER_TOWERS_AND_EXAMINATION_DESIGN.md`. The connected city, bridges, detailed interiors, and river engineering are not yet implemented or runtime-tested.


## Vehicle physics foundation — 20 November 2026

- [x] Add a reusable Godot VehicleBody3D-based vehicle controller prototype with four VehicleWheel3D nodes, chassis collision, suspension setup, keyboard throttle/steering/reverse/brake inputs, and a mobile-control setter API.
- [x] Add a runtime manager that can spawn the first owned/selected vehicle near a dealership in the active modern-world scene.
- [x] Add a first-pass enter/exit flow, hide/disable the player collision while driving, and hand the camera to a vehicle-follow view.
- [x] Route the existing mobile movement joystick to vehicle throttle/reverse and steering; route the existing jump button to a short brake input.
- [ ] Add dedicated on-screen accelerator, reverse, and brake controls with clear driving-mode labels.
- [ ] Tune wheel suspension, traction, braking, mass, collision, and maximum speeds using in-engine driving tests.
- [ ] Test driving on flat roads, slopes, turns, elevated decks, and parking ramps on desktop and Android.
- Note: the controller is now connected through `system_vehicle_runtime_manager.gd` and `main.gd` to a first-pass dealership interaction, owned-vehicle spawning, player handoff, camera follow, and existing touch inputs. This is source-level integration only; it has not been parsed or run in Godot, and no Android driving test was performed.

## Connected Baghdad district — collision and access blockout update — 20 November 2026

- [x] Add static collision shapes matching the generated elevated promenade and vehicle-deck box geometry.
- [x] Add collision shapes to the visual parking-level slabs and parking-ramp deck segments.
- [x] Add a three-level parking-garage blockout with thirty visual parking-bay markings.
- [x] Add two visible vertical-access shaft placeholders for passenger/service lifts.
- [ ] Add actual player vehicle spawning, enter/exit, mobile steering/throttle/brake controls, vehicle physics, and camera handoff.
- [ ] Replace the parking-ramp straight prototype segments with a continuous tested ramp route and safe grade/turn radius.
- [ ] Implement elevator movement, doors, floor selection, emergency controls, and accessible pedestrian paths.
- [ ] Validate all collision surfaces, clearances, ramp slopes, and vehicle handling in Godot and on Android.
- Note: collision-backed decks and parking slabs are source-level additions; no runtime or driving test was run in this update. Lift shafts and parking bay markings remain visual blockout, not interactive systems.

## Connected Baghdad district — vehicles and public life — 20 November 2026
- [x] Record the five distinct tower identities as one connected district: Power, Hunter Association, Business, Shopping, and Entertainment.
- [x] Add an initial procedural five-tower blockout with elevated promenade/vehicle-deck link geometry and ramp-segment placeholders.
- [x] Add placeholder public amenity deck geometry and a planned facility inventory for recreation, hospitality, shopping, health support, parking, and emergency access.
- [ ] Implement validated drivable ramp paths, vehicle physics, lane widths, slope limits, collision barriers, traffic rules, and safe merges from Baghdad streets.
- [ ] Implement parking garages, vehicle elevators/ramps, drop-off points, pedestrian crossings, and service/emergency circulation.
- [ ] Build actual interactive pools, water park, amusement park, hotels, restaurants, cafes, cinemas, sports courts, gardens, and public facilities.
- [ ] Position and validate the full district against the real in-game Tigris corridor, Karkh/Rusafa geography, Tahrir Square, and the Freedom Monument; preserve river navigation and protected landmark sightlines.
- [ ] Run Godot parser/editor/runtime checks and inspect the five-tower blockout in-game before calling this milestone validated.
- Note: the checked items above indicate repository geometry/documentation was added, not that vehicles can already drive on the decks or that the amenities are playable.


## Vehicle runtime integration — 20 November 2026

- [x] Add `system_vehicle_runtime_manager.gd` to spawn an owned vehicle near a dealership in the active world.
- [x] Connect the manager to the player, camera, spring arm, local garage manager, and active world from `main.gd`.
- [x] Route mobile joystick input to vehicle throttle/reverse and steering while driving; route the existing jump touch button to a brief brake.
- [x] Add first-pass enter/exit, player visibility/collision handoff, and vehicle-follow camera behavior.
- [ ] Add a dedicated driving HUD with accelerator, reverse, brake, and exit controls.
- [ ] Verify dealership proximity, spawn placement, camera restoration, wheel orientation, suspension, collision, and player recovery in Godot.
- [ ] Test desktop and Android driving, including city streets, slopes, bridges, elevated tower decks, and parking ramps.
- Note: the runtime manager and main-scene connections are committed source code, not verified gameplay. Godot parser, scene startup, and device tests have not been run; the existing jump button temporarily doubles as brake while driving.


## Vehicle showroom and garage UI — 20 November 2026

- [x] Add a responsive in-game vehicle showroom panel listing the current catalog, vehicle categories, prices, and ownership state.
- [x] Display the player's local vehicle-credit balance and report insufficient funds without completing a purchase.
- [x] Connect purchase and selection actions to the existing local garage manager and its save file.
- [x] Add a resale action using the garage manager's existing resale calculation and active-vehicle protection.
- [x] Connect the selected owned vehicle to runtime spawning and the first-pass enter/drive flow.
- [x] Add a return-to-garage action for a parked vehicle when the player is near a dealership.
- [x] Make showroom panel dimensions adapt to the current viewport and refresh its world-root reference after world changes.
- [ ] Replace prototype credits with the intended authenticated, server-authoritative economy before any shared-world or real-money use.
- [x] Add a procedural 3D vehicle-preview blockout to the showroom, with body, cabin, wheels, lighting, and a preview floor.
- [x] Add five paint-color choices and persist each owned vehicle's selected paint locally in the garage save.
- [x] Apply the saved paint to the spawned drivable vehicle and update its material when the player changes paint.
- [ ] Replace the generic preview blockout with distinct high-detail vehicle models and accurate category-specific proportions.
- [x] Expand the catalog with premium, luxury, supercar, electric-performance, and off-road vehicle classes, using clearly marked unlicensed brand-class references.
- [x] Add dedicated motorsport catalog classes for GT, formula single-seater, endurance prototype, drift, rally, drag, and track hypercar vehicles.
- [ ] Add test-drive mode, purchase confirmation, and a dedicated driving HUD with accelerator, reverse, brake, and exit controls.
- [ ] Verify UI layout, purchase/save/load, selling, spawning, enter/exit, and mobile touch behavior in Godot on Android.
- Note: the showroom and garage actions are source-level integrations committed to GitHub. Ownership and credits still use the existing local prototype save; no Godot parser, runtime, or Android test has been run. Vehicle previews and dedicated driving controls are not included yet.


## Vehicle 3D preview and paint customization — 20 November 2026

- [x] Add an in-showroom 3D preview scene with a procedural body/cabin/wheel blockout, camera, lighting, and floor.
- [x] Add blue, red, black, white, and gold paint swatches.
- [x] Save a separate paint color for each vehicle in the local garage configuration.
- [x] Apply saved paint when a vehicle is spawned and apply paint changes to the currently spawned vehicle.
- [ ] Replace the generic blockout with final distinct vehicle assets, materials, glass, lights, interiors, and correct proportions for each catalog entry.
- [ ] Add preview rotation/zoom, vehicle-specific paint options, and visual damage/customization.
- [ ] Validate SubViewport rendering, UI fit, paint persistence, and material updates in Godot on Android.
- Note: this is a procedural preview blockout, not a final vehicle model. Paint and ownership are stored locally on the device; no Godot parser, runtime, or Android validation has been performed.


## Global automotive market and motorsport catalog — 20 November 2026

- [x] Expand the vehicle catalog beyond basic city transport to include premium executive sedans, grand tourers, supercars, electric performance cars, and off-road 4x4s.
- [x] Add a broad international-market direction with manufacturer-class references spanning Mercedes-Benz, BMW, Audi, Aston Martin, Bentley, Ferrari, Lamborghini, McLaren, Tesla, Porsche, Lucid, Toyota, Land Rover, Jeep, Bugatti, and Koenigsegg.
- [x] Add dedicated race inventory classes: GT3 circuit, formula single-seater, endurance prototype, drift, rally, drag, and track hypercar.
- [x] Mark brand references as unlicensed placeholders; no official manufacturer endorsement, trademark license, or authentic brand asset is claimed.
- [ ] Obtain the required manufacturer/trademark permissions for official branded vehicles, logos, liveries, and authentic models before release.
- [ ] Create distinct high-detail vehicle models, interiors, lights, sound, handling, damage, and category-specific previews for every class.
- [ ] Build racing systems: licensed/fictional championships, circuits, qualifying, laps, timing, pit stops, penalties, AI opponents, multiplayer races, and rewards.
- [ ] Balance prices, unlock requirements, progression, and availability through the intended shared economy.
- Note: catalog metadata and vehicle class entries are source-level foundations only. They do not yet provide authentic manufacturer models, completed racing gameplay, or validated driving physics.


## First-pass motorsport event framework — 20 November 2026

- [x] Add a reusable motorsport manager with event definitions for city sprint, GT championship, formula grand prix, endurance, drift, rally, and quarter-mile drag.
- [x] Validate that the selected event exists, the player owns the entered vehicle, and its catalog class is eligible for that discipline.
- [x] Add ordered checkpoint registration, lap progression, elapsed-time tracking, finish/cancel flow, and race lifecycle signals.
- [x] Add a local prototype wallet reward method and connect event completion to its fixed participation reward.
- [x] Instantiate the motorsport manager from `main.gd` at startup and provide the existing player garage manager.
- [ ] Connect race event selection and physical race routes to the active world; instantiate real start/finish gates and checkpoint Area3D nodes.
- [ ] Build race tracks and route geometry for circuits, drag strips, drift arenas, rally stages, and endurance layouts.
- [ ] Add countdowns, false-start detection, lap timing UI, position tracking, AI competitors, penalties, pit stops, damage rules, and reset/respawn handling.
- [ ] Add event menus, qualifying, championships, seasonal events, leaderboards, multiplayer synchronization, anti-cheat validation, and server-authoritative rewards.
- [ ] Validate all event flows and rewards in Godot and on Android.
- Note: the manager is instantiated by the main game script, but this is still a source-level race lifecycle/checkpoint foundation only. No track/checkpoint nodes, race UI, or AI opponents are built, and rewards remain local-device prototype currency.


## Dedicated motorsport, illegal street racing, and police response — 20 November 2026

- [x] Restrict purpose-built race-class vehicles to dedicated track context in the vehicle runtime manager; spawning or entering GT, Formula, endurance, drift, rally, drag, and track-hypercar vehicles is rejected outside an approved track context.
- [x] Require dedicated-track context before a sanctioned motorsport event can start.
- [x] Clarify that the City Sprint Cup is a closed, sanctioned city circuit, not racing on open public roads.
- [x] Define player-versus-player wager rules as fictional SYSTEM credits only; wager creation remains disabled until authenticated multiplayer escrow, server authority, anti-cheat, and dispute handling exist.
- [x] Add a police-report entry point for unsanctioned street-racing incidents, witness report metadata, wanted-level escalation, and dispatch of a police pursuit toward the reported vehicle.
- [x] Add a first-pass police-arrival response that stops the reported illegal-racing vehicle and records the incident.
- [ ] Build physical dedicated motorsport venues with access gates, paddocks, garages, pit lanes, spectator areas, and track-zone trigger volumes that call the track-context API.
- [ ] Build a separate illegal street-racing activity using road-legal street cars, hidden meetups, rival crews, witness detection, escape routes, police roadblocks, pursuit navigation, arrest/impound, fines, reputation loss, and repeat-offender consequences.
- [ ] Connect police reports to actual active player vehicles and multiplayer participants; current report API requires the race activity to explicitly submit its target vehicle.
- [ ] Implement secure server-authoritative player-to-player wager escrow, opt-in consent, limits, settlement, refunds, anti-collusion and dispute handling; no real-money betting.
- [ ] Run Godot parser, scene integration, AI pursuit, vehicle stopping, and Android tests before treating any of these features as playable.
- Note: the changes are source-level foundations only. No track trigger volumes or playable race venues have been built, the crime manager does not yet automatically detect street races, and the new police response has not been runtime-tested. The dedicated-track context setter must be connected to future physical track zones.


## Baghdad International Motorsport Park blockout — 20 November 2026

- [x] Add a procedural first-pass motorsport venue manager for the modern world.
- [x] Create a 32-segment oval-style circuit surface with static road collision, inner guide line, and safety barriers.
- [x] Add a basic paddock with eight garage bays, pit lane, and simple spectator grandstands.
- [x] Add an approved-track Area3D zone; entering/exiting with the player toggles the dedicated-track context in both vehicle runtime and motorsport managers.
- [x] Integrate the venue manager into modern-world startup from main.gd.
- [ ] Replace procedural blockout meshes with detailed track art, curbs, runoff zones, pit buildings, race control, lighting, signage, and crowd assets.
- [ ] Add track-specific layouts and validated checkpoint transforms, starting grids, finish lines, timing sectors, and track marshal posts.
- [ ] Add track access gates, garage selection, race registration UI, spectator events, and AI competitors.
- [ ] Verify player collision layer/mask and test entering/exiting the Area3D in Godot; run parser and Android performance tests.
- Note: the venue is a source-level procedural blockout, not a finished or tested playable race track. The track zone is a broad access volume around the venue and currently toggles permission; the racing manager still needs actual checkpoint nodes and event registration integration.


## Baghdad motorsport start grid and checkpoint route — 20 November 2026

- [x] Add a visible start/finish gantry and four-lane starting-grid markings to the Baghdad circuit blockout.
- [x] Add four ordered checkpoint trigger areas around the oval route, with visible checkpoint gate markers.
- [x] Connect vehicle-body checkpoint entry to the existing motorsport manager's ordered checkpoint/lap/timing lifecycle.
- [x] Add a track event start API that requires the player to be inside the approved venue, actively driving an owned vehicle, and positioned near the start grid; event and vehicle-class validation remains delegated to the motorsport manager.
- [ ] Build a registration/menu interaction that lets the player choose an eligible event and call the track start API in-game.
- [ ] Add countdown, false-start detection, timing sectors, race HUD, restart/retire flow, AI competitors, and spectator/event presentation.
- [ ] Validate checkpoint collision masks, checkpoint order, lap completion, and start-grid placement in Godot; run Android driving tests.
- Note: this update adds source-level track geometry and trigger-to-manager integration. It is not yet a fully playable race event: there is no in-game event-selection UI or countdown, and no Godot parser/runtime or Android test has been run.


## Baghdad residential and worship fabric — 20 November 2026
- [x] Classify OSM building footprints as low-rise detached houses, apartment/residential blocks, commercial buildings, mosques, churches, or general buildings where source tags permit.
- [x] Use OSM height/level tags when present and add conservative category-specific fallback heights when they are absent.
- [x] Preserve OSM feature identity and attach a building-type metadata label for future interaction and district systems.
- [x] Add first-pass roof markers for polygon worship buildings and distinct point-landmark blockouts for Muslim mosques and Christian churches.
- [ ] Audit the Baghdad OSM cell pack coverage for houses, apartment blocks, building levels, mosques, churches, and all worship-place polygons; report missing or untagged features rather than fabricating exact real locations.
- [ ] Build complete Baghdad neighborhood logic: residential/commercial/mixed-use zoning, street hierarchy, blocks, alleys, sidewalks, courtyards, parking, utilities, and public spaces.
- [ ] Turn residential buildings into enterable, multi-floor structures with apartments, stairs, elevators, doors, furniture, lighting, utilities, and safe navigation.
- [ ] Add house/apartment ownership, purchase/rent, household residents, family schedules, maintenance, and neighborhood services.
- [ ] Refine Baghdad mosque and church models using locally appropriate architectural references, distinct building scales, courtyards, entrances, and interiors while preserving religious respect and accessibility.
- [ ] Connect worship places and residential blocks to the city map, discovery, pedestrian navigation, and NPC daily-life schedules.
- [ ] Validate all building geometry, collisions, streaming, performance and visuals in Godot and on Android; source-level tags and blockouts are not runtime-verified.

## Baghdad OSM building discovery interaction — 20 November 2026

- [x] Attach world-interaction metadata to the collision body of each streamed OSM building footprint so the existing camera ray interaction manager can resolve the building as an interactable target.
- [x] Preserve the OSM feature ID and building classification on the collision body; assign a stable per-feature discovery ID, Baghdad region ID, non-fast-travel location type, and an Arabic display label that prefers the source name when available.
- [x] Keep this as a discovery/information interaction only. It does not claim that the building has a usable door, accessible interior, apartment floor plan, ownership, rent, inventory, or NPC residents.
- [x] Cross-check the Baghdad region ID against `ModernWorldRegionManager.register_map_locations`: building discovery now uses the same `region_baghdad` key as the registered Baghdad city map entry. Runtime discovery registration still requires Godot verification.
- [ ] Add actual entrance/door placement, entrance approach points, interior scenes, apartment/shop use cases, and save-backed discovery state after the interaction flow is runtime-validated.
- [ ] Run Godot parser, scene startup, ray-interaction, cell unload/reload, and Android performance tests; none were run for this source update.

## Baghdad building discovery details and map positioning — 20 November 2026

- [x] Calculate an approximate footprint-center position from each streamed building polygon and store it as discovery metadata, including terrain elevation at that point.
- [x] Store source-derived building height and a clearly estimated floor count (height divided by the configured 3.2 m floor heuristic); these are estimates, not surveyed floor data.
- [x] Update the existing interaction manager to register the stored footprint position instead of the collision body's origin, so discovered building markers are not all registered at world origin.
- [x] Show a short building inspection readout after interaction: display name, classification, estimated floors, estimated height, and an explicit note that interiors/access are not implemented.
- [ ] Improve the readout presentation for mobile screens and verify it with the actual HUD layout.
- [ ] Validate polygon-center quality for concave/irregular footprints; current arithmetic vertex average is an approximation and may not lie inside every footprint.
- [ ] Implement real entrance locations and enterable interiors only after reliable entrance data/placement and runtime validation are available.
- [ ] Run Godot parser, map registration, interaction, UI, streaming, and Android performance tests; none were run for this source update.

## Baghdad road-side building approach markers — 20 November 2026

- [x] Build OSM road meshes before building interaction markers so the same cell's tagged road geometries can inform an approach estimate.
- [x] For each polygon building, find the nearest tagged highway segment to its approximate footprint center, then project that road-side point onto the closest polygon edge and offset a small distance outward.
- [x] Create a visible, interactable approach marker only when a tagged road is within the configured 40 m search radius; register it as a normal discoverable location, never as a fast-travel point.
- [x] Store the approach distance, building category, estimated height and estimated floor count; the existing inspection readout is shown when the approach marker is used.
- [x] Label the prompt as an approximate frontage/approach inspection. This is not a verified architectural entrance, door, sidewalk, accessible route, or permission to enter.
- [ ] Validate approach positions against actual Baghdad building frontage, sidewalk widths, gates, walls, courtyards, and road-side geometry; the current nearest-road heuristic can be wrong.
- [ ] Add entrance nodes only from verified entrance data or manually authored building-specific placements, then connect them to real interior scenes and access rules.
- [ ] Run Godot parser, ray-target selection, collision, map discovery, cell streaming/unloading, and Android performance tests; none were run for this source update.

## Baghdad source-mapped entrances — 20 November 2026

- [x] Extend the OSM extraction workflow with a dedicated entrance-node layer sourced from node tags `entrance`, `door`, and `building=entrance`; preserve source OSM IDs and selected access/accessibility tags.
- [x] Add the entrance layer to boundary clipping and the 200 m metric cell-pack generator. Point features are assigned to their containing cell and remain in the same local coordinate frame as buildings and roads.
- [x] Add runtime loading for entrance points, with a visible interactable marker and stable discovery ID derived from the OSM feature ID. The marker is only emitted for mapped point features; no synthetic door is placed when source data has no entrance node.
- [x] Show mapped entrance type, source access tag, and wheelchair tag when the player interacts. Unknown accessibility remains explicitly unknown.
- [x] Keep the interaction honest: a mapped entrance point is not a built door mesh, verified building-to-door association, openable door, interior scene, or permission to enter; private/no access tags are surfaced as restricted.
- [x] Add a GitHub Actions cell-pack assertion that every emitted entrance feature is a Point with a source entrance/door/building tag.
- [x] Run the updated OSM workflow successfully (run 44736344496; artifact 14629100933): the Baghdad boundary clip contains 188 mapped entrance points, and the initial 5×5 / 200 m sample cell pack contains 30 entrance points. This confirms source coverage in the sample, not that every building has a mapped entrance.
- [ ] Associate entrance nodes with their correct building footprints and building IDs using spatial/topological validation; the current runtime marker is independently discoverable.
- [ ] Build door visuals, access checks, enter/exit transitions, interiors, floors, and apartment/shop functionality only after source-to-building associations and scene integration are validated.
- [x] Canonical Godot 4.3 validation workflow 44736373468 passed project import/script parsing and headless main-scene launch after the entrance-loader changes; project validation workflow 44736373505 also passed.
- [x] Android debug APK workflows passed: canonical SYSTEM WORLD build 44736373661 (artifact 14628179091), SYSTEM WORLD export 44736373583 (artifact 14629175553), and SYSTEM build 44736373546 (artifact 14628741580).
- [x] Follow-up canonical build 44736784123 downloaded the new successful entrance-enabled OSM pack (source run 44736344496; artifact 14629100933), installed all 25 sample metric cells into the project, passed the Baghdad OSM runtime-cell validation, and exported APK artifact 14628622619.
- [ ] Run entrance-specific ray-target, location discovery, cell boundary/unload, and marker-to-building association tests; inspect the APK on a physical Android device. A successful APK export is not a physical-device gameplay test.


## Evidence-based entrance association tooling — 20 November 2026

- [x] Added `tools/geospatial/associate_baghdad_entrances.py` to analyze the generated metric OSM cell-pack ZIP and associate source entrance nodes with OSM building footprints.
- [x] Reassembles building polygon fragments split across multiple 200 m cells before measuring entrance distances; this avoids incorrectly treating a clipped cell fragment as the full building footprint.
- [x] Produces explicit accepted, review, restricted, and rejected outcomes with OSM IDs, distances, source tags, candidate ambiguity information, and summary counts. The tool does not generate or claim an unverified physical door.
- [x] Preserves access restrictions: `access=no/private` is reported as restricted, and explicit `entrance=no` / `door=no` points are rejected as non-entry points.
- [x] Added unit tests for contained entrances, ambiguous neighboring buildings, private access, and no-nearby-building rejection in `tools/geospatial/test_associate_baghdad_entrances.py`.
- [ ] The association report has not yet been run against the latest Actions artifact in this session; test execution and report output remain pending.
- [ ] The report is not yet consumed by `baghdad_osm_cell_streamer.gd`; runtime door/interior transitions remain unimplemented. Do not mark mapped entrances as enterable until that integration and its Godot tests pass.

Run from `SYSTEM-WORLD/` after installing the same Shapely dependency used by the cell-pack generator:

```bash
python tools/geospatial/associate_baghdad_entrances.py --pack path/to/baghdad-cell-pack.zip --output reports/baghdad-entrance-associations.json
python -m unittest discover -s tools/geospatial -p 'test_associate_baghdad_entrances.py' -v
```


## Advertising media and public champion displays — 20 November 2026

- [x] Add the design and implementation acceptance specification at `REAL_WORLD_ADVERTISING_AND_CHAMPION_DISPLAY_SYSTEM.md`.
- [x] Define facade-mounted billboards, rooftop LED panels, skyscraper media ribbons, shopfront, transit, stadium, and Baghdad five-tower display placements.
- [x] Define protected placement rules for entrances, traffic/emergency signage, the Tigris, Tahrir Square, and the Freedom Monument.
- [x] Separate curated in-world campaign content from real paid advertising; require provider approval, privacy/consent safeguards, moderation, opt-out, fallback, and platform/legal review before live ads.
- [x] Specify verified public-result displays for monster-gate clears, missions, Power Tower events, and Hunter Examination qualifiers/finalists/winners.
- [x] Specify authoritative verification, anti-cheat, privacy-safe display names, provisional-versus-final status, and a Hall of Honor archive.
- [ ] Implement facade anchor metadata, actual 3D screen meshes/materials, campaign rotation, and distance-based LOD in Godot.
- [ ] Implement the authoritative verified-event-results service and connect it to gates, missions, Power Tower, and Hunter Examination.
- [ ] Integrate a real advertising provider only after approvals, consent/privacy review, moderation, and platform compliance.
- [ ] Run Godot parser/scene checks and Android performance tests for screen count, texture memory, animation, brightness, and night visibility.
- Note: this commit records the requested system specification and required work; it does not mean live ads, public leaderboards, or event boards are already running in the game.


## City advertising skyscrapers and public champion boards — 20 November 2026

- [x] Add `scripts/system_public_event_board.gd` as a shared 3D display manager for the modern-world city map.
- [x] Replace the previous detached demo billboard routine with a procedural skyscraper facade in each configured city, carrying a curated advertising panel and a separate public event-results panel.
- [x] Add facade-mounted advertising and results panels to the five Baghdad landmark towers: Hunter Association, Power, Business, Shopping, and Entertainment.
- [x] Connect completed monster-gate clears to publish gate rank, gate ID, and XP to the public boards.
- [x] Connect verified mission-reward events to the public boards.
- [x] Connect Hunter Examination stage completion and final license-earned signals to the public boards.
- [x] Connect Power Tower floor-clear events to the public boards.
- [x] Persist the most recent 40 local-session event records in a user config file and show the latest four on every city/tower results display.
- [x] Keep the advertising mode explicitly curated/demo; live commercial ads remain disabled until a compliant provider/backend, consent, moderation, privacy and legal review are implemented.
- [ ] Implement server-authoritative cross-player champion rankings, global winner history, anti-cheat validation and privacy controls; current records are local to the player's device/session and are not a global leaderboard.
- [x] Godot 4.3 project import/script parsing, missing-resource scan, and headless main-scene launch passed in GitHub Actions run 44741267042 on commit `efb156486d857c1a842fcbfb9278b3453923fd80`.
- [ ] Validate facade orientation, screen readability, night brightness, occlusion, LOD, memory and Android frame rate on physical devices.
- [ ] Complete Android APK export workflow and inspect the generated build on a device.
- Note: CI confirms project parsing and headless scene startup, not visual correctness, gameplay feel, or physical-device performance. Local event records are not cross-player global rankings; an authoritative online service remains required.

## Baghdad real-road player navigation map — 20 November 2026

- [x] Expose the pedestrian-accessible road segments from currently loaded OSM metric cells through `get_loaded_road_map_segments()`; retain the source road classification and local metric coordinates.
- [x] Add a strict player-facing `find_real_baghdad_road_path()` API. Unlike the NPC convenience path, it never falls back to the fictional procedural waypoint grid or claims a guessed route is real.
- [x] Connect the existing city navigation manager to the world-map UI through the map bootstrap.
- [x] Draw currently loaded OSM road geometry in the Baghdad map view, show the player's current position, and draw a highlighted route plus destination marker when a discovered Baghdad location is selected.
- [x] Add route selection to discovered Baghdad map locations and a clear-route action. Non-Baghdad worlds do not use the Baghdad road graph.
- [x] Explain route failure when the start/destination cannot be connected inside the currently loaded road cells; do not display a fabricated path.
- [x] Godot 4.3 validation workflow 44798560091 passed project import/script parsing, terrain streaming lifecycle checks, Baghdad city-state persistence round-trip, child-character safety checks, null-mesh scan, and headless main-scene launch.
- [ ] Run an end-to-end route calculation against the installed OSM cell-pack artifact with representative Baghdad start/destination pairs, including cell-boundary transitions and unreachable destinations.
- [ ] Verify map readability, touch target sizes, route visibility, and performance on a physical Android device.
- [ ] Add turn-by-turn guidance and an in-world 3D route ribbon/waypoint guidance after the map route is validated.
- Note: road geometry and routes are available only when the real Baghdad OSM pack is installed and the relevant cells are loaded. The current route graph is local to loaded cells; this implementation does not yet promise city-wide routing across unloaded cells. CI confirms project parsing and headless startup, not physical-device visual/gameplay correctness.


## Baghdad five-tower lobby implementation — 21 November 2026

- [x] Add a shared procedural first-pass lobby interior for the five connected Baghdad towers: Hunter Association, Business, Shopping, Entertainment, and Technology & Innovation.
- [x] Give each lobby a distinct service-desk identity and Arabic information labels matching its tower purpose.
- [x] Add discoverable entry, exit, and service-information interaction areas to the four public service lobbies and the Hunter Association Tower lobby.
- [x] Wire lobby entry/exit transitions through the main interaction handler and clear the player velocity on transitions.
- [x] Keep the separate Power Tower excluded from the lobby script and preserve its independent challenge venue and collider.
- [x] Disable the five connected towers' monolithic base/shaft colliders where they would seal the playable lobby volume; the lobby supplies its own floor and wall collision.
- [ ] Replace the current lobby/service-desk blockouts with final art, working elevators/floor access, staffed NPCs, and complete tower-specific service workflows.
- [ ] Add real shop/business/technology/entertainment activity systems and persistent ownership/transactions where applicable.
- [ ] Run Godot 4.3 parser and headless scene validation on this commit; test player entry, service prompts, and exit on Android.
- [ ] Validate the complete five-tower sky district, river clearance, bridge connections, navigation, and mobile performance in a live build.
- Note: these are first playable lobby blockouts and local information interactions. They do not mean the five towers or their business services are fully complete. Power Tower remains separate and unchanged.


## Power Tower, football stadium and motorsport follow-up — 21 November 2026

- [x] Keep Power Tower detached from the five-tower connected district and all district skybridge loops.
- [x] Align the independent Power Tower architecture with the 200-floor progression system; keep it separate from the five connected Baghdad towers.
- [x] Add an independent physical challenge-arena blockout at the Power Tower, with a walkable floor, ring boundary, spectator tiers, lighting and arena signage.
- [x] Route a valid next-floor request into its generated 200-floor exploration environment; keep the exhibition arena as a separate independently entered venue.
- [ ] Add floor-specific combat rooms, real opponent/boss spawning, combat objective verification, return flow, and secure clear-time/rank validation. The current 200-floor manager stores progression metadata and save state; generated physical exploration environments are now built one active floor at a time, while combat and boss gameplay remain incomplete.
- [x] Expand Baghdad's football stadium from a flat placeholder into an open pitch blockout with grass bands, boundary/halfway lines, center circle, penalty areas, goals, four-sided spectator stands, and an open playable pitch collision surface.
- [x] Disable the solid stadium-shell collider that previously blocked access to the field; add an entry transition from the stadium interaction point to the pitch.
- [ ] Add ball physics, player/team control, match rules, goalkeeper/keeper AI, fouls, score, clock, tournaments, multiplayer and spectator NPC behavior.
- [x] Add a race-control interaction at the dedicated Baghdad motorsport start grid and connect it to the existing sanctioned City Sprint event API.
- [ ] Add complete race UI/event selection, opponents/grid AI, timing display, vehicle recovery, track marshal behavior, replay and tested finish/reward flow.
- [ ] Run Godot 4.3 parser/import/headless scene validation and Android gameplay/performance tests for all new venue changes before calling them verified.
- Note: arena, stadium and race-venue geometry are procedural blockouts. A connected interaction or API call does not mean combat, football matches, AI racing, or the full event experience is complete.


## City street advertising and live map campaign network — 21 November 2026

- [x] Add a dedicated modern-world city advertising manager, separate from the public champion/results display.
- [x] Create three procedural interactive street billboard displays per generated modern-world city, with Arabic text, visible frames, supports, lighting surfaces, and interaction areas.
- [x] Add a timed campaign rotation covering Hunter Association tests, city commerce, Power Tower, football, motorsport, and seasonal city events.
- [x] Show the active campaign category, title, body, suggested action, and expiry when the player interacts with a street board.
- [x] Register street billboard IDs and current campaign data in the world map manager.
- [x] Render advertisement markers with a distinct visual symbol on the modern-world map; support direct touch selection, a campaign-category filter, and a campaign details view.
- [x] Synchronize city media-tower and Baghdad tower facade advertising labels with the same active campaign rotation used by street billboards.
- [x] Add a dedicated headless Godot validation script for billboard/map/facade integration and wire it into the Godot validation workflow.
- [x] Add a Baghdad map action to request navigation to a street billboard through the existing real-road route service; route generation still depends on available connected OSM cells.
- [x] Avoid redundant map refreshes while the current campaign remains unchanged.
- [x] Document campaign lifecycle, placement, moderation, privacy, fairness, performance, backend, and production requirements in `CITY_ADVERTISING_SYSTEM_DESIGN.md`.
- [ ] Add final art assets, city-specific billboard styles, animation/video display surfaces, and more realistic street placement validated against loaded road/building geometry.
- [ ] Add map search, saved favorites, hide/report controls, and accessible campaign settings.
- [ ] Add authorized campaign-management tools, server-authoritative scheduling, moderation, advertiser accounts, billing, analytics, and anti-fraud controls. Current campaigns are local demo data only.
- [ ] Extend campaign support to the historical, mythic/fantasy, and Greed Island worlds after their distinct in-world media rules are designed.
- [ ] Run the updated Godot 4.3 parser/import/headless validation workflow on the latest branch revision; verify in-world board interactions, map refresh, expiry/rotation, facade synchronization, and Baghdad route requests on Android.
- Note: this is a first functional local campaign prototype. It does not yet provide a live commercial advertising network, online campaign administration, or final-quality art. Street and map campaigns are linked by stable board IDs, but the complete production lifecycle remains future work.


## Baghdad approved five-tower reference — elevated sky promenade blockout — 21 November 2026

- [x] Preserve the five existing tower identities and their current independent tower roots.
- [x] Keep the Power Tower separate from the five-tower district and its sky-promenade loop.
- [x] Add a first-pass 12-segment elevated ring promenade around the five-tower district, aligned with the existing elevated-link level.
- [x] Add walkable deck collision, glass-style safety rails, cyan emissive rail accents, and six simple sky-garden planter/tree blockouts.
- [x] Tag the generated promenade with explicit prototype metadata and a note that final art and runtime validation are still pending.
- [ ] Run Godot 4.3 project import/script parsing and headless startup against the new commit; the latest code change has no confirmed workflow run yet.
- [ ] Verify ring alignment against actual tower transforms, bridge joins, player navigation, collision seams, and terrain/river clearance in a live scene.
- [ ] Replace primitive deck/rail/tree geometry with final modular architecture, glass materials, planted landscaping, and city-specific facade art.
- [ ] Add working lift/stair access, public NPC activity, shop/restaurant interactions, and per-platform activity routing.
- [ ] Profile draw calls, collision count, shadows, and frame time on Android quality tiers before increasing detail.
- Note: this is a procedural visual/gameplay blockout only. It is not a final rendered asset pack, and it has not been physically tested on Android.


## Baghdad tower-specific skyline silhouettes — 21 November 2026

- [x] Add distinct procedural visual accents for the five district towers: Hunter sky terraces, Business office decks, Shopping market decks, Entertainment halo rings, and the Technology innovation spire/antennas.
- [x] Keep these accents visual-only and low-node-count; do not claim that the decks are enterable or functional.
- [ ] Validate tower silhouette proportions, intersections with the existing shafts/floor bands, material readability, and skyline composition in Godot.
- [ ] Replace primitive shapes with optimized final modular meshes and authored materials after visual review.
- Note: all five towers remain within the approved district; Power Tower is not included in these identity features.


## Sky promenade clearance and tower access connectors — 21 November 2026

- [x] Increase the outer ring radius to 580 m so the promenade clears the five tower footprints at the current Baghdad anchor.
- [x] Resize the 12 deck segments to approximately 302 m to follow the larger ring chord.
- [x] Add five radial pedestrian bridge blockouts from the tower perimeter zones to the outer sky ring.
- [x] Add collision to both sides' safety-rail blockouts.
- [ ] Verify clearances and bridge joins against terrain and tower transforms in Godot; current coordinates remain provisional until live scene inspection.
- [ ] Add railings/collision to radial bridges, stairs/lifts, lighting budget, navigation links and final modular assets.


## CI parse blocker found during continued review — 21 November 2026

- [x] Fix a duplicate local variable declaration in ModernWorldRegionManager._create_city_advertising_screens by giving the later event-board lookup its own variable name.
- [ ] Re-run Godot 4.3 import/script parsing on the latest PR head to confirm the parse blocker is cleared.
- [ ] Investigate separate runtime validation failures reported by the earlier CI run: NPC visible-population manager was not mounted, and main.gd accessed a nil global_transform at line 1296. These failures are separate from the Baghdad tower blockout and must be resolved before a successful full project validation can be claimed.
- Note: the available failing CI logs were produced by an earlier PR revision, not the current latest head. The latest head still needs its own workflow run.


## Runtime guard and civilian population mounting corrections — 21 November 2026

- [x] Prevent the player physics loop from reading the SpringArm global transform before both player and camera rig are valid.
- [x] Resolve the modern world root directly from WorldManager when creating city navigation and visible civilian population managers, rather than relying on a possibly stale active-root reference.
- [ ] Confirm the population manager mounts and spawns visible civilians in the latest Godot run.
- [ ] Confirm no nil camera-transform errors remain during headless startup.
- Note: these changes address the failure signatures from the earlier CI run; they are not yet confirmed by a new successful run on the latest branch head.


## Baghdad tower lobbies — identity fit-out and physical service desks — 21 November 2026

- [x] Add a dedicated identity display to each of the five tower lobbies, with tower-specific color and function.
- [x] Convert the three service desks in each lobby from decorative-only meshes to solid desk assemblies with collision.
- [x] Add lobby wayfinding pillars and a directional sign near the entrance zone.
- [x] Correct the indentation of the sky promenade metadata statement found during source review.
- [ ] Verify lobby entry/exit routing, player clearance, and the five identity display layouts in a live Godot scene.
- [ ] Replace the current prototype screens with data-backed service UIs and implement working elevator/stair floor selection.
- Note: the lobby remains a first-floor playable blockout. Upper floors, service workflows, NPC staffing and real lift movement are not implemented by this pass.


## Tower building entry/exit interaction wiring — 21 November 2026

- [x] Route interactions with the five connected tower entrance IDs to their sibling TowerInterior entry positions.
- [x] Route the Hunter Association headquarters entrance to HeadquartersInterior.
- [x] Route tower lobby and headquarters exit interactions back to their configured exterior return positions.
- [x] Reset player velocity and clear the active interaction prompt after a building transition.
- [ ] Verify the transition targets and player capsule clearance in Godot; this code path has not yet been confirmed in a live run.
- [ ] Add camera/facing alignment, transition fade, door animation, floor selection and working elevators/stairs.
- Note: this wires first-floor entry and exit only. It does not make upper tower floors accessible or implement lift travel.


## Upper tower floors and interactive lift selection — 21 November 2026

- [x] Add four upper-floor blockout decks to each of the five tower interiors (floors 02–05).
- [x] Add floor identity labels and landing markers.
- [x] Add a continuous visual lift-shaft guide pair and illuminated landing-door panels.
- [x] Add one interaction selector per upper floor with an explicit world-space destination.
- [x] Route tower-floor selector interactions through the building transition manager.
- [ ] Verify player placement, collision clearance, and interaction reach at all four landings in Godot.
- [ ] Implement a true moving elevator car, doors, call buttons, travel animation, stairwell, and floor-specific gameplay services.
- Note: current lift selection is a prototype floor transition, not a physically animated elevator. Upper floors are structural blockouts and not complete furnished interiors.


## Tower-specific upper-floor spaces and service-desk information — 21 November 2026

- [x] Add distinct first-pass floor-space blockouts for all five tower identities across floors 02–05: Hunter briefing/mission display, business office pods/conference table, shopping kiosks/market island, entertainment stage/audience tiers, and technology workbenches/prototype display.
- [x] Add a main interaction response for tower service desks that displays their configured service title and prototype description.
- [ ] Replace static service descriptions with real service workflows, data, inventories, bookings, jobs and NPC staff.
- [ ] Verify all 20 themed floor layouts, collisions, labels and interaction targets in Godot; no current runtime validation is available.
- Note: these are shared five-floor themed blockouts, not fully furnished or operational businesses, labs, arenas or hunter mission systems.

## Hunter examination state continuity fix — 21 November 2026

- [x] Correct the exam start/resume flow so an already-active examination returns its current stage instead of being rejected by an unreachable duplicate condition.
- [x] Validate the active-stage state before reporting a successful resume.
- [x] Clear persisted failure status, failure reason, and stage index when a new exam registration is created, preventing a previous failed attempt from reappearing after reload.
- [ ] Add authoritative evidence verification for each exam stage; the current non-empty evidence string is only a placeholder and is not secure proof of completion.
- [ ] Add explicit player identity persistence and server-side candidate-number allocation before online/multiplayer examinations.
- [ ] Run the Godot 4.3 parser and examination save/resume regression tests on the latest branch head.
- Note: this fixes state-flow defects in the local Hunter examination prototype. It does not implement the actual seven exam challenges, secure evidence validation, online exam service, or a production hunter license.

## Baghdad Hunter Association service connection — 21 November 2026

- [x] Expose explicit open/close methods on the existing Hunter Guild menu so world interactions can open it without requiring the HUD toggle button.
- [x] Connect all three Hunter Association lobby service interaction points to the existing Hunter Guild panel using their tower service IDs.
- [x] Reuse the existing mission acceptance and Hunter examination signals; no duplicate mission/exam manager was introduced.
- [x] Give the registration desk, mission board, and information desk separate filtered views in the existing Hunter Guild menu.
- [x] Route the exact lobby service IDs ending in `_0`, `_1`, and `_2` to registration, missions, and information respectively.
- [ ] Validate service-area targeting, menu visibility, mission acceptance, and exam registration in Godot 4.3 on device.
- [ ] Validate service-area targeting, menu visibility, mission acceptance, and exam registration in Godot 4.3 on device.
- Note: this makes the existing Hunter Guild UI reachable from the Baghdad Hunter Association lobby. It does not complete the full mission objective/evidence verification pipeline or online account persistence.


## Baghdad Business Tower — local economy and company registration prototype — 21 November 2026

- [x] Add a dedicated economy manager that uses the existing player wallet balance rather than creating a second disconnected currency balance.
- [x] Expose generic local wallet credit/debit operations and keep existing vehicle purchases and motorsport rewards on the same wallet.
- [x] Add a locally persisted business registry with company name, sector, local owner, registration timestamp, and stable local company ID.
- [x] Add input validation, duplicate-name prevention, a five-company local prototype limit, and a 1,000 SYSTEM Credits registration fee.
- [x] Add separate Business Tower service views for business consultation, investment information, and company registration.
- [x] Connect the three Business Tower lobby service IDs to the dedicated service interface.
- [x] Persist a local transaction record for company registration and expose recent ledger entries through the economy manager API.
- [ ] Add real business operations: employees, premises, supply chains, products, sales, operating costs, contracts, taxes, and company progression.
- [ ] Implement a simulated investment market with transparent risk, valuation, cash flow, loss conditions, and anti-exploit balancing before enabling investment transactions.
- [ ] Move wallet, company registry, and transaction ledger to authenticated server-authoritative storage before multiplayer or cross-device use; current records are local-device prototypes.
- [ ] Run Godot 4.3 parser/import/headless validation and test all three service desks, wallet debit/persistence, duplicate company names, insufficient funds, and reload recovery.
- Note: company registration currently deducts local prototype credits from the same wallet used by the vehicle garage. It is not a real legal company, online financial service, investment product, or cross-player economy. The investment desk is intentionally informational and disabled; it does not accept deposits or promise returns.


## Baghdad Hunter Examination Tunnel — 21 November 2026

- [x] Open a dedicated passage in the Hunter Association Tower lobby rear wall without changing the other four tower lobby layouts.
- [x] Build a long enclosed tunnel with floor, side walls, ceiling, repeated structural frames, illuminated guidance strips, and a separate candidate staging chamber.
- [x] Add seven numbered stage gates and candidate wayfinding markers along the tunnel.
- [x] Add free registration, public notice, and start/resume interactions in the Hunter Association lobby and tunnel.
- [x] Connect registration, notice and start interactions to the existing Hunter Exam Manager and open the guild UI with candidate status and stage briefing.
- [x] Expand the exam data to seven ordered original stages: endurance pursuit, fieldcraft/cooking, puzzle tower, island survival, strategy/negotiation, individual duels and a secret final trial.
- [x] Save candidate identity, attempt number, failure timestamp and permanent-license status; expose the next weekly retry time after a failed attempt.
- [x] Award the permanent HUNTER_LICENSE only after all seven ordered stage records are completed.
- [x] Add a Godot 4.3 automated validator for stage order, progression and permanent-license state.
- [ ] Build the seven actual challenge environments, puzzle/maze geometry, survival resources, cooking interaction, duel opponents and evidence verification; the tunnel gates are currently a briefing/route blockout, not seven finished playable environments.
- [ ] Add server-authoritative candidate identity, anti-cheat evidence validation and account-synced license persistence before multiplayer examinations.
- [ ] Run Godot 4.3 parser/import and in-engine collision, camera, interaction-ray, player-clearance, lighting, and Android performance checks.
- Note: this is a procedural architectural and interaction prototype inside the Hunter Association Tower. It does not yet teleport candidates into playable external challenge maps or validate exam evidence.

## Hunter Association public examination announcement — 21 November 2026

- [x] Add a large, clearly visible Arabic/English "Hunter Examination Center" sign directly above the tunnel entrance in the Association Tower lobby.
- [x] Add an official public notice board beside the entrance explaining registration, public information, announced candidate batches, and the registered/accepted-candidate entry rule.
- [x] Add an interaction on the public notice board that opens the existing Hunter Association information desk view.
- [x] Mark the exam center as publicly announced in the interior metadata; it is an official visible Association facility, not a hidden or secret tunnel.
- [ ] Verify sign and board readability, placement, collision, and interaction reach in Godot 4.3 and on Android.
- Note: the notice board does not invent fixed exam dates or imply that registration is currently open. The tunnel start gate still checks the existing local exam registration/state flow; final candidate eligibility and server authority remain future work.


## SYSTEM Nen discovery and individualized aura discipline — 21 November 2026

- [x] Add a dedicated SYSTEM Nen manager with six affinity families: enhancement, emission, manipulation, transmutation, conjuration, and specialization.
- [x] Make Nen discoverable by any registered eligible player or NPC character; discovery is a three-step insight journey rather than an automatic unlock.
- [x] Generate per-character affinity and aura-capacity traits from character identity/background seeds; different people can share an affinity family but retain individual profiles.
- [x] Reveal a character's affinity only after their own discovery is completed.
- [x] Add foundational Ten, Ren and Zetsu training progression with per-character training records.
- [x] Add a personal Hatsu technique creation gate that requires foundation training; technique naming and optional self-imposed vows are stored per character.
- [x] Persist local character Nen profiles and connect a mobile-friendly Nen panel to the main runtime.
- [x] Add a Godot headless validator and workflow step for discovery isolation, training requirements and personal technique creation.
- [ ] Integrate automatic registration and visible discovery/training storylines into every NPC population, mentors, guilds and world-specific locations; the manager currently exposes the shared character API but NPC population systems are not yet automatically wired to it.
- [ ] Expand combat abilities into balanced, animated, effect-backed techniques with stamina/aura costs, counterplay, restrictions and AI usage.
- [ ] Add online account synchronization, server-authoritative progression and anti-cheat validation; current saves are local-device prototypes.
- [ ] Run the new Godot 4.3 validator and full Android runtime tests on the latest PR head.
- Note: this is a first connected progression prototype, not a finished combat ability system. Nen is intended to be learnable by all eligible characters, but each character must discover it through their own path; NPC-wide automatic enrollment and actual combat execution remain pending.


## Building-first production scope and NPC role constraints — 21 November 2026

- [x] Keep the immediate development priority on completing physical buildings and their interiors before expanding unrelated gameplay systems.
- [x] Record the NPC role rules as world-design constraints: ordinary NPCs live natural lives and hold varied professions such as teachers, trainers, police officers, professors, doctors and merchants.
- [x] Keep NPCs out of the Hunter Exam candidate pool; NPCs serve as examiners and staff.
- [x] Keep gangs as the specific NPC faction exception that players may choose to join; do not turn ordinary NPC populations into universal fighters or supernatural combatants.
- [ ] Return to full map integration only after each building has a traversable interior, clear entrance/exit flow, functional interaction points and a registered map location.

## Baghdad civic buildings — structural interior completion pass — 21 November 2026

- [x] Replace the four civic venues' opaque solid facade blocks with separate wall sections and a real entrance opening.
- [x] Add collision-backed side, rear, front and lintel wall sections plus an interior floor collision for the mosque, church, city museum and rare-antiquities bazaar.
- [x] Match interior wall and roof heights to each venue type; preserve the mosque dome/minarets and church roof/towers above the visitor space.
- [x] Add venue-specific interior fixtures: prayer-hall mihrab/minbar, church altar/lectern/stained glass, museum reception/exhibit labels/display cases, and bazaar auctioneer/appraisal desks.
- [x] Add low-cost non-shadowing interior lighting to the four venues.
- [x] Extend the civic venue validator to instantiate all four interiors and check wall collision, entrance-side wall layout, floor collision and venue-specific props.
- [ ] Run the Godot 4.3 validator and visually verify door clearance, wall/floor alignment, roof coverage, interior scale and Android performance; source-level validation has not yet been executed.
- [ ] Replace placeholder exhibit labels and generic props with authored historically grounded collections, culturally reviewed architecture, NPC staff, schedules and interactive visitor experiences.
- [ ] Complete the remaining service buildings (schools/universities, hospitals, police/fire stations, hotels, markets, transport hubs, shops, libraries, cinemas, gyms and other civic services) with distinct room layouts and functional interiors.
- [ ] Integrate each completed building's entrance, interior navigation, service interactions and map marker into the unified city map and streamed region lifecycle.
- Note: this pass upgrades the four Baghdad civic interiors from open placeholder rooms to collision-backed traversable architectural shells with venue-specific fixtures. It does not yet mean all city buildings or all interiors are production-complete.


## Power Tower — first physical 200-floor exploration-world pass — 21 November 2026
- [x] Keep the independent exhibition arena separately accessible through its own stable Baghdad interaction; do not open its demo UI automatically when entering a 200-floor exploration environment.


- [x] Add a dedicated system_power_tower_floor_world.gd builder without replacing the existing 200-floor progression manager or the independent arena venue.
- [x] Generate a collision-backed, 520 m exploration ground and traversable route for the requested floor, instancing only the active floor to control memory and scene cost.
- [x] Generate deterministic region-specific environment layouts across the ten existing region profiles, with floor-seeded obstacle and landmark variation.
- [x] Add three physical checkpoint trigger areas and connect their player-entry events to the existing progression manager's ordered checkpoint records.
- [x] Add a physical boss-trial platform and spawn marker on every tenth floor, including the floor-200 finale.
- [x] Add a return gate that sends the player back to the Power Tower entrance while preserving reached checkpoints for a retry.
- [x] Route the Power Tower entrance interaction into the generated floor environment rather than sending every floor attempt to the same arena floor.
- [x] Extend the existing Power Tower validator and Godot workflow to check generated ground collision, all three checkpoint areas, checkpoint registration, and the floor-200 boss platform.
- [ ] Run the updated Godot 4.3 workflow on the new branch head and fix any parser/runtime issues it reports.
- [ ] Replace primitive environment geometry with authored biome assets, varied terrain elevation, water, caves, structures, lighting, sound, vegetation and navigation.
- [ ] Add actual floor-specific quests, secret discoveries with rewards, enemy populations, boss characters, combat objective verification, and a complete return/reward flow.
- Note: this is a first physical procedural exploration pass for all 200 floor IDs, not 200 individually hand-authored finished maps. Each active floor is generated from its region profile and stable floor seed; final art, enemy AI, quest content and runtime validation remain outstanding.


## Baghdad archaeological sites and ruins — OSM-grounded landmark pass — 21 November 2026
- [x] Classify historic memorials/monuments, tombs, heritage buildings, fortifications and city gates separately instead of rendering every historic tag as generic ruins.
- [x] Preserve worship identities for historic mosques/churches while allowing their heritage details to be built from the same OSM source.
- [x] Exclude explicitly named Kadhimiya/Kadhimain historic features from this current landmark pass.
- [x] Audit result from OSM source workflow run 44943717154: 318 historic-tagged source objects in the municipal extract; the initial 5×5 sample pack contains 4 historic geometry features from 3 unique OSM IDs, all tagged historic=memorial. This is source coverage, not proof of finished in-game assets.
- [ ] Inspect the 3 unique sample memorials in Godot and check their physical scale/placement; full municipal historic layer also contains named heritage buildings, tombs, gates, palaces and ruin features outside the initial sample cells.


- [x] Add a dedicated historic-sites OSM layer to the Baghdad extraction, clipping and metric cell-pack pipeline; retain historic tags and source feature IDs.
- [x] Stream the dedicated historic-sites layer into Baghdad cells and prevent duplicate ruin landmarks when a feature is also present in the buildings/amenities layers.
- [x] Recognize OSM archaeological_site, ruins, castle, fort and city_gate tags, plus building=ruins and site_type=archaeological.
- [x] Generate collision-backed outdoor ruin details for tagged ruin building footprints while retaining their source OSM feature IDs.
- [x] Support both historic point features and polygon/multipolygon archaeological site boundaries in the OSM amenity layer, with collision-backed ruin fragments and stable discovery interactions.
- [x] Generate outdoor archaeological landmark clusters, broken walls, columns, site names and stable discovery interactions for tagged OSM historic point features.
- [x] Extend the existing Baghdad OSM runtime validator with a synthetic tagged-feature regression for the archaeological landmark builder and its stable interaction ID.
- [x] Audit the verified source artifact and clipped municipal historic layer; distinguish source features from the smaller 5×5 sample-pack coverage and do not treat synthetic validator fixtures as real-world sites.
- [ ] Audit the installed runtime pack and confirm actual landmark coverage after the map-integration milestone.
- [ ] Add researched site-specific layouts, artifacts, environmental storytelling, guarded excavation areas, NPC archaeologists and discovery missions after real site coverage is confirmed.
- [ ] Install the verified candidate cell pack into the runtime only at the planned map-integration milestone; the current 5×5 source artifact is not yet installed, so the OSM landmark generator is prepared but not active in the live Baghdad scene.
- [ ] Run Godot 4.3 OSM runtime validation and inspect the tagged sites in the live Baghdad world once the pack is installed.
- Note: the builder only creates landmarks for source features carrying recognized historic/ruins tags. A synthetic validator fixture proves the builder path, not that a particular real archaeological site exists in the current Baghdad OSM sample.


## Baghdad football stadium — physical facilities and walk-in rooms — 21 November 2026

- [x] Expand only the Baghdad stadium footprint to fit the full-size 105 m × 68 m pitch, concourses and service rooms; other city stadiums retain their lighter footprint.
- [x] Convert the stepped spectator stands to collision-backed structures and batch visible seat rows with MultiMesh instances.
- [x] Add north, south, east and west physical access gates with stable Baghdad interaction IDs.
- [x] Add walk-in home/away team locker rooms, referee room, medical room, media room and press-conference room with floors, collision-backed walls, open doorways and basic furnishings.
- [x] Add a collision-backed player/official tunnel connecting the south concourse toward the pitch.
- [x] Add four stadium floodlight towers and a Baghdad stadium scoreboard.
- [x] Extend the existing Baghdad civic venue validator to check the stadium's facilities and room collision/entry nodes.
- [ ] Add ticket validation, secure spectator circulation, stair navigation, crowd NPCs, team/official schedules, dressing-room interactions and a complete football match simulation.
- [ ] Run Godot 4.3 validation and inspect the expanded stadium in the live Baghdad scene.

## Server-authoritative artifact player marketplace — 27 November 2026

- [x] Add authenticated Firebase callable endpoints for listing a player's owned artifact at a seller-selected SYSTEM Credits price, browsing open listings, purchasing, and seller cancellation.
- [x] Lock a listed artifact against duplicate listing/sale by recording its listing ID and listed state in the server-owned artifact record.
- [x] Execute buyer debit, seller credit, artifact ownership transfer, listing settlement, and immutable transaction-ledger creation in one Firestore transaction.
- [x] Reject unauthenticated users, invalid prices/IDs, self-purchases, already-closed listings, inconsistent ownership/locks, missing wallets, insufficient funds, and duplicate buyer item IDs.
- [x] Keep marketplace wallet, inventory and listing collections outside client-writable player systemData; the existing Firestore catch-all denies client writes to these new collections.
- [x] Add a GitHub Actions TypeScript compilation workflow for Firebase Functions; CI run 46038445917 passed the full dependency-install and TypeScript compile job on commit 96faef97.
- [ ] Provision marketWallets/{uid} and playerArtifacts/{uid}/items/{itemId} only from trusted server reward/account flows; existing local SYSTEM Credits and local artifact saves are not authoritative and are not automatically imported.
- [ ] Connect the Godot market UI to Firebase callable endpoints and remove local-wallet/local-inventory claims from the online marketplace path while preserving the offline prototype as an explicitly separate mode.
- [ ] Add emulator-backed transaction tests for concurrent buyers, duplicate requests, seller cancellation races, insufficient balance, and rollback on failed ownership transfer.
- [ ] Deploy Firebase Functions and verify authenticated end-to-end transactions in a controlled test environment before enabling player-to-player trading.
- Note: the server transaction path is implemented in functions/src/artifact_market.ts but is not live until server-owned wallets/artifact inventory are provisioned and the client is connected. No real player credits or artifacts have been moved by this code yet.


## Modern city greenery and pedestrian density pass — 27 November 2026

- [x] Preserve the existing modern-world map, city anchors, Baghdad OSM cell pack and streaming architecture; this pass does not regenerate or replace the map.
- [x] Replace the twelve isolated green-belt discs per city with dense park pockets: each valid pocket receives up to five trees and eight shrubs, with terrain/land checks and batched MultiMesh rendering.
- [x] Raise natural forest vegetation counts from 28 to 36 trees, 24 to 48 shrubs, and 90 to 150 ground-cover clumps.
- [x] Raise the visible civilian pedestrian cap from 32 to 72 and reduce resident refresh churn by moving the refresh interval from 3 to 5 seconds.
- [ ] Run Godot 4.3 import, city-generation runtime and visual inspection to verify park placement, tree/shrub transforms, pedestrian variety and collision/navigation clearance.
- [ ] Profile Android frame time, memory and thermal behavior with the denser park meshes and 72 visible civilian actors; tune LOD/streaming from measured results before calling density complete.
- [ ] Verify that Baghdad's streamed OSM cells receive equivalent dense public-park landscaping where the city-cell content is loaded.
- Note: source implementation is committed; the map itself is preserved. Density and mobile performance are not yet runtime/visual verified.


## High-density city population, commercial streets and industrial district — 27 November 2026

- [x] Increase Baghdad's seeded civilian society target to 8,500 adults plus 1,500 minors; residents are created in batches across frames to avoid one large startup loop.
- [x] Expand deterministic resident home placement from a 5 × 5 cluster to a 41 × 41 city-block grid.
- [x] Select the nearest living residents to the player for the bounded visible actor pool instead of always rendering the first records in the society list; retain a 72-actor visible cap pending mobile profiling.
- [x] Add twelve individually named commercial tenants to the shopping street: restaurant, cafe, bakery, sweets, clothing, shoes, perfume, electronics, mobile, furniture, supermarket and industrial hardware/parts.
- [x] Add a dedicated industrial/workshop district with six marked units: metalwork, carpentry, auto parts/repair, building materials, textiles and warehousing.
- [x] Add source-level Godot validation for population targets, distributed placement, nearest-resident streaming, commercial categories, industrial units and the existing batched vegetation helper.
- [ ] Run the updated Godot 4.3 workflow and fix any parser/runtime failures before marking this pass tested.
- [ ] Verify that the 10,000 society records seed and save/load correctly on a real Android device; measure startup hitch, memory, CPU and frame pacing.
- [ ] Add working shop inventories, staff/customer schedules, checkout/economy integration, manufacturing/warehouse production chains and real walk-in interiors; current new tenant rows are marked visual/interaction foundations, not finished retail simulations.
- [ ] Extend the population simulation to other cities and rural settlements only after the Baghdad seed, save/load and mobile performance are measured.
- Note: 10,000 is the authored Baghdad resident-society target, not 1,440 simultaneously rendered 3D characters. The visible crowd remains distance-selected and capped at 72 for mobile safety; all residents are not rendered at once.
