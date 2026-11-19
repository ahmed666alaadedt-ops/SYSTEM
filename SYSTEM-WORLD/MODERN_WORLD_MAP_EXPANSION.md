# SYSTEM WORLD — Modern World Map Expansion

> **Architecture status:** This document records the earlier fictional-continent prototype only. It is not the canonical geography decision. The modern world is now planned as a real-Earth geographic world with WGS84 source coordinates and licensed regional data packs. See REAL_EARTH_GEOGRAPHY_AND_NPC_LIFE.md for the current canonical direction. Existing procedural terrain and city anchors are retained as a temporary prototype until a verified real-data replacement is ready.

## Design foundation

The modern world uses one connected fictional continent with real city names as cultural and architectural references. Its coordinates are intentionally fictional and do not claim to reproduce real-world geography. The existing terrain foundation remains authoritative and is not replaced by this expansion.

## Current generated geography

- Connected main continent with procedural height, coastline, beaches and terrain collision.
- Four surrounding islands.
- Three river routes and lake/river basins.
- Five mountain formations and four cave entrances.
- Fourteen named city anchors:
  - New York
  - London
  - Paris
  - Baghdad
  - Moscow
  - Cairo
  - New Delhi
  - Guangzhou
  - Seoul
  - Tokyo
  - Singapore
  - Sydney
  - Rio de Janeiro
  - Johannesburg

## City detail layer

`scripts/modern_world_region_manager.gd` adds a second procedural layer over the terrain. Each city receives:

1. A civic plaza.
2. Downtown high-rise district.
3. Historic/old-town district.
4. Residential district.
5. Commercial district.
6. Industrial district.
7. University district.
8. Waterfront district.
9. Green-belt district.
10. Local boulevard and ring-road segments.
11. An international-airport visual hub.
12. A central-rail-station visual hub.

Building placement samples the existing terrain, avoids water, and rejects large local height differences. If a requested city anchor is offshore, the manager searches nearby land before placing the city.

## Rural settlements

Ten named rural settlements are generated as small villages with a central square, houses and a notice tower. Their coordinates are also resolved against the terrain so a village is not deliberately placed in open water.

## Map discovery and travel data

The region manager registers city, village, airport and rail-station locations with `SystemWorldMapManager`. Airport and rail entries are registered as fast-travel points, but the existing map system still requires the player to reach and activate each point. Baghdad is the initial discovered city; the other regions remain available for discovery.

## Performance and visual direction

- City blocks use MultiMesh instances to reduce per-building draw overhead.
- Districts and transport hubs are generated once when the modern world is created.
- The design layer is procedural placeholder geometry, not final high-detail art assets.
- Future streaming should load detailed districts around the player and retain lightweight distant silhouettes.
- Future work should add collision/navigation for roads, detailed interiors, functional transport schedules, port facilities, bridges, traffic, pedestrians, hospitals, emergency services, markets, parks, and city-specific architectural kits.

## Current implementation boundary

This expansion is committed to the repository and wired into `world_manager.gd` and `main.gd`. It has been checked by re-fetching the committed files and confirming the integration references. It has **not** yet been run through the Godot parser or visually tested in-game. The world map is an ongoing build, not a claim that every city or the full planet is complete.


## Vehicle ownership, dealerships, and transport completion scope

### Implemented prototype foundation
- A vehicle catalog now defines purchasable city cars, sports cars, SUVs, taxis, delivery vans, buses, utility trucks, and non-sale emergency service vehicles.
- A player garage manager provides local prototype wallet balance, vehicle purchase, resale, active-vehicle selection, and local persistence.
- A dealership visual manager is placed at a land-resolved site in each generated modern city and is connected to the player's garage manager during main-scene setup.
- The current wallet and garage save to a local ConfigFile. This is a single-device prototype only: it is not secure, not cloud synchronized, and must not be used for real-money balances or a live multiplayer economy.
- The showroom is currently a visual location plus callable manager API. A complete in-world interactive sales UI, vehicle preview turntable, test-drive flow, contracts, taxes, trade-in, financing, service bay, and garage UI remain to be built.
- The traffic vehicles remain visual NPC traffic models. They are not yet drivable player vehicles and do not yet use a full vehicle physics controller.

