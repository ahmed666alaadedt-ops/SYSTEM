# SYSTEM WORLD — Modern World Completion Tracker

## Baghdad tower mobile combat integration — 22 November 2026

- [x] Instantiate the existing ModernWorldCombatSystem in the live modern-world startup and explicitly bind it to the active player, camera, and progression manager.
- [x] Connect mobile attack, skill-one, skill-two, and dodge signals to real combat actions; ignore combat actions while driving.
- [x] Connect skill one to the existing rank-four Nen Burst, applying its timed damage/defense/movement/cooldown effects before the empowered strike.
- [x] Connect skill two to a charged heavy strike that consumes weapon durability and uses progression/elixir damage bonuses.
- [x] Extend the Baghdad tower operations validator to verify combat-manager creation, player binding, mobile signal wiring, Nen Burst activation, charged strike, and dodge movement.
- [ ] Inspect touch-control placement and combat feedback on a physical Android device; balance hit range, strike damage, and cooldown feel.

This is the acceptance checklist for the modern-world map. The project must not be described as complete, and work must not move to the portal phase, until every required item is implemented, connected, and verified in Godot on the target platforms. A visual placeholder is not accepted as a completed gameplay system.



## Baghdad five-tower district role update — 22 November 2026

- [x] Replace the former Business and Investment Tower identity with the Weapons, Equipment and Elixirs Tower; keep the district at exactly five connected primary towers.
- [x] Preserve the existing tower site and connected-district membership for this replacement; update its stable landmark ID and the public event-board node mapping together.
- [x] Define the tower's equipment scope: swords, spears, axes, bows, firearms, shields, helmets, armor, combat outfits, and equipment upgrades.
- [x] Define its elixir scope: Nen acquisition, Nen control and ability development, healing, strength, speed, endurance, energy, and rare/legendary elixirs.
- [ ] Build the tower's navigable interior, shops, crafting stations, inventories, purchase/equip flows, elixir recipes, and progression-safe unlock rules.
- [ ] Implement and balance Nen-acquisition/development systems and elixir effects; no elixir or Nen gameplay is claimed to be playable by this landmark metadata.
- [ ] Add server-authoritative inventory, trading, crafting, anti-duplication, and save synchronization before online economy use.
- [ ] Run Godot parser/import, scene startup, interaction, visual inspection, Android performance, and physical-device tests; this role replacement is source-level only until those checks pass.
- Note: the tower remains a procedural exterior landmark and connected-district member. Its actual interior and equipment/elixir gameplay are unfinished. The standalone 200-floor Power Tower remains separate and unchanged.


## Baghdad tower exterior identity and public display coverage — 22 November 2026

- [x] Add a distinct architectural identity pass for the Hunter Association Tower, Weapons/Equipment/Elixirs Tower, Shopping Tower, Entertainment/Sports Tower, and Technology/Innovation Tower.
- [x] Add a separate tournament/champion identity detail to the standalone Power Tower without adding it to the connected district.
- [x] Store each landmark's floor count, approximate height, and connected-district membership as node metadata.
- [x] Add the Technology Tower to the Baghdad tower public advertising/champion display node map; all five connected towers and the standalone Power Tower now have explicit node mappings.
- [ ] Verify the new procedural identity geometry in Godot for scale, overlaps, silhouette, collision, readability, river/Tahrir view corridors, and Android rendering cost.
- Note: this pass adds exterior identity blockout meshes and metadata only. No tower interior, elevator ride, shop transaction, equipment equip flow, elixir effect, or live online leaderboard is claimed complete.

## Baghdad tower entrance directory metadata — 22 November 2026

- [x] Attach floor count, approximate height, and connected-versus-standalone status to each tower entrance interaction marker.
- [x] Extend the existing interaction response with a tower directory for Hunter Association, Weapons/Equipment/Elixirs, Shopping, Entertainment/Sports, Technology/Innovation, and the standalone Power Tower.
- [x] Explicitly label floor directories as informational until real interior floors and elevator transitions exist; do not imply that selecting a tower entrance grants access to all floors.
- [ ] Replace the text-only directory with a mobile-friendly interactive floor selector and validated elevator transitions after interior scenes and collision-safe arrival points exist.
- [ ] Test entrance targeting and directory readability in Godot and on Android; no physical-device visual test is claimed.

## Baghdad public tower lobby pavilions — 22 November 2026

