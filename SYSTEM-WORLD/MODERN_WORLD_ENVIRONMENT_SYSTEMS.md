# SYSTEM WORLD — Modern World Environment Systems

## Purpose

This document tracks the living-world layer for the connected modern-world map. It distinguishes implemented procedural foundations from systems that still require production assets, gameplay logic, or runtime validation. The existing continent and city layout remain in place; these systems extend them.

## Implemented in the current GitHub revision

### 1. City regions and rural settlements
- Fourteen named city anchors are defined in `scripts/modern_world_region_manager.gd`: New York, London, Paris, Baghdad, Moscow, Cairo, New Delhi, Guangzhou, Seoul, Tokyo, Singapore, Sydney, Rio de Janeiro, and Johannesburg.
- Each city receives eight district zones: downtown, old town, residential, commercial, industrial, university, waterfront, and green belt.
- Each city has a central plaza, procedural building clusters, road strips, airport and central rail-station visual hubs, and green-belt park markers.
- Ten named rural settlements are generated around the continent.
- City and village locations, airports, and rail stations are registered with the existing map discovery manager. Baghdad is the starting discovered city; other places remain discoverable as the player explores.
- City anchors are resolved against the existing terrain so an anchor requested over water is moved to a nearby land sample when one is found.

### 2. Street lighting and night illumination
- The original four-post-per-city pass has been superseded by scripts/modern_world_lighting_manager.gd.
- The lighting manager procedurally places fixtures along both current boulevard corridors and both ring-road segments for each resolved city, with tighter spacing on main roads and wider spacing on secondary roads. It also adds plaza lanterns, four pedestrian-scale fixtures around each generated district block, and forecourt fixtures around each visual airport and rail hub. The obsolete duplicate streetlight pass in `world_manager.gd` is no longer spawned.
- Fixture geometry uses inexpensive emissive materials. A capped pool of 24 shadowless OmniLight3D lights is repositioned to the nearest fixtures around the player, rather than enabling a dynamic light at every post.
- Nearby dynamic lights switch on after local sunset and switch off during daylight, using the system clock. The existing world-time manager continues to control the sun, sky, ambient illumination, and weather/daylight cycle.
- This is a broader procedural district-and-transport lighting foundation, not yet a complete lighting pass for every alley, bridge, tunnel, building interior, shopfront, port, park, and road outside the currently generated city and district footprints. Those areas still need fixture placement and scene integration.
- Dynamic illumination has not been visually or performance-tested on Android. A final pass should add baked/static lighting where supported, district-specific profiles, windows, signs, traffic signals, vehicle beams, wet-surface response, and quality tiers.

### 3. Ambient wind and bird calls
- New `scripts/modern_world_ambience_manager.gd` generates looping PCM audio streams at runtime.
- A low-level filtered-noise wind bed and short synthetic bird chirps are played through two ambient audio players.
- The manager exposes enable/disable and volume controls for later biome, weather, and accessibility integration.
- These are procedural placeholder sounds, not recorded bird species or final sound-design assets. Later production should replace or layer them with licensed recordings and location-specific mixes: city traffic beds, river sounds, forest insects, rain on roofs, waves, distant aircraft, and indoor ambience.

### 4. Ambient city traffic
- scripts/modern_city_traffic_manager.gd now defines eight visual traffic archetypes per resolved city (sedan, taxi, delivery van, city bus, police, ambulance, utility truck, and sport car), producing up to 112 lightweight ambient vehicles across fourteen cities.
- Vehicles have procedural body, cabin, wheel, and emissive headlamp meshes and move along the current two boulevard axes. Their height follows terrain and they hide when a sampled position is over water.
- This is still a visual traffic prototype, not a finished traffic simulation. It has no vehicle physics, road collision, complete lane graph, junction logic, traffic signals, navigation, parking, pedestrian yielding, service dispatch, player ownership, garage, purchase/sale, multiplayer replication, or drivable controls.
- Vehicle density must later be streamed and capped around the player by device tier and city population; the current prototype does not yet implement distance-based traffic streaming or a server-authoritative multiplayer vehicle service.