### Required world transport production
- Connect road networks between cities with terrain-aware highways, local streets, bridges, tunnels, junctions, signs, barriers, lane markings, and race circuits.
- Build navigable rail corridors, stations, platforms, switches, crossings, timetables, passenger trains, freight trains, and station interactions.
- Build airport terminals, runways, taxiways, gates, air-traffic routes, aircraft models, boarding, and flight travel transitions.
- Build ports, docks, cargo yards, ferry terminals, sea lanes, passenger ships, cargo vessels, and boat navigation.
- Add ownership and usage systems for player cars, commercial fleets, public transport, aircraft, and vessels, with per-zone streaming and device performance budgets.
- Complete city services and street life: pedestrians, traffic signals, parking, shops, markets, garages, fuel/charging, repair, emergency response, street furniture, public spaces, building entrances/interiors, and district-specific lighting.
- All purchases and balances must move to a trusted server/account backend before multiplayer trading or any real-money-linked economy is enabled.
- Do not label the map or transportation systems complete until the actual scenes, interactions, navigation, persistence, performance, and Godot runtime tests are complete.


## Civilian vehicle ownership and police response prototype

- The modern world now creates a small civilian-owned vehicle fleet in each generated city. Each vehicle records an NPC owner, city, vehicle class, witness count and theft/recovery state.
- Vehicles expose the standard world interaction target. Interacting with an NPC-owned vehicle attempts a theft and records the owner, location, witness count and wanted level.
- Witnessed thefts generate a report and dispatch a visible police pursuit unit that follows the stolen vehicle. If the police unit catches the target in this prototype, the vehicle is recovered and removed from the street.
- Crime records and wanted level are saved locally for this single-device prototype. This is not yet a secure authoritative law system, a multiplayer anti-cheat system, or a full player vehicle hijack/drive controller.
- Required next production steps: civilian NPC occupants and schedules, key/lock and alarm states, player entering and driving the stolen vehicle, police patrol routes and response delays, line-of-sight and witness simulation, license-plate recognition, pursuit escalation, road-blocks, fines, arrest/jail, impound lots, insurance and ownership transfer. Police must pursue the actual player-controlled vehicle once vehicle possession and driving are implemented.


### Autonomous civilian driving and persistent NPC owners

- Civilian car owners are now registered in the existing AI society manager as persistent driver NPC records, rather than existing only as labels on vehicles. Their owner IDs are saved in a registry so the same owner records can be reused on later launches.
- Each civilian vehicle follows a lightweight loop around its city, with individual cruising speeds and short pauses. A theft switches the vehicle to a faster escape state; recovery stops and removes it from the active street scene.
- A witnessed theft updates the owner's activity, raises the local wanted level, creates a crime report and dispatches a visible police unit to pursue the moving target. Recovery returns the owner's activity to work.
- This remains an early simulation layer: routes are simple local loops, not lane-aware navigation; vehicle physics, traffic lights, collisions, pedestrian avoidance, player possession/steering, arrests and secure multiplayer crime authority are not yet implemented. These limitations must remain explicit until those systems are built and tested in Godot.


## Intercity roads, bridges, rail corridors, ports and race circuits — first visual pass

