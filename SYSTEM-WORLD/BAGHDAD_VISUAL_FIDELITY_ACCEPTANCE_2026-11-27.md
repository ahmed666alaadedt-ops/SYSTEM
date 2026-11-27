# SYSTEM WORLD — Baghdad Visual Fidelity and Landmark Acceptance Standard
Date: 2026-11-27
Reference: user-provided night-time futuristic river city image (uploaded 2026-11-27)
Branch: fix/baghdad-citywide-osm-road-network-20261127

## Visual target
Treat the supplied image as the visual-fidelity target for Baghdad, not as permission to replace the approved Baghdad tower composition or existing world assets. The target is a coherent, dense, cinematic 3D city scene:
- High-detail architecture with distinct silhouettes, curved and angular glass/metal facades, believable floor-to-floor structure, window grids, interior illumination, roof equipment, balconies and readable material response.
- Dense skyline depth with near, middle and far building layers; no isolated primitive boxes presented as finished buildings.
- A large Tigris river surface with physically coherent reflections, shoreline geometry, embankments, piers, marinas, boats and moving vessel traffic.
- Detailed bridges with visible pylons, cable arrays, deck structure, road markings, lights and correct river crossing alignment.
- Multi-level roads and ramps with barriers, lane markings, traffic lights, signs, vehicles and pedestrian links.
- High-density but performance-managed street life, trees, planted medians, public gardens, promenade details and crowds.
- Cinematic night lighting, emissive architectural accents, atmospheric depth, sky illumination and balanced exposure.
- Preserve mobile performance with distance-based LOD, occlusion, instancing, streaming, impostors where suitable and scalable shadow/reflection settings. Never use low-detail LOD geometry as proof of final visual completion.

## Baghdad districts and landmarks that must remain in scope
1. Existing five connected Baghdad towers and elevated upper city above the Tigris / Republic Bridge area, preserving their approved layout and identity.
2. Hunter Association tower above the five-tower district, its rooftop helipad, advertising facades and the single secret Hunter examination tunnel beneath the district.
3. The independent X-S-X Power Tower, kept separate from the five Baghdad towers and its upper city links.
4. Baghdad residential city fabric: detached houses, apartment blocks, luxury villas and palaces, mixed-use buildings, commercial streets, shops, restaurants, cafes, clothing stores, workshops, markets and service alleys. Villas and palaces need distinct footprints, heights, facade treatment, boundary walls, gates, landscaped grounds and driveways where mapped; do not render them as ordinary house boxes.
5. Mosques and Islamic religious buildings, plus Christian churches and other mapped places of worship. Keep distinct building silhouettes and labels; do not classify every place of worship as a mosque.
6. Hospitals, clinics, pharmacies, police stations, fire and civic services, schools and other public facilities. OSM markers are only mapped locations until full building interiors and gameplay are implemented.
7. Tigris riverfront, bridges, promenades, marinas, parks, roof gardens, transport and street furniture.
8. The separate swamp-land region (أرض المستنقعات): preserve its existing work and connections; do not replace it with a few wetland polygons or merge it into ordinary Baghdad city tiles. Keep its wetlands, water channels, mud banks, vegetation, wildlife, paths, settlements and gameplay as its own environment.
9. Antiques & Heritage Tower / museum exhibits, plus a distinct walkable Antiques and Artifacts Market (سوق التحف والآثار). Museum exhibits and the player market are different features. The market requires browseable listings, seller-defined prices, secure item reservation/escrow, buyer balance validation and debit, atomic ownership transfer, seller payout, cancellation/refund and anti-duplication/replay protection.