### 5. Existing environment systems retained
- The project already contains a world clock/day-night manager and a sky/weather/flying manager.
- The world builder already creates terrain, forests, mountains, waterways, a marine environment, and a discovery manager.
- Existing wildlife code is retained; its actual species, animation, spawn density, and audio integration must be audited before claiming a complete ecosystem.
- No duplicate world clock, terrain, map-discovery, or wildlife manager is introduced by this update.

## Performance principles

- Keep repeated city geometry on MultiMesh where practical.
- Avoid one shadow-casting dynamic light per street lamp. The current city plaza lights have shadows disabled.
- Keep ambient sound generation to a small number of looping streams, not one audio player per bird.
- Future traffic and wildlife should be streamed or activated near the player rather than fully simulated at equal detail across the entire continent.
- Mobile quality tiers should scale shadow distance, foliage density, traffic count, audio voices, reflections, and volumetric effects independently.

## Remaining map and environment work

1. Validate all GDScript with the target Godot version and run the scene on Android hardware.
2. Build a connected inter-city road network that follows land, with bridges, tunnels, ramps, junctions, road markings, barriers, signs, and collision.
3. Add ports, docks, ship lanes, ferries, cargo vessels, and coastal settlements.
4. Replace visual airport and rail hubs with usable transport gameplay, schedules, boarding, routes, and safe arrival points.
5. Expand city identity: distinctive architecture, landmarks, skyline silhouettes, materials, street furniture, signs, local vegetation, and cultural details for each named city.
6. Add road-side businesses, gas/charging stations, service areas, farms, orchards, fields, windbreaks, rural roads, and village economies.
7. Add traffic signals, pedestrian crossings, sidewalks, crowd flow, parking, vehicle AI, emergency vehicles, and drivable vehicle controls.
8. Add a full lighting pass: windows with randomized occupancy, shop signs, neon districts, billboards, traffic signals, headlights and brake lights, interior lighting, moonlight, cloud shadows, and weather-responsive fixtures.
9. Add a final audio pass: region-specific bird species, dawn/dusk variation, wind through leaves, forest insects, river and waterfall beds, city crowds, market calls, engines, horns, rail, aircraft, ship horns, rain, thunder, and interior reverb.
10. Add robust weather effects: rain accumulation, puddles, wet-road reflections, fog volumes, dust storms, snow where the climate supports it, wind response for trees and flags, and weather transitions.
11. Add streaming/LOD and biome-based activation so distant districts do not consume full Android CPU, GPU, or memory.
12. Validate map discovery, fast-travel activation, and transport interactions against the existing map manager; visual hubs must not be presented as fully usable travel services until the gameplay connection exists.

## Current verification boundary

GitHub file writes are confirmed for the scripts listed below. Godot parsing, scene startup, sound playback, traffic motion, visual quality, and Android performance have **not** been runtime-tested in this work session. The procedural visuals and sounds are foundations that still need validation and final art/audio production.


### 6. City road tunnels — visual prototype
- `scripts/modern_world_transport_network_manager.gd` now attempts one short covered tunnel landmark per resolved city.
- Candidate sites are sampled for continuous land and limited height variation before geometry is placed.
- Tunnel geometry includes approach slabs, road bed, side walls, ceiling, portal frames, lane-edge markings, emissive ceiling fixtures, and a map landmark record.
- This is not an excavated or drivable tunnel system. The road graph, terrain cutting, collision, vehicle clearance tests, emergency exits, ventilation simulation, dynamic lighting, and runtime validation are still required.


### 7. Rural settlement access roads — visual prototype
- The region manager now stores each successfully resolved rural village anchor and exposes it to the transport layer.
- The transport manager checks direct village-to-city candidates against the terrain and builds a marked road only when the sampled centerline remains on land.
- Water-crossing candidates are rejected. The road meshes follow sampled terrain heights and are registered as map landmarks.
- This is a first-pass visual connection, not a finished road graph: route optimization, collision, road-edge clearance, traffic navigation, junctions, signs, and runtime validation remain outstanding.