- A new transport network manager is created by the modern region manager after city anchors and local roads are available.
- It lays out selected city-to-city highway corridors and parallel rail guide strips using the resolved city positions. Narrow water gaps can receive raised bridge decks and simple support piers; routes with long open-water gaps are skipped rather than creating implausible continent-spanning bridges.
- Coastal city locations are checked for nearby land-to-water edges and receive a first-pass harbor/dock layout with simple crane structures. These are visual harbor landmarks, not navigable ship systems.
- Where a complete land loop fits around a city, a motor-racing circuit is generated and registered as a map landmark.
- Bridge, port and circuit landmarks are added to the modern-world map location registry.
- Current limits: road and rail meshes are visual only; no drivable road graph, lane navigation, collision-aware traffic, rail vehicles, timetables, ship steering, airport flight routes, passenger boarding, tunnel interiors or race-event logic have been implemented by this pass. These must be built as separate functional systems and verified in Godot before the map is called complete.


- The transport layer also places first-pass parked passenger-aircraft models at generated airport sites, multi-car train consists at central rail hubs, and a stationary passenger/cargo ship beside each harbor where a valid waterfront site is found. These are scene props only; no boarding, driving, flight, rail simulation or ship navigation is implied.


## Street-level city infrastructure — first visual pass

- Every generated city now receives pedestrian crosswalk markings, four-corner traffic signal props with alternating red/amber/green phases, bus-stop shelters with benches and signs, and a marked public parking bay.
- The signal cycle is currently decorative. NPC vehicles do not yet query signal state, yield to pedestrians, reserve parking spaces or obey road rules; those behaviors belong to the next traffic-AI integration pass.


- Airport prop sites now include a marked runway with edge lights and a parked passenger-aircraft model. Central rail prop sites include a track bed, twin rails, sleepers and a stationary multi-car train. Harbor sites include a stationary cargo/passenger vessel with containers. These details improve the visible transport hubs but remain non-functional set dressing.


## City services and discoverable landmarks — first visual pass

- Each generated city now receives separate hospital, police headquarters, fire/rescue station, hotel, central market and vehicle garage buildings. Buildings have basic facades, roofs, windows, entrances, collision bodies and discoverable entrance interaction areas.
- Each service entrance is registered in the world map under its city region. The interaction prompt identifies the service, while treatment, police case handling, hotel booking, market transactions and garage service menus remain to be implemented.
- These buildings are procedural exterior prototypes. Their interiors, staff NPC schedules, service workflows, economic transactions and full accessibility are not complete.


- Civilian car models now include a visible driver silhouette while the car is in normal use, and their wheels rotate while the vehicle follows its local route. When theft is triggered, the driver visual leaves the vehicle and the escape/police-response state begins. The occupant is still a visual representation of the linked AI society owner record, not a fully animated enter/exit character.


- Vehicle ownership is now recorded on the corresponding AI society NPC profile. The owner keeps the vehicle ID in their owned-vehicle list, receives a theft memory when the car is stolen, and receives a recovery memory when police return it. This links the crime event to the citizen's persistent social record.


## City road tunnels — first visual infrastructure pass

- The transport manager now attempts to place one short covered road-tunnel landmark near each resolved city.
- Candidate alignments are sampled against the existing terrain; a tunnel is skipped when the full segment is not on land or the sampled ground height varies too sharply.
- Each generated tunnel includes a road bed, side walls, roof, framed portals, approach slabs, lane-edge markings, ceiling fixtures, and a city-named landmark record for map registration.
- These are procedural visual structures only. The terrain is not excavated, the road network is not yet connected through the tunnel, and collision, vehicle navigation, traffic rules, dynamic tunnel lighting, emergency systems, and drive-through validation remain outstanding.
- The build log reports how many city tunnel prototypes were placed; the number may be lower than fourteen when terrain validation rejects a candidate.


## Rural settlement access roads — first visual pass

- Resolved village anchors are now retained by the region manager and exposed to the transport layer.
- Each village searches for the nearest city with a sampled all-land corridor; when a continuous land route is found, a narrow rural access road with center markings is generated.
- Routes that cross water are skipped rather than bridged with an arbitrary straight line.
- These roads are visual geometry only. They still need terrain-aware route planning, edge/shoulder treatment, collision, signs, junctions, drainage, lane navigation, traffic integration, and Godot runtime validation.


