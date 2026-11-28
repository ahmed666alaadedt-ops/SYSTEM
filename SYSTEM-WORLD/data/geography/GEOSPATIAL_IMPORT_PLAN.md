# Baghdad Geospatial Import Plan

**Status:** source candidate verified; first 5×5 metric cell pack generated as a GitHub Actions artifact; conditional Godot runtime loader and Android workflow handoff implemented. Full municipal geometry is not yet imported into the default repository/runtime.  
**Target:** first production geography proof for Baghdad, Iraq.  
**Runtime CRS:** WGS84 / EPSG:4326, projected into the existing regional Godot coordinate frame.  
**Registry:** `real_world_registry.json`.

## 1. Candidate source snapshots

### Primary candidate — BBBike Iraq PBF

BBBike publishes an Iraq OpenStreetMap PBF extract:

- Direct source: https://data.bbbike.org/osm/pbf/region/asia/iraq.osm.pbf
- Dataset page: https://data.bbbike.org/osm/region/asia/iraq/
- Provider-reported last update: 2026-10-16 06:00:02 UTC
- Provider-reported size: 97 MB
- Map-data credit: © OpenStreetMap.org contributors; © BBBike.org
- Underlying OSM data license: Open Database License (ODbL) 1.0.

This source has now been downloaded and verified by GitHub Actions. The embedded OSM timestamp is 2026-11-19 23:32:47 UTC, file size is 103,097,147 bytes, and SHA-256 is `5cb6bbb8994d125ab159134c03972b3bcacc76c120661d7157844104f51c0fe5`. Relation 5638803 is present with `boundary=administrative`, `admin_level=5`, Arabic name `بغداد` and note `حدود امانة بغداد`; it contains 69 members (1 node, 55 ways, 13 relations). The relation extraction passed reference checks. Its exported geometry is a MultiPolygon with WGS84 bounds `[44.1846152, 33.1797569, 44.5699963, 33.4868251]` (west, south, east, north). A preliminary projection to UTM 38N (EPSG:32638) gives an approximate polygon area of 861.08 km². The shape and area have been preliminarily inspected, but official boundary validation is still required. The complete Baghdad municipal feature extract has not yet been integrated into SYSTEM WORLD.

### Fallback candidate — Geofabrik Iraq PBF

- Snapshot file: `iraq-261117.osm.pbf`
- Snapshot date: 2026-11-17
- File size reported by Geofabrik: 91,646,428 bytes
- Direct source: https://download.geofabrik.de/asia/iraq-261117.osm.pbf
- Region index: https://download.geofabrik.de/asia/iraq.html
- License: Open Database License (ODbL) 1.0.

A GitHub Actions runner could not connect to `download.geofabrik.de` during the first verification attempt. Keep this as a fallback candidate; do not treat the failed network request as evidence that the data or relation is invalid.

### Stale comparison source — OpenStreetData Iraq PBF

- Direct source: https://files.openstreetdata.org/extracts/IQ.osm.pbf
- Provider-reported size: 81.1 MB
- Provider index: https://openstreetdata.org/
- License: Open Database License (ODbL) 1.0.
- The downloaded file's actual last object timestamp was **2023-04-23 23:59:30 UTC**.

This extract successfully contained Baghdad relation 5638803 (`boundary=administrative`, `admin_level=5`, Arabic name `بغداد`, note `حدود امانة بغداد`) with 54 relation members (1 node, 40 ways, 13 relations). Its verified last object timestamp was 2023-04-23 23:59:30 UTC; SHA-256: `ef0e0f868d1e3a8101d8aa022c3c4e22f902c06f174b1fdc2e0e8edd900780db`. That snapshot is too old to serve as the current production source for roads, buildings or infrastructure. Retain it only as a boundary/reference comparison candidate.

All three sources derive from OpenStreetMap and require ODbL and attribution review. Do not merge their geometry until timestamps, boundaries and feature coverage have been compared.

### First municipal candidate clip — generated, not yet approved

The first reference-complete Baghdad municipal PBF clip was generated and its contributor metadata fields were cleaned:

- File size: 6,177,094 bytes
- SHA-256: `09db4b98f6f1020e9228b9a21d4eaaf8885708709ee26f93e0190eba637abf7e`
- Object counts: 756,937 nodes, 126,889 ways, 1,763 relations
- Metadata fields `version`, `timestamp`, `changeset`, `uid` and `user` are absent/cleaned in the distributed clip.
- Preliminary tag-filter counts: 42,302 building ways and 361 building relations; 64,167 road ways; 1,095 waterway ways; 835 bridge ways; 5,416 landuse ways and 152 landuse relations; 3,096 amenity ways and 32 amenity relations; 526 railway ways; 832 natural-water ways and 26 relations. Building and amenity node counts are also recorded in the registry.

The clip's object-data bounding box is `[44.0753646, 31.3210325, 46.0328698, 33.7259272]`, larger than the municipal boundary polygon. This is expected with Osmium's `complete_ways` strategy: it preserves full ways that touch the extraction polygon and does not geometrically clip their coordinates. The later GeoJSON/GIS conversion must clip feature geometry to the approved boundary or a documented buffer. Do not use the PBF bounding box as the playable-city boundary.

This is a candidate data extract, not an accepted map. The counts measure tagged OSM objects, not completeness or accuracy. Roads, bridges, water, buildings and district geometry still need spatial review and cross-checking against suitable official/independently licensed sources.

## 2. Candidate Baghdad boundary

A candidate OSM boundary reference is:

- Element: relation 5638803
- Name: Baghdad / أمانة بغداد
- OSM admin level: 5
- Boundary type: administrative
- Candidate role: Baghdad Municipality (Amanat Baghdad)

Reference pages:
- https://spatial.demo.geocode.earth/explore/place/osm/relation:5638803
- https://wiki.openstreetmap.org/wiki/Iraq

The Iraq OSM reference describes admin level 5 as Baghdad Municipality (Amanat Baghdad), with districts, sub-districts, quarters and neighbourhoods at further levels. The candidate relation must still be confirmed inside the pinned PBF snapshot and its geometry must be reviewed before use. It must not be assumed to represent every metropolitan or suburban area players may expect as “Baghdad”.

## 3. License and attribution

OpenStreetMap data is distributed under the Open Data Commons Open Database License (ODbL) 1.0.

Required project handling:
- Display clear attribution: `© OpenStreetMap contributors`.
- Link or otherwise make the ODbL 1.0 availability clear to users.
- Preserve source, snapshot date, attribution and license metadata for each imported dataset.
- Review ODbL share-alike obligations for any derivative database that is publicly distributed.
- Keep data-derived geometry distinguishable from original SYSTEM-authored gameplay content.
- Do not imply Geofabrik owns or authored the underlying OSM mapping data.

Geofabrik's PBF extracts omit contributor usernames, user IDs and changeset IDs. Do not attempt to restore or collect those personal contributor fields.

## 4. Important coverage warning

OpenStreetMap's Iraq reference page currently warns that many major highways are missing and very few waterways are mapped. This means the Iraq extract must not be treated as a complete or authoritative representation of Baghdad.

Before production use:
- Compare major roads, the Tigris, bridges, districts and key infrastructure against suitable official or independently licensed sources.
- Record coverage gaps and confidence for each feature class.
- Prefer authoritative administrative sources for legal boundaries where available.
- Do not fabricate missing roads, river paths, bridges, building footprints or landmarks.
- Keep incomplete features marked unavailable or provisional until verified.

## 5. Required data layers

The first Baghdad region pack should contain only reviewed layers needed by the game:

1. Administrative boundary and district/quarter boundaries.
2. Road centerlines, junctions, road classes, access and one-way tags.
3. Building footprints, building type and mapped height/levels where available.
4. Tigris River and other verified waterways.
5. Bridges and road/rail crossings.
6. Rail, stations and transport facilities where mapped.
7. Parks, land use and green spaces.
8. Named landmarks and public facilities.

Each feature must retain a stable source ID, source tags, geometry type, source snapshot, CRS, license and validation status.

## 6. Import and validation pipeline

