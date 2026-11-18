# SYSTEM WORLD — Modern World Map Expansion

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