## District street-grid visual pass

- Every resolved city district now receives a first-pass local street grid: four roads in each direction, terrain-sampled road surfaces, raised sidewalk strips on both sides, and zebra-style pedestrian crossing markings at grid intersections.
- Geometry is batched into a small set of meshes per district rather than creating a separate node for every road segment.
- These are visual street surfaces only. They do not yet include collision, curb ramps, lane direction graphs, parking rules, traffic-light control, pedestrian navigation, or verified continuity between neighboring district grids.


## Race circuit facilities — visual prototype

- Each race circuit that passes the all-land terrain check now receives an outer safety-barrier ribbon, red/white-style curb strip, start/finish gantry, pit garage block, and tiered grandstand.
- These additions make the circuit read as a motorsport venue rather than only a loop of road mesh.
- They remain scenery: no collision-tested barriers, pit services, race marshal logic, grid slots, timing, checkpoints, AI opponents, rewards, or playable race events are implemented yet.


## Airport, rail-station and harbor facilities — visual expansion

- Airport prototypes now include a passenger terminal hall, glass frontage, departure/arrival wings, apron stand markings, and an air-traffic control tower alongside the runway and parked aircraft.
- Central rail prototypes now include passenger platforms, platform canopies and supports, a station concourse, glass frontage, roof, departure sign, tracks, sleepers and train carriages.
- Harbor prototypes now include a cargo warehouse, loading apron and stacked freight containers in addition to docks, piers, cranes and a ship.
- Terrain-checked access-road meshes are attempted between each city and its airport, central station, and harbor. A route is skipped if the direct sampled corridor crosses water.
- All transport structures remain visual prototypes. No ticketing, boarding, vehicle movement, route schedules, freight handling, collision-tested access, or navigable transport has been implemented.


## Bridge safety and waterfront public space — visual expansion

- Water-crossing portions of accepted inter-city corridors now receive side railing meshes and spaced emissive marker lights in addition to their earlier deck and support prototypes.
- Harbor edges now receive a promenade deck, bollards, benches and a simple harbor sign to create a pedestrian-facing waterfront.
- These remain decorative meshes. Bridge collision/structural validation, continuous road routing, promenade access ramps, pedestrian navigation, lighting controls and water-level clearance tests remain outstanding.


## Inter-city highway markings

- The generated inter-city road corridors now include dashed center and lane-edge markings, sampled along the same terrain-following segments as the road surface.
- Markings are batched into a separate mesh per corridor segment and use no realtime shadow casting.
- These visual markings do not yet define traffic lanes or navigation paths for vehicles.


## Inter-city highway service areas — visual prototype

- Each inter-city corridor segment that is generated attempts to place a roadside rest stop on nearby land.
- The rest-stop scene includes a market building, glazed frontage, canopy, fuel-pump props, EV charging posts and marked parking bays.
- Stops are skipped when neither side of the sampled midpoint is land.
- These are scenery only: no fuel inventory, charging, purchases, vehicle service, staff, traffic entry/exit lanes or player interaction is implemented.


## Urban flyovers — visual prototype

- Each city attempts an elevated east-west flyover crossing its central boulevard, with sampled terrain ramps, a raised deck, dashed center marking, side barriers and three support piers.
- The flyover is skipped when its full sampled alignment is not on land.
- These structures are visual only; ramp grading, road junction connections, vehicle clearance, collision, traffic routing, pedestrian access and runtime validation are still required.


## City identity landmark silhouettes

- Every resolved city now receives a small procedural civic landmark group selected by its existing city style index.
- The fourteen silhouettes are distinct: a layered skyline and beacon, civic clock tower, observation tower, riverfront domed hall and minarets, heritage domes, desert pyramid group, ceremonial gateway, twin towers with skybridge, digital culture tower, cultural gate and roof, garden domes, sail-like harbor roofs, coastal lookout, and mining-heritage headframe.
- These are original stylized identity markers, not exact reproductions of real monuments. They establish visual distinction only; detailed architecture, cultural signage, interiors, collision, and local asset sets remain future work.



