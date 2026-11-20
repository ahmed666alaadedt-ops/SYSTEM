# SYSTEM WORLD — Real Earth Geography & Living Society

**Decision status:** canonical direction for the modern world  
**Initial implementation region:** Baghdad, Iraq  
**Runtime target:** Android first, with scalable PC/console targets later

## 1. World geography decision

The modern world is based on the real Earth, not a fictional continent populated with real city names. Country, city, coast, river, mountain, road and district positions must be grounded in geospatial datasets and their declared coordinate reference systems.

The current procedural continent and its generated city anchors are retained as a prototype/reference layer until real regional data has been imported and reviewed. They must not be described as real-world geography or silently treated as the final map.

### Geographic data contract

Every imported feature must retain:
- Stable feature ID and feature type.
- Country, region, city and district identifiers where applicable.
- WGS84 coordinates (EPSG:4326) or an explicitly declared source CRS.
- Geometry and elevation references, including geometry version.
- Source provider, dataset name, retrieval/version date and license.
- Required attribution text and any share-alike obligations.
- Import status: provisional, validated, generated, reviewed or production.

Never invent coordinates, boundaries, roads or landmark positions for real places. If data is missing, mark the feature as unavailable rather than fabricating a real-world claim.

### Coordinate and world-space architecture

- Store geographic source coordinates as latitude/longitude in WGS84.
- Convert to Earth-centered coordinates and then regional east/up/south local coordinates for Godot.
- Use a regional origin and floating-origin/rebasing strategy; do not represent the whole planet in one enormous Godot coordinate frame.
- Divide regional data into independently loadable tiles. The initial default is 1 km, subject to profiling and source density.
- Keep tile identity independent of display meshes so roads, buildings, terrain, vegetation and points of interest can stream at different LODs.
- Store offline region packs for gameplay. Do not make the live game depend on a public map server.
- Generate actual meshes, collision and navigation from approved source data; a 2D map image is not a playable environment.

### Data layers

1. Country and administrative boundaries.
2. Elevation/DEM, terrain and water bodies.
3. Road centerlines, junctions, access rules and lane metadata.
4. Building footprints, height/levels and building type.
5. Rail, airports, ports, bridges and tunnels.
6. Parks, trees, vegetation and biome context.
7. Named landmarks and points of interest.
8. SYSTEM gameplay overlays: gates, incidents, guilds, hospitals, discoveries and player markers.

### Expansion strategy

The first production proof is a small, real Baghdad region. It must validate the entire pipeline from licensed source data to regional coordinates, terrain, streets, building footprints, collision/navigation, Godot scene and offline package. Expand to the rest of Baghdad, Iraq, neighboring countries and then other continents only after the pipeline is stable.

The star-gate inter-world hub remains Baghdad only. Monster gates and ordinary world events may occur in other cities according to gameplay rules.

## 2. Living NPC society

NPCs are persistent residents, not decorative crowd props. Their lives continue while the player is elsewhere, but the simulation uses tiers so a phone does not simulate every resident at full detail.

### Individual identity and life

Each resident can have:
- Stable ID, name, age and life stage.
- Home, district, family links, friends and personal history.
- Occupation, employer, work schedule, wallet and savings.
- Health, hunger, thirst, energy, hygiene, social and wellbeing needs.
- Current activity, current location, daily schedule and recent memories.
- Relationships, marriage, children and generational family records.

### Daily routine

The schedule can include waking, washing, eating, drinking, commuting, working, shopping, studying, socializing, visiting family, resting and sleeping. Work creates income; shopping and services consume money. Needs affect which activity is selected.

### Society simulation tiers

- **Near-player tier:** real navigation, animation, interaction, traffic participation and full decision updates for a small budgeted group.
- **Same-city tier:** scheduled decisions, destination changes, work, household and economy updates without per-frame character simulation.
- **Distant-region tier:** coarse time-step updates to needs, wages, household state and important life events.
- **Dormant/offline tier:** deterministic catch-up when a region is loaded again, with strict caps to avoid huge simulation spikes.

Use stable seeds and bounded update batches. Do not run every NPC's full AI every frame.

### Safety and gameplay boundaries

NPCs may work, travel, trade, gather ordinary information, socialize, form relationships, marry and have children. They do not complete player main quests, solve player puzzles, reveal protected solutions, join the player's combat missions, or form the player's guilds and clans.

Civilian schedules must never bypass the Baghdad-only star-gate rule.

## 3. Initial code foundation

- scripts/real_world_geography_manager.gd: WGS84 to regional Godot coordinates, city registry lookup and tile IDs.
- data/geography/real_world_registry.json: provisional Baghdad/Iraq geographic anchor; not a complete city dataset.
- scripts/npc_daily_life_manager.gd: bounded batch simulation for resident needs, schedules, work, money and social/family routines.
- scripts/ai_npc_society_manager.gd: existing persistent identity, family, memory and relationship record system remains the society data owner.