- [x] Generate an accessible ground-level open lobby pavilion at each of the five connected towers and the standalone Power Tower.
- [x] Add a walkable lobby floor with collision, a canopy, support columns, a directory kiosk, and a visible tower-name sign.
- [x] Add ray-interactable directory kiosks carrying the tower ID, floor count, height, and district membership without registering duplicate map landmarks.
- [x] Route both tower entrance markers and lobby kiosks through the same Arabic tower-directory response; keep the Power Tower floor-request status visible after the directory.
- [ ] Replace pavilion blockouts with detailed architectural lobbies, security/reception, NPC staff, doors, accessible circulation, and real tower-core connections.
- [ ] Implement elevator cars, floor selection, travel transitions, interior floor scenes, emergency stairs, and validated collision/navigation.
- [ ] Verify all lobby geometry and interactions in Godot and on Android; current code is source-level and automated validation is pending.

## Baghdad tower floor zoning and reception blockouts — 22 November 2026

- [x] Define floor zoning for the Hunter Association headquarters, Weapons/Equipment/Elixirs, Shopping/Commerce, Entertainment/Sports, Technology/Innovation, and standalone Power Tower.
- [x] Attach floor zoning data to the tower root, public entrance, and lobby directory kiosk.
- [x] Display the floor ranges and department labels on each lobby's 3D directory sign.
- [x] Add a first-pass reception counter and security-gate frame to each public lobby pavilion, with collision on the counter and gate posts.
- [ ] Turn the reception/security blockouts into staffed, functional access control with faction/rank/permit checks, NPC staff, queues, and accessibility support.
- [ ] Implement floor-specific interior scenes, real elevator travel, stairwells, floor arrival points, and safe return/exit transitions.
- [ ] Validate lobby collision, sign legibility, interaction reach, and mobile performance in Godot and on Android.

## Baghdad enclosed lobby and lift-core blockout — 22 November 2026

- [x] Enclose the public lobby with collidable side walls and split back/front wall sections while preserving a clear walk-in entrance.
- [x] Add a lift-core door visual and collision panel at the back of each lobby; explicitly mark it as a visual-only placeholder.
- [x] Preserve the separate reception counter, security gate, directory kiosk, floor zoning sign, and walkable floor.
- [ ] Cut a real lift-core opening into the tower shell and connect it to safe, navigable interior floor scenes; the current lift door is closed and non-functional.
- [ ] Add glazing, automatic doors, accessibility routes, lighting, interior materials, and detailed architecture after the collision layout is validated.
- [ ] Run Godot interaction/collision traversal and Android visual/performance tests for all six lobbies.

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
- [x] Add first-pass discoverable service-location definitions for hospitals, police/fire stations, hotels, markets, garages, schools, universities, football stadiums, shopping streets, restaurants, banks, malls, pharmacies, bakeries, cafes, fuel/charging stations, public parks, bus stations, post offices, libraries, rail stations, harbor terminals, cinemas, and fitness centers.\n- [ ] Turn these service-location prototypes into fully functioning interiors, jobs, inventories, transactions, medical/legal services, public transport schedules, and interactive recreation.
- [ ] Add residents, pedestrians, vendors, workers, schedules, crowds, public services, and city activity that responds to time and weather.
- [ ] Make the ten rural settlements functional and connect them to roads, services, farms, orchards, fields, and local economies.

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


## Baghdad connected five-tower district plus separate Power Tower — design direction updated 22 November 2026

- [ ] Build the five distinct district landmark towers as one connected vertical urban district spanning central Baghdad's Karkh–Rusafa corridor; build the standalone Power Tower as a separate destination outside that network.
- [ ] Keep the Tigris visibly open and flowing beneath the district; preserve the river channel, riverfront access, navigation clearance, and views.
- [ ] Preserve Tahrir Square and the Freedom Monument as recognizable, explorable public landmarks on the Rusafa side; do not cover, replace, or overwhelm them.
- [ ] Connect the five towers with skybridges, elevated promenades, public terraces, and carefully designed cross-river links while keeping the river unobstructed below.
- [ ] Create a multi-level public district with ground streets/plazas, mid-level shopping and services, and upper sky gardens/recreation decks.
- [ ] Implement the five connected district identities: Hunter Association, Weapons/Equipment/Elixirs, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation.
- [ ] Keep the 200-floor Power Tower separate, with its own entrance/map marker; exclude it from the five-tower skybridge and vehicle-deck loop.
- [ ] Add accessible pedestrian routes, transit access, emergency/service circulation, wayfinding, and clear public connections to the existing Baghdad street network.
- [ ] Validate the district in Godot from Karkh, Rusafa, Tigris riverfront, and Tahrir Square viewpoints; ensure the Freedom Monument and river remain visually legible.
- Design approval/documentation is recorded in `HUNTER_TOWERS_AND_EXAMINATION_DESIGN.md`. The connected city, bridges, detailed interiors, and river engineering are not yet implemented or runtime-tested; the six-landmark source correction is on a feature branch pending Godot validation.


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
- [x] Record the five connected district identities: Hunter Association, Weapons/Equipment/Elixirs, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation; keep Power Tower separate.
- [x] Expand the separate Power Tower progression model to 200 floors; playable interiors, opponent encounters, and server-verified records remain open.
- [x] Add an initial procedural five-tower district blockout with elevated promenade/vehicle-deck link geometry and ramp-segment placeholders; add the separate Power Tower landmark outside that connection loop.
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
- [x] Add facade-mounted advertising and results panels to the five connected Baghdad towers plus the standalone Power Tower: Hunter Association, Weapons/Equipment/Elixirs, Shopping, Entertainment, Technology, and Power.
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