### 8. District streets, sidewalks and crossings — visual prototype
- Each resolved city district receives a compact four-by-four street layout in both directions.
- Road and sidewalk meshes sample terrain height along their segments; pedestrian zebra markings are added at the planned intersections.
- Meshes are batched per district to limit scene-node overhead.
- The street grid is not yet a drivable/navmesh road system: collision, curb ramps, lane routing, parking, traffic-rule integration, pedestrian AI, and district-to-district continuity checks remain outstanding.


### 9. Race venue structures — visual prototype
- Land-valid city circuits now receive a continuous outer barrier mesh, curb strip, start/finish gantry, pit-garage block, and small tiered grandstand.
- The structures are batched where practical and use existing procedural materials.
- No playable race logic, collision validation, pit interaction, AI racers, timing, checkpoint progression, rewards, or leaderboard is implied by these visuals.


### 10. Transport terminals and access — visual prototype
- Airport scenery includes terminal wings, passenger hall, apron markings and control tower.
- Railway scenery includes platforms, canopies, station concourse and train carriages.
- Harbor scenery includes warehouse, loading apron and freight containers.
- Airport, station and harbor access-road meshes are generated only when sampled direct routes stay on land.
- These are not functional terminals or transport services; boarding, schedules, route networks, freight, collision, and runtime validation remain outstanding.


### 11. Bridge railings and harbor promenades — visual prototype
- Accepted bridge spans receive side railings and spaced emissive marker lights along the sampled water-crossing points.
- Harbor prototypes receive a small waterfront promenade with benches, bollards and signage.
- No structural simulation, collision-tested bridge access, pedestrian navigation, or dynamic promenade lighting is implied.


### 12. Inter-city highway markings — visual prototype
- Inter-city corridor meshes now include dashed center and lane-edge markings following each sampled road segment.
- Markings are batched per corridor segment and disable shadow casting.
- A lane graph, traffic direction, speed rules, collision, and vehicle navigation remain separate unfinished systems.


### 13. Highway rest stops — visual prototype
- Generated inter-city corridors attempt a roadside service area with a small market, fuel canopy, pump props, EV chargers and parking-bay markings.
- Candidate sites are placed only on sampled land beside the corridor.
- Fuel/charging economy, service interactions, staff, vehicle routing and collision remain unfinished.


### 14. Urban flyovers — visual prototype
- Cities attempt an elevated boulevard crossing with terrain-sampled approach ramps, lane marking, side barriers and support piers.
- Sites crossing water are skipped.
- The flyovers are not connected drivable roads yet; collision, clearance, junction and traffic validation remain outstanding.


### 15. City identity landmarks — visual prototype
- The city style index now selects a distinct procedural landmark silhouette for each of the fourteen named cities.
- Landmark groups use lightweight box and cylinder meshes with restrained emissive accents; they are original stylized motifs rather than exact monument replicas.
- Detailed city-specific architecture, signage, interiors, collision and runtime visual review remain outstanding.

### 16. Worship landmarks and city advertising screens — first visual pass
- Baghdad's OSM point amenities tagged as Muslim places of worship (or `building=mosque`) are now distinguished from generic amenity markers and receive a lightweight procedural prayer-hall, dome and twin-minaret landmark.
- This first mosque pass applies to point features in the currently streamed Baghdad OSM amenity layer. Polygon-only mosque footprints and detailed city-specific mosque architecture still need dedicated treatment and asset review.
- Each generated modern-world city now receives a large emissive LED billboard prototype with a visible placeholder campaign label. The screen nodes carry explicit metadata identifying demo mode and keeping live ads disabled.
- Real advertising is not active. Production integration requires an approved ad provider, secure server-side campaign delivery, consent/privacy controls, content moderation, frequency limits, regional/legal review, and a non-ad fallback. Provider secrets must never be embedded in the Android client. No ad revenue or impressions are claimed.
- Mosques are civic/worship landmarks and are excluded from commercial billboard placement.
- These are source-level visual additions; runtime appearance, OSM feature coverage, and Android performance still require Godot validation.