## 4. Honest implementation boundary

The first Baghdad registry point is only a coordinate anchor. It does not contain Baghdad's real road graph, district polygons, terrain raster, building footprints or landmark geometry. The resident simulation creates persistent civilian records and routine state; it does not yet produce fully animated visible pedestrians or complete navigation routes.

Godot import, parser, scene launch, Android build and device performance must be run on a workstation with the approved Godot and Android toolchain before these additions can be called runtime-verified.



## 5. Candidate Baghdad geospatial sources — not yet imported

- Verified source candidate: BBBike Iraq OpenStreetMap PBF. GitHub Actions verified the downloaded snapshot timestamp as 2026-11-19 23:32:47 UTC and SHA-256 `5cb6bbb8994d125ab159134c03972b3bcacc76c120661d7157844104f51c0fe5`.
- Candidate source URL: `https://data.bbbike.org/osm/pbf/region/asia/iraq.osm.pbf`.
- Fallback candidate: Geofabrik Iraq PBF snapshot `iraq-261117.osm.pbf`, dated 2026-11-17. GitHub Actions could not connect to its download host during verification.
- OpenStreetData Iraq PBF was successfully downloaded and relation 5638803 was found, but its last OSM object timestamp was 2023-04-23 23:59:30 UTC. It is stale and is retained only for boundary/reference comparison, not current road/building production.
- OSM relation 5638803 is present in the verified BBBike snapshot: Arabic name `بغداد`, note `حدود امانة بغداد`, `boundary=administrative`, `admin_level=5`, 69 members (1 node, 55 ways, 13 relations). Its exact municipal coverage and geometry still require geographic review.
- OSM data uses the Open Database License (ODbL) 1.0. Preserve `© OpenStreetMap contributors` attribution and applicable share-alike obligations; include BBBike attribution when its extract is used.
- OSM's Iraq reference page warns that many major highways and very few waterways are mapped. All candidate extracts require coverage review and supplementation from suitable official or independently licensed sources.

The source candidates and verified snapshot metadata are recorded in `data/geography/real_world_registry.json`. The staged workflow, provenance, licensing, quality gates and offline packaging plan are documented in `data/geography/GEOSPATIAL_IMPORT_PLAN.md`. The relation-only boundary extraction passed reference checks, but the complete Baghdad municipal data pack has not yet been generated or reviewed. No real roads, district polygons, water geometry, bridges or building footprints from this source are yet present in the runtime. Do not treat relation verification as a completed Baghdad map or as permission to begin detailed building production.

## 6. Civilian crime, public safety and justice layer

The modern society supports crime as a systemic world event rather than a graphic spectacle. The first implementation extends the existing city crime response manager with persistent case records and a justice workflow.

### Crime categories
- Theft, robbery, assault, murder, harassment and stalking.
- Kidnapping, domestic abuse, child abuse, human trafficking and exploitation.
- Fraud, vandalism, arson and corruption.
- Vehicle theft remains connected to the existing witness and police-pursuit prototype.

### Case lifecycle
- A crime report records its type, city/location, suspect/victim IDs, witness count, evidence tags, severity and timestamp.
- Investigators can record arrival, witness interviews, evidence collection, suspect identification and victim-support contact.
- Cases can be sent to trial. Convictions require a minimum evidence score; a guilty verdict can place the NPC in detention for a sentence.
- NPC daily-life updates count down detention time and record release. Conviction affects reputation and routine access.
- Murder can record a confirmed NPC death in the society history. The crime itself is represented through records and consequences, not graphic animation.

### Victim care and protection
- Sexual assault, trafficking, exploitation, kidnapping, domestic abuse and child abuse trigger a private protection state and a support-request signal.
- Victim memories store only a private case reference and category; explicit details are not recorded.
- A report is not automatically treated as proof of guilt. Evidence and a trial outcome remain separate steps.

### Adult consensual sex work
- Adult independent sex work can be represented as a non-explicit civilian occupation.
- Registration requires an adult NPC and voluntary participation.
- Coercion, trafficking, and under-18 involvement are rejected and routed to protection/crime reporting.
- No sexual acts, explicit scenes, or coercive sexual content are simulated.

### Current implementation boundary
These are callable simulation APIs and persistent records, not a complete police department or courtroom scene. Patrol navigation, emergency calls, witness AI, evidence-object interaction, lawyer/prosecutor roles, court NPCs, and detailed social consequences remain staged work. No claim is made that the full society is already equivalent to real human life.