## Mountain cave passage blockout — 21 November 2026

- [x] Add `scripts/modern_world_cave_passage_manager.gd` for the four existing mountain cave sites without moving their coordinates or changing the continent.
- [x] Generate a walkable passage floor with static collision, side-wall collision, an arched ceiling mesh, and a larger inner chamber floor.
- [x] Tag each generated passage as a cave landmark and mark it explicitly as geometry blockout requiring runtime validation.
- [ ] Add validated entrance-to-building association, proper terrain excavation, complete chamber wall/ceiling collision, cave lighting, audio, navigation, discovery persistence, and player interaction.
- [ ] Run Godot parser/import, scene startup, collision traversal, and Android performance tests. The new geometry is committed source code and has not yet been run in Godot or on a device.

## Baghdad tower lobby Godot validation — 22 November 2026

- [x] Godot 4.3 resource import and GDScript parse passed on branch commit `f97aebce63ac06076bb622f5c0b32a619e3a3b81` in GitHub Actions run [45035625980](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45035625980).
- [x] Runtime scene missing-mesh scan and headless main-scene launch passed in the same run.

- [x] Add a dedicated Godot SceneTree validation script and CI step for six tower landmarks, exactly five connected towers, Power Tower separation/200 floors, lobby collision/kiosks/signs, floor zoning, weapon/elixir categories, and Technology public-display mapping.
- [x] First structural validation exposed that the original Shopping Tower plot had no nearby land inside the initial 192 m search radius; widen the local land search and relocate the Shopping Tower to the nearest generated land point.
- [x] Re-run the structural validation successfully on commit `9f32efa09e64a51e5ff807b5634430ce2af5e4c7`, GitHub Actions run [45035977040](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45035977040): all six towers were generated, five remain connected, Power Tower remains separate at 200 floors, all six lobby kiosks/floor directories exist, and Technology is present on the public event board.
- Note: the Shopping Tower plot was relocated by 264 m, Power Tower by 96 m, and Technology Tower by 48 m in this runtime layout. Godot visual review must confirm the final positions remain coherent with the Baghdad district, Tigris corridor, and protected Tahrir Square/Freedom Monument views.

- [x] Canonical SYSTEM WORLD Android APK export and artifact upload passed on the same code commit in GitHub Actions run [45035977001](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45035977001).
- [ ] Install and inspect that APK on a physical Android device; export success does not establish mobile visual quality, touch interaction, collision traversal, or frame-rate performance.

- [ ] Visual review of the six tower lobbies, collision traversal, kiosk ray targeting, sign readability, and Baghdad landmark sightlines remains pending; headless launch does not verify visual quality or gameplay interaction.
- [ ] Canonical Android APK export and physical-device review remain pending for the current branch head.



## Baghdad tower operations, NPC workforce, commerce, interiors and Power Tower runtime — 22 November 2026

Implementation added on the feature branch; automated runtime validation is pending.

