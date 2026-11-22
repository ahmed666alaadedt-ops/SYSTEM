# SYSTEM WORLD — Modern World Completion Tracker

This is the acceptance checklist for the modern-world map. The project must not be described as complete, and work must not move to the portal phase, until every required item is implemented, connected, and verified in Godot on the target platforms. A visual placeholder is not accepted as a completed gameplay system.

## Current verified repository foundations

- [x] Fourteen city labels and eight district labels per city are defined in modern_world_region_manager.gd; only Baghdad is currently connected to the provisional WGS84 registry anchor, while the other thirteen centers remain prototype-layout coordinates.
- [x] Each city style index generates a distinct original civic landmark silhouette to improve skyline and local identity.
- [x] Ten rural settlement seeds are defined.
- [x] City road strips, plaza markers, green-belt markers, airport/rail visual hubs, and map discovery registration exist.
- [x] Baghdad tower landmarks are created by the region manager.\n- [x] Tower exteriors now include stepped podiums, facade fins and illuminated crowns; the Power Tower adds tournament display blades and concentric arena terraces, while the Hunter Association Tower adds monumental wings and a Hall of Honor display. These remain architectural blockouts; interior arenas, live champion data and playable headquarters rooms are not complete.\n- [x] Power Tower's 100-floor data model now cycles through duel, team, survival, elite-gauntlet and championship challenge profiles, with every tenth floor assigned a boss trial. This is challenge metadata; spawning, playable arena rooms, matchmaking and server-verified rankings remain open.
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


## Mountain cave passage blockout — 21 November 2026

- [x] Add `scripts/modern_world_cave_passage_manager.gd` for the four existing mountain cave sites without moving their coordinates or changing the continent.
- [x] Generate a walkable passage floor with static collision, side-wall collision, an arched ceiling mesh, and a larger inner chamber floor.
- [x] Tag each generated passage as a cave landmark and mark it explicitly as geometry blockout requiring runtime validation.
- [ ] Add validated entrance-to-building association, proper terrain excavation, complete chamber wall/ceiling collision, cave lighting, audio, navigation, discovery persistence, and player interaction.
- [ ] Run Godot parser/import, scene startup, collision traversal, and Android performance tests. The new geometry is committed source code and has not yet been run in Godot or on a device.

 
## Baghdad underground vault door lifecycle — 22 November 2026

- [x] Keep the existing interaction root, group registration, and DoorBody target path unchanged; the ray interaction still resolves the moving body to its parent interactable.
- [x] Replace instant hide/collision-disable behavior with a 1.25-second vertical stone-slab movement; the slab retains its collision while moving and clears the doorway by rising 4.2 m.
- [x] Allow the door to reverse direction safely if the player interacts while its tween is running; expose the current open state and matching Arabic prompt on the interaction root.
- [x] Use an AnimatableBody3D for the moving door slab so its physical motion can be synchronized with the physics engine.
- [x] Godot 4.3 headless project import/parser and dedicated vault-door lifecycle test passed in GitHub Actions run 44990348872 on commit `ed5ea163b54bb92a34b323449d84c448520ab1d2`; the test covers animated open/close, collision remaining enabled, Arabic prompts/state metadata, tween reversal, and local state restoration after manager recreation.
- [x] Expanded Godot 4.3 lifecycle run 44992857584 passed on commit `373f82954546e2844b47a692bd015b1c8563a189`: shared camera-ray targeting resolves the door from both sides, the closed/moving slab blocks the ray, the fully raised slab clears the doorway at player height, and local save/reload restores the open transform after a physics frame.
- [ ] Run the canonical main scene and verify actual player-body traversal/physical clearance in gameplay; the automated ray test does not replace a full character-controller traversal test.
- [x] Corrected the ray-test fixture to register the synthetic vault door in `system_interactable`, matching production registration. The previous run progressed through camera-ray targeting and door animation, then exposed a restore-baseline bug: repeated `restore_stone_door_state()` calls recaptured the already-open body position as the closed baseline. Fixed by capturing the original closed position only once per interactable instance (commit `efbe5a41e7452c807056d21593f6bcb1dbf5bb56`).
- [ ] Integrate persistence with the authenticated world-state save service for cross-device/account synchronization; current ConfigFile persistence is local to this device only.
- [ ] Validate actual player-body traversal through the opened doorway, repeated interaction in the running game, and mobile-device behavior.
- [ ] Verify independent saved state for Baghdad Old Souk and Baghdad River Catacombs; a dedicated two-site isolation assertion was added on commit `22e390432ce856395e2dff286ba70471b9c0b7e0` and is awaiting CI.

- [x] Persist each Baghdad heritage-vault door's desired open/closed state in a local ConfigFile and restore the slab position/prompt when the heritage manager recreates its city sites.
- [x] Connect door-state changes to the heritage manager so the saved state is updated when the player toggles the door, including during an active animation.
- [x] Verify local save/reload behavior in Godot 4.3 workflow run 44992857584 on commit `373f82954546e2844b47a692bd015b1c8563a189`; saved open state restores the raised slab after manager recreation and a physics frame.
- [x] Two-site isolation passed in Godot 4.3 workflow run 44992928278 on commit `22e390432ce856395e2dff286ba70471b9c0b7e0`: opening Baghdad Old Souk did not open Baghdad River Catacombs, and the independent closed state remained closed after manager recreation.
- [x] Open and closed states both survived repeated manager recreation in Godot 4.3 workflow run 44992978899 on commit `725acf124b01f5fd77560d1e5c35d1f7a53d162a`; Baghdad Old Souk and River Catacombs retained independent states.
- [ ] Validate capsule/player-body collision traversal through the doorway, then verify repeated interaction and mobile-device behavior in the running game; persistence remains device-local, not Firebase/cloud synchronization.
