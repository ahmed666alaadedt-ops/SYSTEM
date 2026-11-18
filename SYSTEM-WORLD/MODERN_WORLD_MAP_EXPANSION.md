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