- [x] Add system_baghdad_tower_operations_manager.gd and connect it to the canonical main scene.
- [x] Generate four persistent civilian NPC employees for each of the six Baghdad towers (24 staff total): tower-specific service roles plus a dedicated advertising manager. Staff identity and employer/location data are stored in the existing NPC society records.
- [x] Add visible, ray-interactable employee characters in each public lobby. Interacting with an employee opens the relevant service panel.
- [x] Add local-session player credits, persistent wallet storage, NPC-supervised purchase transactions, inventory item grants, and sale of owned inventory items back to tower staff.
- [x] Add initial catalogs for weapons, armour, shields, Nen/elixir items, shopping supplies, entertainment tickets, technology devices, and Hunter supplies.
- [x] Add rotating NPC-managed advertising text to internal lobby displays and external tower advertising displays; each tower's advertising manager is identified in the campaign label.
- [x] Add on-demand procedural interior floor rooms for all six towers, with floor collision, perimeter walls, department signage, service kiosks, and elevator return markers.
- [x] Add an elevator travel transition between the lobby and selected floor; generated floor rooms are unloaded when leaving to limit mobile memory/render cost.
- [x] Keep Power Tower progression independent and sequential across 200 floors; the operations manager requests the next floor through the existing progression manager.
- [x] Add a reusable Power Tower opponent actor with health, pursuit movement, close-range attacks, and damage handling compatible with the modern combat raycast.
- [x] Spawn opponent waves from each floor's challenge data; boss floors spawn a stronger boss opponent. Completing the final wave calls the existing trusted floor-clear integration hook and awards the configured XP/rank.
- [x] Generate distinct first-pass arena obstacle layouts from duel, team, survival, elite, championship, and boss-trial floor profiles; floor 200 is configured as a boss trial.
- [x] Abandon an active Power Tower attempt without crediting a clear if the player is wounded; return the player to the lobby for hospital treatment.
- [ ] Pass the new Godot 4.3 operations validator and inspect any runtime errors from the current CI run.
- [ ] Review the generated interiors, NPC models, elevator movement, arena combat and mobile frame rate in a physical Android build.
- [ ] Expand the generic procedural floor rooms into individually authored, themed floors with complete department-specific activities and interactive furnishings.
- [ ] Add actual equipment/equip slots and balanced, functional Nen/elixir effects; current purchases are inventory items only and do not yet grant combat/stat effects.
- [ ] Add crafting recipes/stations, upgrade materials, stock refresh, NPC vendor restocking, and supply-chain/economy simulation.
- [ ] Replace the local wallet with server-authoritative currency, inventory, trade validation, anti-duplication and cloud save before enabling online trade or real-value purchases.
- [ ] Connect advertisements to a governed campaign system with campaign ownership, pricing, moderation, display scheduling, and any future revenue accounting. Current campaigns are local in-game display content, not paid external ad inventory.
- [ ] Build authoritative online matchmaking, player rankings, anti-cheat verification and multiplayer spectator systems for Power Tower. Current floor records and rewards use the existing local save path.
- Note: the current commit implements a playable first-pass systems layer and generated floor geometry, not a production-complete commercial economy or 200 individually handcrafted arena scenes. The PR remains draft and must not be merged into main without explicit user approval.


### Elevator cabin and Power Tower final sovereign trial extension — 22 November 2026

- [x] Add a visible elevator cabin with floor/roof panels, glass side walls, sliding doors and an animated car/player transition between lobby and selected tower floor.
- [x] Allow the floor directory/elevator marker inside a generated floor to reopen the floor selector; the player can choose another floor or return to the lobby.
- [x] Keep only the active generated floor room loaded during normal tower traversal; free the cabin after a return to the lobby.
- [x] Mark Power Tower floor 200 as the unique FINAL_BOSS/SYSTEM SOVEREIGN trial, with a distinct large gold boss visual, stronger health profile, shockwave attack, special arena platform and completion reward.
- [x] Add Power Tower loot items: routine tokens, milestone fragments, boss cores, and the unique sovereign crown/core reward on floor 200.
- [x] Ensure floor 200's level requirement is 90, within the existing 100-level player cap.
- [ ] Pass the latest CI run covering elevator cabin travel/return, final boss metadata/rewards, NPC staff, trading and ads.
- [ ] Inspect elevator camera clearance, cabin door alignment, player landing/collision and floor-room visibility on a physical Android device.
- [ ] Complete individual arena art, final boss attack telegraphs/animations, boss phase changes, reward balance, online leaderboard verification and spectator/matchmaking features.


### Equipment, elixir and Nen first-pass functionality — 22 November 2026

- [x] Add persistent weapon, shield, armour, helmet and outfit equipment slots.
- [x] Apply equipped weapon damage bonuses to the existing light/heavy combat hitscan.
- [x] Apply equipped shield/armour/helmet defense bonuses to incoming combat damage, with a bounded reduction so attacks cannot become zero-damage.
- [x] Add timed strength, speed, endurance, energy and rare/legendary elixir effects to damage, movement, defense and attack cadence.
- [x] Add healing elixir field recovery while preserving the existing persistent wounded state; a healing elixir cannot replace hospital treatment.
- [x] Add Nen acquisition unlock and control rank progression (rank 1–5) through the corresponding elixirs.
- [x] Add NPC employee service controls to equip owned gear, consume owned elixirs, unequip items and prevent sale of currently equipped gear.
- [ ] Pass current Godot validation for progression save/load, combat integration and the extended tower/elevator transaction validator.
- [ ] Add visible 3D weapon/armour attachment models, weapon-specific attack animations, shield blocking integration, and real Nen abilities/aura techniques.
- [ ] Add elixir crafting, ingredient sourcing, recipes, cooldown/stacking rules, balance and anti-exploit validation.