1. Download the pinned PBF snapshot and verify its published checksum where available.
2. Confirm relation 5638803 exists in that exact snapshot and inspect its members, tags and boundary geometry.
3. Generate a reviewed Baghdad clipping polygon; preserve holes and multipolygon members.
4. Extract the required OSM layers against the reviewed region polygon using reference-complete ways. Osmium does not geometrically clip OSM objects: complete ways may extend beyond the polygon, so later GIS conversion must clip/render geometry against the reviewed boundary plus a documented streaming buffer.
5. Normalize tags and geometry into versioned GeoPackage/GeoJSON intermediate layers.
6. Validate geometry integrity, duplicate IDs, invalid rings, coordinate ranges, road connectivity and feature coverage.
7. Strip OSM contributor metadata (`version`, `timestamp`, `changeset`, `uid`, `user`) from distributed game data while retaining source IDs/tags needed for attribution and traceability.
8. Convert geographic coordinates through `SystemRealWorldGeography` using a region-specific origin.
9. Generate terrain, roads, water, building footprints, collision and navigation from the approved layers.
10. Package the resulting region into offline tiles; do not make runtime gameplay depend on a public tile server.
11. Run Godot import, scene, collision/navigation and map-overlay tests, then inspect the region in-editor and on Android.

## 7. World-scale and streaming gate

The current procedural continent is a small prototype, not a full-scale Baghdad map. The first OSM sample overlays real-scale vector features on the existing procedural terrain; a reviewed Baghdad elevation/DEM layer is still required before calling the terrain geographically accurate:

- `modern_continent_manager.gd` uses `CONTINENT_RADIUS_X = 1120 m` and `CONTINENT_RADIUS_Z = 790 m`, giving an approximate full width of 2.24 km and depth of 1.58 km.
- The candidate Baghdad municipal boundary spans approximately 36.0 km east-west and 34.1 km north-south, with a derived area estimate of 861.08 km².
- The municipal region is therefore roughly 16 times wider and 22 times deeper than the current procedural continent. It must not be squeezed or rescaled into the prototype terrain.
- The geography manager defines 1,000 m tile IDs, but a complete tile streaming system, region LOD, collision/navigation streaming and memory budgets have not yet been validated.

Before loading the full Baghdad region into the canonical runtime:
1. Define the global coordinate contract and preserve WGS84-derived meter scale.
2. Build region/cell streaming so only nearby cells and their required collision/navigation are loaded.
3. Keep roads and water connected across cell boundaries.
4. Define LOD, occlusion, collision and navigation budgets for Android.
5. Validate the first Baghdad cells at true scale before expanding the region.

At a 1 km cell size, the boundary envelope alone spans roughly 36 × 35 cells. This is a streaming workload, not a single monolithic scene. Do not begin detailed building placement until this world-scale and streaming gate is accepted.

## 8. Production acceptance gates

A Baghdad region pack is not production-ready until:

- The boundary source and legal/geographic scope are reviewed.
- Road, water, bridge, district and building coverage are measured and reviewed.
- OSM gaps are supplemented or explicitly marked.
- Attribution and ODbL obligations are present in the shipped data pack and user-facing map credits.
- Coordinate conversion is checked against known reference points.
- Roads and bridges connect correctly and support player/NPC navigation.
- Building footprints align with streets and terrain; no detailed building production begins from unreviewed footprints.
- Collision, navigation, LOD, memory and mobile performance are tested.
- A reviewer records the exact snapshot, checksums, source IDs and validation report.

## 9. Current boundary

The registry currently has one Baghdad coordinate anchor. The Baghdad city anchor now uses the WGS84 registry, but this plan does not mean the PBF has been imported. Real streets, district polygons, terrain, river geometry, bridges and building footprints are still absent from the canonical runtime. The other thirteen named city centers remain prototype-layout coordinates.


## 10. First 200 m metric cell proof — 2026-11-20

A reproducible cell-pack generator now exists at `SYSTEM-WORLD/tools/geospatial/build_baghdad_metric_cell_pack.py`. It converts the clipped WGS84 OSM layers into a small 5 × 5 sample around the Baghdad registry origin:

- Cell size: 200 m × 200 m.
- Cell IDs: X/Z = -2 through +2, inclusive.
- Coverage: an initial 1 km × 1 km sample around the Baghdad anchor, not the full municipality.
- Local axes and projection: the same WGS84 ECEF tangent frame used by `SystemRealWorldGeographyManager` (X east, Z south); this avoids a mismatch between exported data and the in-game regional origin.
- Layers: buildings, roads, waterways, bridges, landuse, amenities, railway, natural-water, and a dedicated `entrances` point layer for OSM nodes tagged `entrance`, `door`, or `building=entrance`. The updated workflow completed successfully (run 44736344496; artifact 14629100933): 188 entrance points were clipped to the Baghdad municipal boundary, and 30 were included in the initial 5×5 / 200 m sample pack. This is a partial sample, not a complete city-wide entrance inventory.
- Source IDs and selected OSM tags are preserved; source attribution and ODbL metadata are included in the manifest.

