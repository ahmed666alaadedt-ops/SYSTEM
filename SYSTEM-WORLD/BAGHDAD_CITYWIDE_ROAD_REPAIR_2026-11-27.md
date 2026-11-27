# Baghdad Citywide Map Expansion
Date: 2026-11-27
Repository: ahmed666alaadedt-ops/SYSTEM
Work branch: fix/baghdad-citywide-osm-road-network-20261127
Base: main at dc3d9ba942251173ef0a9a5aa57d83b097937986

## Preserved city map layers
- Existing 200 m detailed core pack remains intact, including the verified Republic Bridge and Tigris source geometry.
- Existing citywide 1 km roads-only overview remains separate and streams around the player.
- Added a separate 1 km municipal urban overview pack generated from Baghdad municipality relation 5638803. It includes buildings, waterways, bridges, land use, amenities, railways, natural-water polygons and mapped entrances.
- The urban pack is streamed independently from the roads and detailed core packs. Its streamer loads only the active 1 km cell, uses low-detail exterior building boxes, omits per-building collision meshes and omits entrance interaction bodies to limit mobile CPU, memory and draw-call cost.
- Mapped amenities are classified where OSM tags are available: hospitals/healthcare, police stations, mosques, shops, restaurants/cafes, schools and civic facilities. Arabic/English OSM names and source IDs are retained when present.
- Building footprints retain OSM source IDs, building type, mapped height/floor estimate and display name. These regional overview buildings are visual LOD only; they are not yet walkable interiors or full collision-ready buildings.

## Build and runtime integration
- Source workflow builds and checks the urban ZIP beside the existing detailed and roads ZIPs, and reports totals by layer plus counts of classified facility types.
- Canonical Android workflow requires and installs the urban pack into SYSTEM-WORLD/data/geography/baghdad/regional_urban.
- BaghdadOSMCellStreamer supports a dedicated low-cost overview mode; WorldManager attaches it as BaghdadRegionalUrbanStreamer.
- Runtime validator checks the 1 km urban manifest, locates an occupied building cell and a POI cell, then verifies that low-detail building meshes and amenity markers are generated.

## Existing Baghdad landmarks retained
- BaghdadTowerLandmarksManager continues to generate the Baghdad connected tower district, upper sky-city platforms and links, public amenities, and the single Hunter examination tunnel.
- The Power Tower remains a separate standalone challenge destination and is excluded from the connected five-tower sky-city links.
- The existing code contains the Hunter Association tower, Business & Investment tower, Shopping tower, Antiques & Heritage tower, Technology tower and standalone Power Tower. No tower geometry or layout was replaced in this urban-data expansion.
- Police stations and hospitals from the municipal OSM amenities layer are mapped as real-world POI markers when present in the source extract; a POI marker does not imply a finished interior, emergency-response gameplay, or verified operating status.

## Validation status
- Previously passed road-only source and Android validation remain documented in the prior section/history.
- The new urban source-pack build, Android installation and Godot runtime checks are pending the next GitHub Actions execution. No new pass is claimed until those jobs report success.
- Physical-device visual review, collision/driveability, frame-rate, memory and thermal acceptance remain pending.
- The new citywide urban pack is a first LOD layer, not a photorealistic finished Baghdad. Detailed facades, doors, windows, interiors, shop inventories, hospital/police gameplay and NPC staffing remain separate production tasks.

## Guardrails
- Do not delete or replace the original detailed 200 m pack.
- Do not merge this branch to main without explicit approval.
- Do not treat a mapped OSM point as proof that the corresponding building interior or service gameplay is complete.
- Keep the Power Tower independent from the Baghdad five-tower district.