## Current implementation distinctions
- The Baghdad landmark manager already contains the connected tower district and a 34-floor Antiques & Heritage museum exhibit system. This does not prove a fully finished player-to-player artifact marketplace.
- The citywide 1 km OSM urban overview is a low-detail exterior LOD layer. OSM building values for villas and palaces are now classified separately in the overview renderer, with distinct material and display metadata; this is a classification/rendering foundation, not finished luxury architecture. It does not yet meet the image's final visual standard and does not provide detailed interiors or collision-ready walkable buildings.
- Christian church classification has now been added to the regional POI renderer alongside mosque classification. It still requires source-pack and runtime validation.
- The separate swamp-land environment is a preserved project feature and must be checked independently; this Baghdad urban expansion must not replace or reset it.
- Hospitals and police stations mapped as POIs are not equivalent to complete hospital/police buildings, interiors, NPC staffing, dispatch or emergency gameplay.

## Acceptance checks before calling the visual target complete
- Representative street-level, aerial and riverfront views at night and day.
- At least one complete residential street, commercial street, mosque, church, hospital and police station with finished exteriors and walkable interiors where intended.
- Five-tower district, Hunter tower, Republic Bridge and riverfront visually reviewed together without layout drift.
- Independent swamp-land region and artifact market entered and functionally tested.
- No obvious primitive placeholder buildings in close or medium view.
- Android device testing for frame rate, memory, heat, streaming seams, collision, navigation and draw-call stability.
- Automated source/build tests plus visual review on the target Android device. A successful APK export alone is not visual acceptance.

## Non-negotiable project guardrails
- Preserve existing useful work and approved reference designs.
- Do not replace the swamp-land world or the five-tower Baghdad layout.
- Keep the Power Tower independent.
- Do not merge to main or claim complete until validation and explicit approval.

## Exact composition cues from the supplied reference image
These are explicit visual requirements in addition to the general target above. Preserve the range of shapes and the layered composition; do not reduce the reference to generic glass towers beside a river.

### Building silhouettes and facade language
- A varied skyline: slender tall towers, broad sculptural towers, curved sail-like profiles, tapered crowns, angular crowns, and facades that lean or sweep in smooth arcs.
- Include the prominent tall central tower language: a narrow, tapering high-rise with a curved top/crown and a visible structural lattice/diagrid treatment, plus neighboring curved towers with luminous cyan edge lines.
- Mix rounded/arched building cut-outs, concave and convex facades, stepped terraces, podiums, layered horizontal bands and complex rooflines.
- Use glass curtain walls, metal ribs, fine structural grids, visible floor divisions, dense window patterns, warm interior office lights and restrained cyan/blue architectural accents.
- Towers must have distinct silhouettes and believable proportions; do not clone one tower mesh repeatedly. Surround landmark towers with a dense, varied background skyline.

### Bridge and transport structures
- Include a major cable-stayed bridge crossing the river: tall sculptural pylons, clearly separated fan-shaped cable arrays, realistic deck thickness, support structure, barriers, road surface, lane markings and integrated night lighting.
- Retain other bridges and river crossings as distinct structures; do not represent all crossings with one repeated bridge model.
- Include elevated curving expressways, sweeping ramps, multi-level junctions and waterfront roads, with visible columns, guardrails, lane markings, signs and traffic.
- Ensure bridge pylons, cables, bridge deck, road approaches and river banks meet continuously with correct scale and alignment.

### Riverfront, public realm and atmosphere
- Keep the broad river visible as a major part of the composition, with reflective night water, physically coherent reflections of towers and bridge lights, shoreline promenades, stepped embankments, piers and marina edges.
- Add varied boats and passenger vessels at different distances and scales, with navigation lights and wakes; retain waterfront pedestrian zones, trees, planted terraces and crowds.
- Recreate the depth of the image: foreground waterfront and roads, middle-ground river and bridge, and a dense illuminated skyline receding into the night atmosphere.
- Include the aerial light trails / distant moving traffic visible in the sky as a restrained city-transport effect where appropriate, without making it obscure the architecture.

### Acceptance rule
A Baghdad scene is not accepted as matching this reference if it only has generic towers, a flat water plane, a simple bridge slab, repeated primitive buildings or decorative neon strips. Review the complete composition and each major structure from aerial and street-level views. Preserve the approved Baghdad five-tower district identity and keep the independent Power Tower separate.
