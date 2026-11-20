# Baghdad Geospatial Import Plan

**Status:** source candidate identified; no regional geometry has been imported yet.  
**Target:** first production geography proof for Baghdad, Iraq.  
**Runtime CRS:** WGS84 / EPSG:4326, projected into the existing regional Godot coordinate frame.  
**Registry:** `real_world_registry.json`.

## 1. Candidate source snapshots

### Primary candidate — OpenStreetData Iraq PBF

OpenStreetData publishes full country extracts from OpenStreetMap raw data dumps:

- Country file: `IQ.osm.pbf`
- Direct source: https://files.openstreetdata.org/extracts/IQ.osm.pbf
- Index: https://openstreetdata.org/
- Provider-reported size: 81.1 MB
- License stated by provider: Open Database License (ODbL) 1.0.
- The public index does not publish a snapshot date for the country PBF.

This is the current primary candidate because the download host is separate from Geofabrik. The exact OSM data timestamp and SHA-256 must be recorded from the downloaded file before use. The source has not yet been downloaded, parsed or imported into SYSTEM WORLD.

### Fallback candidate — Geofabrik Iraq PBF

- Snapshot file: `iraq-261117.osm.pbf`
- Snapshot date: 2026-11-17
- File size reported by Geofabrik: 91,646,428 bytes
- Direct source: https://download.geofabrik.de/asia/iraq-261117.osm.pbf
- Region index: https://download.geofabrik.de/asia/iraq.html
- License: Open Database License (ODbL) 1.0.

A GitHub Actions runner could not connect to `download.geofabrik.de` during the first verification attempt. Keep this as a fallback candidate; do not treat the failed network request as evidence that the data or relation is invalid.

Both sources derive from OpenStreetMap and require the same ODbL and attribution review. Do not merge their geometry until their timestamps, boundaries and feature coverage have been compared.

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
4. Extract the required OSM layers and clip them to the reviewed region polygon plus a documented streaming buffer.
5. Normalize tags and geometry into versioned GeoPackage/GeoJSON intermediate layers.
6. Validate geometry integrity, duplicate IDs, invalid rings, coordinate ranges, road connectivity and feature coverage.
7. Convert geographic coordinates through `SystemRealWorldGeography` using a region-specific origin.
8. Generate terrain, roads, water, building footprints, collision and navigation from the approved layers.
9. Package the resulting region into offline tiles; do not make runtime gameplay depend on a public tile server.
10. Run Godot import, scene, collision/navigation and map-overlay tests, then inspect the region in-editor and on Android.

## 7. Production acceptance gates

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

## 8. Current boundary

The registry currently has one Baghdad coordinate anchor. The Baghdad city anchor now uses the WGS84 registry, but this plan does not mean the PBF has been imported. Real streets, district polygons, terrain, river geometry, bridges and building footprints are still absent from the canonical runtime. The other thirteen named city centers remain prototype-layout coordinates.