The first generated pack was validated in GitHub Actions run [44708930412](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/44708930412), artifact [14615624945](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/44708930412). The nested metric pack contained 25 cells and these feature parts:

| Layer | Parts in first 5×5 sample |
|---|---:|
| Buildings | 246 |
| Roads | 469 |
| Waterways | 10 |
| Bridges | 32 |
| Landuse | 179 |
| Amenities | 443 |
| Railway | 25 |
| Natural water | 13 |

This sample proves the export pipeline can create metric cells; it does not establish completeness of the OSM source, nor a full Baghdad map. Building footprints are assigned to one cell by representative point to avoid splitting individual buildings; roads, waterways, bridges and area features are clipped at cell bounds with stable source IDs.

Runtime support has now been added:
- `scripts/baghdad_osm_cell_streamer.gd` reads the extracted cell JSON files, creates first-pass building extrusions/collisions and road/water/bridge/land-use meshes, and streams nearby cells.
- `WorldManager` adds this streamer only when the regional pack manifest is present.
- `ModernWorldRegionManager` skips Baghdad's procedural district blockout when the real OSM pack is present, avoiding duplicate buildings/roads.
- `tools/validate_baghdad_osm_runtime.gd` checks that cell 0:0 creates real road, building, land-use and building-collision nodes.

The source workflow now regenerates the pack and uploads it as part of the OSM artifact. The canonical Android workflow is wired to download the pack after that source workflow succeeds, unpack it into the Godot project and run the OSM runtime validation before exporting. **End-to-end workflow-run handoff is now verified:** canonical Android build [44711157454](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/44711157454) downloaded and installed the latest successful OSM pack, validated its WGS84 origin/axes against the canonical registry, passed Baghdad OSM runtime geometry, launched the main scene headlessly, passed companion/NPC checks, and exported the APK. APK artifact 14617457540 (35.6 MB) is available from that run's Artifacts section. The pack is not checked into the repository; it is generated by the OSM workflow and injected into the APK build as a short-lived Actions artifact. Physical phone visual/performance acceptance is still pending.

Do not scale this initial 5×5 sample to the whole 861 km² candidate municipality until road/water connectivity, source coverage, cell ownership, LOD, navigation, memory and physical Android performance have been reviewed.

## Civil aeroway and passenger transport import — 28 November 2026

The Baghdad source workflow's amenities filter includes `nwr/aeroway` and exports point, linestring and polygon geometries into `amenities.geojson`. This is the existing source route for publicly mapped aerodromes, terminals, runways, taxiways, aprons and helipads; it is not a separate OSM layer file. The metric-cell pack retains the `aeroway` tag and preserves geometry. Runtime rendering handles public runway/taxiway lines and apron polygons, while military/security-tagged aeroway features are suppressed from player-facing output.

The authored `ModernWorldAirTransportManager` is separate from the factual OSM geometry. It places gameplay terminals relative to the existing world city anchors, generates routes between registered city terminals, and provides a Baghdad circular passenger airship. Baghdad's city anchor is tied to the WGS84 registry; all other current city anchors are explicitly prototype-layout positions and must not be represented as accurate real-world airport locations. A future geographic airport placement pass must use verified public airport footprints and preserve the separation between OSM exteriors and authored interiors.

The airship's approved design values are 90 m overall length, 28 m balloon diameter, 45 m passenger cabin and 40–60 passenger capacity (60 modeled seats). Its fictional Baghdad sightseeing/transport loop uses a 3 km radius, 190 m cruise altitude, 17.5 m/s cruise speed and 24-minute scheduled duration. The loop starts and ends at the elevated boarding station waypoint, with a 190 m mooring tower, elevator and passenger bridge; it is separate from real-world OSM airport records. City flight ticket state enforces scheduled duration and automatically teleports the `system_player` group member to the destination terminal at arrival; the existing city-cell streamer can react to the updated player position. Payment confirmation still uses an external receipt reference without authoritative currency debit. Live NPC passenger/crew population and robust fallback for a destination region that is not loaded remain outstanding.