### NPC vendor economy, crafting stations and final Power Tower challenge — 22 November 2026

- [x] Add persistent vendor stock by product, stock-sensitive buy/sell prices, restocking every five real-time minutes and stock persistence.
- [x] NPC vendors reduce stock on purchase and take player items back into stock on sale.
- [x] Add the Weapons Tower blacksmith and elixir laboratory benches, each linked to its assigned NPC employee service.
- [x] Add recipe-based crafting for swords, spears, axes, bows, shields, armour, helmets, outfits, healing/strength/speed/endurance/energy elixirs and Nen/rare elixirs.
- [x] Add raw material purchasing and Power Tower milestone/boss material drops to support crafting.
- [x] Add interactive service kiosks on public tower floors and interactive lift doors in all six lobbies.
- [x] Add a Power Tower lobby progress board showing cleared floors and the 200-floor target.
- [x] Add final-boss shockwave warning and three combat phases; floor 200 also grants a unique crown, sovereign core, rare core, Nen fragment and bonus SYSTEM credits.
- [ ] Pass the newest CI run after the vendor stock, crafting-station and lobby-lift extensions.
- [ ] Add visual weapon/armour attachments, weapon-specific animations, real Nen abilities, crafting discovery/upgrade/repair systems and physical Android interaction/performance review.
- [ ] Add online/server-authoritative wallet, vendor stock, player leaderboard and multiplayer Power Tower matchmaking; current economy/progression/records are local.


### Power Tower challenge objective pass — 22 November 2026

- [x] Survival arena floors now run timed survival objectives with sequential enemy waves; surviving until the timer ends clears the floor.
- [x] Championship arena floors now require clearing all waves before their time limit; failure abandons the attempt and leaves the same floor available for retry.
- [x] Arena signage displays the active objective and live countdown; the timer begins only after the elevator reaches the floor.
- [x] Automated validator checks every floor from 1 to 200 for valid level gates, boss cadence, wave counts, rewards and timed objective profiles.
- [x] Latest Godot 4.3 validation workflow passed on the current tested source revision, including all tower, NPC commerce, crafting, equipment/elixir/Nen, elevator and Power Tower checks.
- [ ] Latest Android APK export workflow is still running; physical Android visual/touch/performance review remains outstanding.


- [x] Power Tower lobby board now shows the player's highest cleared floor, next floor, progression rank, completion percentage and personal best clear time. This is a local personal record, not a global online leaderboard.


### Equipment durability, upgrades and repair — 22 November 2026