## Outer archipelago expansion — first connected-world extension

- Added `scripts/modern_world_archipelago_manager.gd` and integrated it into the modern-world creation sequence immediately after the main continent.
- The outer sea now receives eight additional named island landforms: Northwatch Isle, Whispering Keys, Stormglass Isle, Eastern Crown, Sunset Atoll, Southern Reach, Farwind Isle, and Bluewater Haven.
- Each island has layered rock, sand and grass ellipsoids, a simple collision volume, and a small tree cluster. The original continent, city anchors, and existing four islands are left unchanged.
- These are first-pass explorable landform prototypes. They do not yet have docks, boats, NPC settlements, quests, detailed coast sculpting, underwater terrain, or island-specific discovery/fast-travel registration.
- The new islands extend the visible exploration geography; they do not represent a completed world-scale planet map. The Godot project still needs parser, collision, visual, and Android performance validation.


## Outer island harbors and maritime navigation

- Added a first-pass wooden pier and edge rails to each of the eight outer islands, with support piles, harbor lights, and a moored ferry-boat visual.
- Added lighthouse structures to selected larger islands.
- Added twelve sea-navigation buoy markers and tagged them as discoverable world landmarks.
- Harbor metadata marks fast travel as disabled by default; visiting and activating docks must be implemented by the discovery/transport gameplay systems.
- Ferry visuals are scenery prototypes only. There is no boat controller, route schedule, passenger boarding, docking interaction, water physics, or functional maritime navigation yet.


## Island shoreline dressing and paths

- Added twelve coastal boulders and seven low shrubs per outer island, with palettes matching each island's terrain style.
- Added a simple land trail leading toward each harbor so the dock reads as part of the island settlement rather than a detached prop.
- These are low-detail procedural dressing meshes; they are not yet destructible, harvestable, animated, or individually collision-enabled.


## Deterministic biome dressing — first regional ecology pass

- Added `scripts/modern_world_biome_manager.gd` and integrated it after the continent and outer archipelago are created, before detailed city regions.
- Four terrain-following dressing zones are defined: western woodland, eastern woodland, southern drylands, and northern highlands.
- The manager uses a fixed random seed so the same accepted terrain positions are reproduced between launches.
- Trees, canopies, shrubs and rocks are batched with MultiMesh instances to keep node counts lower than one-node-per-prop placement.
- Candidate positions are rejected when they fall in water, near the existing city anchors, near the three river corridors, or inside the two lake buffers. Height bands also filter each biome type.
- This is scenery dressing only: vegetation has no harvesting, growth, wind animation, individual collision, wildlife ecology, fire simulation, or player interaction. The existing terrain, city coordinates, river/lake network, and transport routes are not changed.
- The manager has been committed and wired into the modern-world creation order. Godot parser validation, visual review, and Android performance profiling are still required.


## Coastal ecology dressing — main-continent shoreline pass

- Added `scripts/modern_world_coastal_detail_manager.gd` and integrated it into modern-world startup after terrain generation.
- Samples the existing elliptical continent edge at 256 angular positions and searches the terrain height field for nearby low shoreline points.
- Adds batched coastal rock clusters, driftwood and dune-grass silhouettes; it avoids the established city anchor areas.
- Uses a fixed seed for repeatable placement and MultiMesh batches to reduce scene-node overhead.
- The existing coastline, beaches, ocean, islands, ports and city coordinates are not reshaped or moved.
- This pass is visual scenery only. It does not yet implement tides, swimming, shoreline collision, erosion, harvesting, fishing, dynamic weather interaction, or detailed sea-floor ecology.
- The script and world-manager integration are committed. Godot parsing, in-engine visual inspection, collision review and mobile performance profiling remain pending.
