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
- Four visual street-lamp posts are placed around each city along the current boulevard axes.
- Each city receives a plaza-area `OmniLight3D` with zero initial energy and the `system_night_light` group.
- `scripts/world_time_manager.gd` now collects those grouped lights and drives their energy through its existing day/night cycle.
- Lamp-head materials are emissive, so the fixtures remain visually readable even when dynamic lighting is reduced.
- This is a first lighting pass, not a finished physically based city-lighting art pass. Window interiors, shop signs, traffic signals, vehicle light beams, volumetric night atmosphere, and per-district lighting profiles remain future work.

### 3. Ambient wind and bird calls
- New `scripts/modern_world_ambience_manager.gd` generates looping PCM audio streams at runtime.
- A low-level filtered-noise wind bed and short synthetic bird chirps are played through two ambient audio players.
- The manager exposes enable/disable and volume controls for later biome, weather, and accessibility integration.
- These are procedural placeholder sounds, not recorded bird species or final sound-design assets. Later production should replace or layer them with licensed recordings and location-specific mixes: city traffic beds, river sounds, forest insects, rain on roofs, waves, distant aircraft, and indoor ambience.

### 4. Ambient city traffic
- New `scripts/modern_city_traffic_manager.gd` creates two lightweight visual vehicles per city (28 total across the fourteen city anchors).
- Vehicles have simple body, cabin, wheel, and emissive headlamp meshes and move along the two existing boulevard axes.
- Their height follows the terrain, and a vehicle is hidden when its current sample falls over water.
- This is ambient visual traffic only. It does not yet provide vehicle physics, road collision, lane networks, traffic lights, intersections, navigation, parking, pedestrian yielding, drivable player cars, or traffic-law AI.

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
