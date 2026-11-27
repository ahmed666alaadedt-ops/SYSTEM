# Baghdad Citywide OSM Coverage and Urban Expansion
Date: 2026-11-27
Repository: ahmed666alaadedt-ops/SYSTEM
Base: main at dc3d9ba942251173ef0a9a5aa57d83b097937986
Work branch: fix/baghdad-citywide-osm-road-network-20261127

## Original road coverage diagnosis
The detailed OSM artifact is limited to 200 m cells with inclusive bounds [-2, 20, -9, 2], at most 276 occupied cells. It contains Baghdad core detail and the Republic Bridge/Tigris area, not citywide road coverage. The source workflow had hard-coded those bounds and the Android workflow only installed that detailed pack.

## Road repair implemented and previously validated
- Preserved the existing 200 m detailed pack and its surveyed Republic Bridge/Tigris features.
- Generalized the metric-cell pack builder to select layers and derive cell bounds from the official boundary geometry in the same ECEF tangent coordinate frame.
- Added a separate 1 km roads-only overview pack generated from all roads clipped to Baghdad municipality relation 5638803.
- Added a second instance of the existing OSM streamer for the regional roads pack. It follows the player and loads a 3x3 neighborhood of 1 km road cells while the detailed 200 m core pack remains unchanged.
- Source workflow passed on 2026-11-27, run 46046395053.
- Verified municipal OSM source: 64,593 distinct road ways.
- Generated citywide road pack: 1 km cells, projected bounds [-17, 18, -20, 15], 927 occupied cells, 81,859 clipped road fragments, all four municipal bounding-box quadrants contain road cells, ZIP size 3,608,423 bytes.
- Detailed core pack preserved: 200 m cells, 276 occupied cells, 47 mapped entrance points, Republic Bridge and Tigris source IDs remain present.
- Canonical Godot/Android validation passed on 2026-11-27, run 46046680067. The build downloaded and installed both packs, imported the project, passed the Baghdad OSM runtime validator, launched the main scene, passed companion/NPC/Hunter validators and exported a signed debug APK.
- Runtime OSM assertions: detailed center cell roads=31, buildings=10, land-use=15, building collisions=10; Republic Bridge primary=1, secondary=1 and Tigris=1; 1 km overview center cell=198 road meshes and Republic Bridge area cell=316 road meshes.
- Android APK artifact 15222627516, 40,516,714 bytes; SHA-256 ed3872bf80e16a794de566bfd6030327e4fdca4b4b73aa8466737cb16fe69904.
- Physical-device visual review, collision/driveability, vehicle navigation, frame-rate, memory and thermal acceptance remain pending.

## Citywide urban expansion — added in this work
- Added a separate 1 km municipal urban overview pack generated from Baghdad municipality relation 5638803. It includes buildings, waterways, bridges, land use, amenities, railways, natural-water polygons and mapped entrances.
- The urban pack is streamed independently from the detailed 200 m core and roads-only 1 km overview. Its streamer loads only the active 1 km cell, uses low-detail exterior building boxes, omits per-building collision meshes and entrance interaction bodies to limit mobile CPU, memory and draw-call cost.
- Mapped amenities are classified where OSM tags are available: hospitals/healthcare, police stations, mosques, shops, restaurants/cafes, schools and civic facilities. Arabic/English OSM names and source IDs are retained when present.
- Building footprints retain OSM source IDs, building type, mapped height/floor estimate and display name. Regional overview buildings are visual LOD only; they are not yet walkable interiors or full collision-ready buildings.
- The source workflow builds and checks the urban ZIP beside the existing detailed and roads ZIPs, and reports totals by layer plus counts of classified facility types.
- The canonical Android workflow requires and installs the urban pack into SYSTEM-WORLD/data/geography/baghdad/regional_urban.
- BaghdadOSMCellStreamer supports a dedicated low-cost overview mode; WorldManager attaches it as BaghdadRegionalUrbanStreamer.
- Runtime validation checks the 1 km urban manifest, locates an occupied building cell and a POI cell, then verifies that low-detail building meshes and amenity markers are generated.

## Existing Baghdad landmarks retained
- BaghdadTowerLandmarksManager continues to generate the Baghdad connected tower district, upper sky-city platforms and links, public amenities, and the single Hunter examination tunnel.
- The Power Tower remains a separate standalone challenge destination and is excluded from the connected five-tower sky-city links.
- Existing code includes the Hunter Association tower, Business & Investment tower, Shopping tower, Antiques & Heritage tower, Technology tower and standalone Power Tower. No tower geometry or layout was replaced in this urban-data expansion.
- Police stations and hospitals from the municipal OSM amenities layer are mapped as real-world POI markers when present in the source extract; a POI marker does not imply a finished interior, emergency-response gameplay, or verified operating status.

## Urban expansion validation status
- The new urban source-pack build, Android installation and Godot runtime checks are pending the next GitHub Actions execution. No new pass is claimed until those jobs report success.
- This is a first citywide LOD layer, not a photorealistic finished Baghdad. Detailed facades, doors, windows, interiors, shop inventories, hospital/police gameplay and NPC staffing remain separate production tasks.

## Guardrails
- Do not delete or replace the original detailed 200 m pack.
- Do not change the Baghdad tower layouts as part of the OSM data expansion.
- Do not merge this branch to main without explicit owner approval.
- Keep the Power Tower independent from the Baghdad connected tower district.
- Do not treat a mapped OSM point as proof that the corresponding building interior or service gameplay is complete.