- [x] Equipment durability decreases when weapons are used and armour/helmets absorb hits; shields wear while actively blocking.
- [x] Broken equipment stops contributing its damage/defense bonus until repaired.
- [x] NPC employees offer equipment upgrades through +10, with level and material costs; higher upgrades require rare cores and Nen control rank.
- [x] Repair kits can be purchased or crafted; the NPC repair service restores equipment durability.
- [x] Player inventory displays equipped item upgrade levels and durability.
- [x] Latest Godot 4.3 validation passed after durability/upgrade/repair integration.
- [x] Latest canonical Android debug APK export passed at HEAD \`3646251e0d9834e885d845656bb52e92a8fc1c12\`; artifact \`SYSTEM-WORLD-canonical-android-debug-apk\` expires 6 December 2026.
- [ ] Physical Android device gameplay/touch/performance review remains pending.


### Nen awakening elixir and Hunter Association strike demonstration — 22 November 2026

- [x] Rename the player-facing item and crafting recipe to **إكسير إيقاظ النِن**; it awakens Nen and is not an attack or combat skill.
- [x] Preserve existing saves by migrating the old `nen_acquisition_elixir` inventory key to `nen_awakening_elixir`; the old item ID remains accepted by the consume method for compatibility.
- [x] Keep the actual Nen strike as a separate combat ability. The Hunter Association Tower now exposes a dedicated training-demo entry, with a visual preview before awakening and the real strike after Nen reaches control rank 4.
- [x] Keep the awakening elixir in the Weapons/Equipment/Elixirs Tower catalog and crafting laboratory; the Nen strike demonstration belongs to the Hunter Association Tower.
- [ ] Run the updated Godot validator and canonical Android APK export; physical-device touch/visual review remains pending.
- Note: the pre-awakening preview is a visual training effect only; it does not unlock Nen, consume an item, or deal damage. The real combat strike still uses the existing combat system and its normal rank/cooldown requirements.

### Baghdad tower interior identity pass — 22 November 2026

- [x] Add a dedicated reusable floor-theme builder for the five connected Baghdad towers.
- [x] Give the Weapons/Equipment/Elixirs Tower a forge, equipment-display and elixir-laboratory visual identity.
- [x] Give the Shopping Tower retail display, market and visitor-rest areas.
- [x] Give the Entertainment/Sports Tower event, fitness and audience-area visual identity.
- [x] Give the Technology/Innovation Tower robotics, test-platform and data-lab visual identity.
- [x] Give the Hunter Association Tower mission, training, registry and Hall-of-Honor visual identity.
- [x] Attach stable floor-theme metadata and department labels to generated rooms; preserve on-demand floor generation and single-active-room memory behavior.
- [x] Extend the Godot operations validator to require a distinct theme root and themed station props on each of the five connected tower floors.
- [ ] Run the latest Godot 4.3 validator and Android APK export on the new commit; inspect any failures before claiming the theme pass validated.
- [ ] Replace the current themed visual blockouts with finished art, fully interactive department activities, staff schedules, and physical-device visual/performance verification.
- Note: this pass adds tower-specific visual identity and department set dressing. It does not claim that every floor has unique hand-authored geometry or that the displayed stations are all independently playable.

### Godot validator correction — 22 November 2026

- [x] Investigate the first tower-theme validation run. The new validator incorrectly required the five connected Baghdad department themes on the separate Power Tower.
- [x] Keep the five-department theme assertion scoped to the five connected Baghdad towers.
- [x] Validate the independent Power Tower against its own arena challenge display and arena metadata instead.
- [x] Re-run Godot validation and Android export on this corrected commit; both passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Hunter Association rooftop helicopter landing pad — 22 November 2026

- [x] Add a dedicated rooftop helicopter landing pad physically attached to the Hunter Association Tower; it is not a sixth tower and is not part of the standalone Power Tower.
- [x] Add a circular landing deck, static deck collision, painted landing circle and H marking, eight perimeter lights, identity sign, and a collision-backed access bridge to the tower roof.
- [x] Tag the facility with its Hunter Association owner ID and an explicit landing-zone radius for future helicopter runtime integration.
- [x] Extend the Baghdad tower Godot validator to check pad ownership, deck/collision, markings, sign, bridge collision, and all eight perimeter lights.
- [x] Pass Godot 4.3 parsing, headless scene startup and the extended tower validator on the current PR head.
- [x] Attach a dedicated Hunter Association helicopter runtime controller to the pad; generate a parked helicopter model with animated main/tail rotors.
- [x] Add pilot enter/exit flow, keyboard flight inputs, on-screen mobile ascend/descend/directional controls, and camera follow while piloting.
- [x] Add approach-distance interaction, a defined 18 m landing radius, low-speed landing state, and exit restriction while airborne.
- [x] Require completion of all Hunter examination stages before allowing helicopter pilot access; unlicensed players receive a clear denial message.
- [x] Add a physics-space shape query before each flight movement step to block movement into collidable world geometry.
- [x] Pause the on-foot player movement loop while piloting so the character controller cannot fight the aircraft controller.
- [x] Expose pilot authorization in the runtime status for automated verification.
- [x] Track simultaneous touch-button presses independently so releasing one direction does not cancel another held direction.
- [x] Pass Godot 4.3 parsing, headless startup and the expanded helicopter runtime validator on PR head `8edf22ac6551c9668e1e5da17c2a466bf06b06b7`.
- [x] Pass canonical Android APK export on the same PR head; artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,802,382 bytes) uploaded successfully.
- [ ] Add robust aircraft body collision, terrain-aware flight physics, emergency landing, aircraft parking persistence and flight safety validation.
- [ ] Review rooftop approach clearance, touch layout, camera behavior, collision traversal, lighting and Android performance on a physical device.
- Note: this is a first playable flight prototype using scripted movement and a procedural helicopter blockout. It is not yet a production aircraft physics model, and membership permissions and obstacle collision are still pending.


### Hunter examination continuity — 22 November 2026

- [x] Fix the active-exam resume branch: a saved in-progress examination now returns its current stage instead of incorrectly rejecting the player as already registered.
- [x] Prevent a fully completed examination from reopening with `exam_active = true`; completed candidates receive the explicit `ALL_STAGES_COMPLETED` result.
- [x] Extend the Baghdad tower operations validator to test both active-exam resume and completed-exam closure.
- [x] Correct the helicopter pilot-authorization lookup and validator to use the actual runtime node name `SYSTEMHunterExamManager`, discovered by the first regression run.
- [ ] Pass the updated Godot 4.3 validator and canonical Android APK export on the latest PR head.
- [ ] Test the full seven-stage examination, app restart/resume, license persistence, and pilot-permission unlock on an Android device.


### Power Tower entry safety and progression gates — 22 November 2026

- [x] Prepare the selected floor room and elevator cabin before reserving an active Power Tower challenge, preventing a failed room/cabin setup from leaving the progression manager locked on an active floor.
- [x] Add automated progression regression checks for sequential floor access, player-level requirements, duplicate active-floor requests, and rejection of clear reports for floors that were never activated.
- [x] Pass Godot 4.3 parser, complete Baghdad tower operations validator, and canonical Android APK export on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.
- [ ] Verify the full 200-floor progression, save/reload continuity, boss floors, rewards and failure/abandon recovery through extended automated gameplay tests and Android device testing.


### Baghdad tower interaction prompt alignment — 22 November 2026

- [x] Update the in-world tower interaction prompt: the floor selector and elevator travel are available, while unfinished tower services/interior details remain explicitly marked as in development.
- [x] Pass the latest Godot operations validation and canonical Android APK export after the Hunter exam, Power Tower and prompt updates on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Hunter examination regression fixture correction — 22 November 2026

- [x] Correct the automated test fixture to use a typed empty stage-ID array when switching from the completed-candidate test profile back to the unlicensed profile; this prevents stale completed-stage data from contaminating the helicopter authorization assertion.
- [x] Re-run the full Godot operations validator and Android export on the corrected head; both passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Hunter helicopter authorization test isolation — 22 November 2026

- [x] Explicitly mark the helicopter regression-test profile as unregistered after the completed-exam regression case, so the negative pilot-authorization test cannot inherit the prior candidate's completed-stage state.
- [x] Re-run Godot 4.3 operations validation and canonical Android export on the isolated test profile; both passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Helicopter flight-loop regression coverage — 22 November 2026

- [x] Extend the Godot operations validator to grant a test-only completed Hunter license, enter the aircraft, verify player-control handoff, command takeoff, command a controlled landing inside the pad radius, and verify safe exit restores on-foot controls.
- [x] Capture the player's prior physics-processing state when boarding and restore that exact state on exit instead of assuming it was always enabled.
- [x] Pass the Godot 4.3 flight-loop regression test on commit `999431189fa50161d09f6cd95e964b4596e510d4`.
- [x] Pass canonical Android APK export on the same tested source head; artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,805,824 bytes) uploaded successfully.
- [ ] Perform physical Android touch-control, rotor/clearance, flight feel, and performance testing; automated headless checks do not replace device inspection.


### Mobile-responsive Baghdad tower operations UI — 22 November 2026

- [x] Resize the tower operations panel to the current viewport, keeping it centered and bounded for phone portrait and landscape layouts.
- [x] Recalculate panel dimensions when the viewport changes orientation or size.
- [x] Add automated sizing assertions for 360×780 portrait and 780×360 landscape viewports.
- [x] Pass Godot 4.3 parsing, full Baghdad tower operations validation and responsive-size assertions on UI source commit `b5bcf4b04bdd45888874d0b4591c8f7668f7ec90`.
- [x] Pass canonical Android APK export on the same UI source head; artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,806,414 bytes) uploaded successfully.
- [ ] Inspect the actual panel on the HONOR 50 after installation, including portrait/landscape layout and scrolling.


### Responsive panel viewport API correction — 22 November 2026

- [x] Use Viewport.get_visible_rect().size from the Node-based operations manager; get_viewport_rect() belongs to Control/CanvasItem and is not available on this Node.
- [x] Re-run Godot parser, responsive-size assertions, full tower operations validator and Android APK export; all passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Latest verified PR-head CI — 22 November 2026

- [x] Godot 4.3 import/parse, headless main-scene startup, Baghdad tower landmark/lobby validation, and tower interior/NPC commerce/advertising/Power Tower boss-arena validation passed on `d3b92ded6a95a444f23c5bb849529af4e586d467` (workflow run `45047696991`).
- [x] Canonical Android debug APK export and upload passed on the exact same PR head (workflow run `45047696994`); artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,802,758 bytes, expires 6 December 2026.
- [ ] Physical Android device testing remains outstanding; automated CI does not verify touch feel, visual alignment, frame rate, or real-device stability.


### Hunter Association helicopter parking persistence — 22 November 2026

- [x] Save the helicopter's parked local position and orientation to the local Godot user profile when the pilot safely exits after landing.
- [x] Restore the saved parked transform when the Hunter Association helicopter controller is initialized after an app restart.
- [x] Keep boarding anchored to the aircraft's actual saved parking location and place the pilot on detected ground beside the aircraft after landing, including emergency landing away from the rooftop pad.
- [x] Pass the extended Godot regression for re-boarding at the saved location and safe nearby exit placement on tested source HEAD `a0ddf2497f4137eab3c5fc25d97afe55d34b38d8` (Godot run `45053166540`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,810,487 bytes, expires 6 December 2026 (Android run `45053166565`).
- [x] Reject malformed saved transform values and out-of-bounds parking coordinates, falling back to the designated rooftop spawn.
- [x] Extend the Baghdad tower operations validator to save a test parking transform, reload it, and assert that the parked position is restored.
- [x] Expand swept-position clearance checks to cover the fuselage/tail boom, the full main-rotor disc, and the tail rotor instead of checking only the center body.
- [x] Pass Godot 4.3 parsing, headless startup, full Baghdad tower operations validation, helicopter parking position/orientation persistence, controlled emergency landing, and main-rotor obstacle-clearance regression on tested source HEAD `5253e8a5becbfc5745a95b13f82f2c58111d11a7` (workflow run `45052867549`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,810,354 bytes, expires 6 December 2026 (workflow run `45052867541`).
- [ ] Verify parking persistence across a real Android app force-close/relaunch cycle; CI uses an isolated test profile and does not prove device persistence.
- Note: this is local-device parking persistence only. It does not synchronize the aircraft location between online players or across devices.


### Power Tower full progression and save/reload regression — 22 November 2026

- [x] Extend the Godot operations validator to simulate sequential requests and confirmed clears for all 200 floors using a level-100 test profile.
- [x] Verify that each floor can only be requested after the previous floor has been cleared and that every clear writes its personal clear-time record.
- [x] Instantiate a fresh progression manager after the 200-floor run and verify that floor 200, completion status, and all 200 clear-time records reload from the saved profile.
- [x] Pass the full 200-floor progression and save/reload regression on tested source HEAD `ad479c3704bd9f9955f908007dff07681c93a307`; the Godot validator completed successfully (workflow run `45053457072`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,812,958 bytes, expires 6 December 2026 (workflow run `45053457094`).
- [x] Add a final-boss regression that checks the sovereign boss transitions through all three health phases and registers defeat.
- [x] Exercise the operations manager's final-floor clear integration and verify that the sovereign crown/core, rare core, Nen fragment, SYSTEM credits, and floor-200 completion record are granted; restore the validator's original local profile afterward.
- [x] Pass the sovereign final-boss three-phase/defeat regression and final reward integration on tested source HEAD `8d37b28105c5f52a8a2b2b5f44de35e45012919f` (Godot run `45053818855`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,815,543 bytes, expires 6 December 2026 (Android run `45053818923`).
- [x] Add validator coverage for survival-timer completion, championship timeout abandonment without a clear, and wound-triggered active-floor abandonment/recovery.
- [ ] Pass the extended survival/championship/abandon regression on the latest PR head; physical Android gameplay review remains outstanding.


### Hunter rank ladder and helicopter high-rank authorization — 22 November 2026

- [x] Establish the official hunter grade order from F through E, D, C, B, A, S, SS and SSS, with SSS as the highest and exceptionally rare grade.
- [x] Permit A/S/SS/SSS hunters to use the Hunter Association helicopter without the separate level-50 threshold; F–B grades do not qualify by rank alone.
- [x] Extend the Godot validator to check denial for F–B and authorization for A/S/SS/SSS.
- [x] Investigate the latest Godot CI failure: the validator declared progression twice in the same function scope. Rename the later shopping-test reference to avoid the duplicate declaration.
- [ ] Re-run Godot validation and canonical Android APK export on the corrected rank-authorization commit.
- [ ] Implement and validate the full multi-stage rank-award board, including exceptional SSS evaluation; the ladder and helicopter gate alone do not constitute a completed promotion system.
- [ ] Connect association NPC pilot staffing/flight automation; current authorization is evaluated for the player character.


### Hunter Association rank progression board — 22 November 2026

- [x] Add an entry to the Hunter Association tower menu for the official F-to-SSS rank board.
- [x] Display the player's current rank, verified mission points/count, Nen awakening/control rank, Nen skill-use count, and distinct abilities.
- [x] Show the progression requirements for F, E, D, C, B, A, S, SS, and SSS; clearly state that SSS requires exceptional Hunter Association Board approval and cannot be self-awarded.
- [x] Extend the Baghdad operations validator to open the Hunter Association menu and assert that the rank-board entry and progression rows are generated.
- [ ] Run Godot 4.3 import/parse, the full Baghdad tower operations validator, and canonical Android APK export on the latest branch head; this UI addition is not yet marked tested.
- [ ] Implement the separate multi-stage SSS examination/board decision workflow; the current board is a transparent progress display, not the final SSS approval workflow.
