# SYSTEM WORLD — Hunter Association and Power Tower Design

## Current approved Baghdad layout

Baghdad has **exactly five connected district towers** across the Karkh–Rusafa corridor:

1. Hunter Association
2. Business and Investment
3. Shopping and Commerce
4. Antiques and Heritage
5. Technology and Innovation

The Hunter Association Tower is one of the five, and is the central tallest tower above the upper city, aligned with Republic Bridge and the Tigris. It is 650 m / 200 floors, carries the XSX guild identity on all four exterior faces, has inward- and outward-facing advertising facades, and a functional rooftop helipad with an attached flight controller.

The connected district is an elevated, traversable city layer above the river/bridge corridor. Keep its skyways, public facilities, hotel, restaurants, pools and fifteen sky gardens. Public leisure facilities are not extra towers.

The Power Tower is a separate standalone 200-floor challenge destination away from Baghdad. It is never counted among the five district towers and must not join their skybridge or vehicle-deck loop.

## Active Hunter discovery, recruitment and tunnel route

The approved player route is one continuous underground examination tunnel, not a multi-city or multi-stage journey.

1. The player discovers the Hunter Association in Baghdad and enters its public lobby.
2. On arrival, an Arabic invitation asks whether the player wants to become a Hunter. The player can accept or decline.
3. Declining leaves registration unchanged and allows the player to choose again on a later visit.
4. After acceptance, the player follows the visible Hunter Guild guide.
5. The guide escorts the player from the Hunter Association Tower to the single permanent underground examination tunnel beneath the district.
6. The candidate serial is allocated, saved and shown only when the player reaches the tunnel.
7. Re-entry reuses the saved serial. The system must not allocate a second number to an already registered candidate.

The tunnel competition is continuous and contains three ordered physical checkpoints. It includes 500 individually tracked background candidates and five named interactive rivals. The background crowd uses shared MultiMesh rendering and lightweight non-combat decision profiles; it is not represented as 500 full physics/pathfinding agents with individual combat and dialogue.

The five named rivals retain their individual behaviors:
- Ren: objective theft and recovery/progression blocking
- Kai: deception
- Mira: ambush and pursuit
- Sami: fair rivalry
- Daigo: individual combat duel

Candidate numbers currently persist locally on the installation. Global uniqueness across accounts/devices and server-authoritative anti-cheat verification are not claimed.

The Al-Zawraa Park footprint in central Baghdad is permanently repurposed as the Baghdad Mesopotamian Marshland and Hunter Examination biome. This is a major green agricultural and wetland reserve, not a bare water swamp. The initial playable footprint is an approximately 0.48 km² elliptical reserve (840 m × 720 m bounding dimensions). The modern terrain height field is extended as a connected Al-Zawraa peninsula so the reserve sits on its exact WGS84 park anchor; a nearest-land fallback is retained only if the regional terrain data cannot resolve the anchor. The reserve remains physically connected to the far end of the existing Hunter Examination tunnel by a continuous walkable underground passage. This extends the same Hunter examination journey; it does not create seven separate stages, a second unrelated exam, a teleport at the tunnel exit, or change the Hunter Tower invitation/guide flow.

### Approved marshland environment
- Fertile cultivated plots, vegetable gardens (12 plots / 432 crop instances), wet soil, grassy banks, willow groves and dense reed beds.
- Eight shallow marsh pools, muddy channels, lily pads and shallow swim volumes.
- 1,800 reed instances, 56 willow trees, nine raised wooden boardwalk segments and nine illuminated route-arrow markers.
- Fourteen animated low-lying mist layers with seasonal tint/density; the scene maintains cinematic swamp fog and low visibility without making the route unreadable.
- The marsh entrance begins at the tunnel's physical exit and the boardwalk network continues toward the hidden ancient sanctuary. The WGS84 park anchor is retained; if the exact projected point falls outside the current terrain's land mask, the runtime nudges the visual center to the nearest land point within 300 m and records the offset.
- The region uses Al-Zawraa Park's WGS84 anchor (33.31496, 44.37818) projected through the Baghdad regional origin. Preserve the five Baghdad towers and their approved exterior silhouettes.

### Hunter examination gameplay inside the marsh
- Twelve visible candidate/false-guide NPCs populate the marsh. Some deliberately provide misleading route hints; they are not the genuine Hunter Guild guide.
- Nine directional route markers guide candidates toward the intended route and hidden sanctuary. Their placement is readable through the fog, but they do not guarantee safety.
- Six giant wildlife encounter profiles are present: giant marsh turtles and ancient swamp beasts. Each has a moving enemy body wired to the existing combat system; approaching activates its C-rank combat behavior, while candidates may fight or attempt to escape.
- Five forbidden-route hazard zones can fail an active candidate's exam when entered.
- The trial mood is inspired by the dangerous, deceptive swamp atmosphere of the Hunter Exam in Hunter × Hunter, while all SYSTEM WORLD characters, routes, creatures and locations remain original.
- The test remains one continuous journey from the tunnel into the marsh; do not reintroduce the retired seven-stage exam wording.

### Hidden ancient sanctuary and seasonal Star Gates
- A concealed ancient heritage site sits at the far end of the marsh route, beyond the reeds and boardwalks. Its ruins are hidden until an active candidate reaches the discovery area; only then does the sanctuary reveal itself.
- Three Star Gates are hidden there. They unlock only after the registered candidate completes the full continuous tunnel-plus-marsh exam at the sanctuary; completing the tunnel checkpoints alone must not award the license or reveal the gates.
- Gate destinations rotate by season and resolve to existing city anchors in the modern world. The current destination pools are: spring — Tokyo, Paris, Singapore; summer — Cairo, Sydney, Guangzhou; autumn — London, Seoul, New York; winter — Moscow, New Delhi, Rio de Janeiro.
- The three gates therefore provide changing destinations each season; their labels and destinations must reflect the current season, and gate travel must use the existing modern-world city anchors rather than inventing city coordinates.
- Future seasons can add or replace destinations without rebuilding the sanctuary. The gates are an in-world discovery and travel system, not an external URL or a claim that new world maps are already built.

## Restaurant and Shopping Tower boundary

The Shopping and Commerce Tower restaurant keeps its own ordering, seating, meal delivery, waiter and chef lifecycle. It is not the active Hunter examination entrance.

The old restaurant secret-riddle, private-room meal gate, restaurant elevator, and multi-stage examination prototypes are historical implementation directions, not the current approved player route. Do not restore them or let them replace the Hunter Tower invitation and guide escort.

Weapons, swords, spears, axes, bows, firearms, shields, armor, helmets, modern armored outfits, equipment upgrades, repairs, crafting, Nen-awakening/control/recovery elixirs, skill manuals and player marketplace departments remain inside Shopping and Commerce Tower. They are not separate towers.

## Power Tower — 200-floor individual challenge

The Power Tower is an independent destination with its own entrance, progression, arenas, spectators, staff and rewards.

- Exactly one player fights exactly one opponent in each official round (1v1).
- Standard, elite and boss fights remain individual duels; team battles, party fights, enemy waves and group combat competitions are prohibited.
- Every tenth floor is a boss duel; every fifth non-boss floor is an elite duel.
- Floor 200 is the unique final sovereign boss duel.
- The progression uses ranks F through SSS, floor requirements, clear-time records and player progression rewards.
- Spectators and supporter groups are non-combat social activities. Prediction tickets use SYSTEM virtual currency only; no real-money betting or cash-out.
- The separate Power Tower does not receive Baghdad's five-tower public-customer or sky-garden allocation.

The 200 floors are grouped into ten visual environment chapters of twenty floors each: Iron, Desert, Frost, Volcanic, Jungle, Royal Ruins, Storm, Shadow, Celestial and Sovereign. Generated arenas receive matching floor-deck materials, illuminated rings, themed pylons and arena titles. Floor 200 uses the unique Sovereign theme.

The Power Tower is a substantial local gameplay foundation, not a claim of production online PvP matchmaking. Signed server-result verification, global leaderboards, authoritative online records, final art for every floor and physical Android performance inspection remain separate release gates.

## Current implementation and verification boundary

Relevant runtime files include:
- `scripts/baghdad_tower_landmarks_manager.gd` — five connected Baghdad towers, central Hunter tower, separate Power Tower, helipad, underground tunnel and Al-Zawraa marshland attachment.
- `scripts/baghdad_marshland_manager.gd` — Al-Zawraa agricultural wetland, fog, deceiving Hunter NPCs, giant wildlife, route arrows, wrong-route failure hazards, hidden ancient sanctuary, seasonal Star Gates and physical Hunter-tunnel connection.
- `scripts/system_hunter_candidate_crowd.gd` — 500 tracked candidate records with shared rendering and lightweight background behavior.
- `scripts/system_hunter_exam_manager.gd` — candidate registration, persistent serial, tunnel arrival and continuous competition state.
- `scripts/hunter_guild_menu.gd` and the Hunter recruitment/guide runtime — invitation, accept/decline and guide escort.
- `scripts/system_power_tower_manager.gd` — separate 200-floor progression, rank and duel records.

Automated validation on the current branch has passed the following areas on the latest verified runtime snapshot:
- Baghdad five-tower landmarks, Republic Bridge/Tigris placement, upper city and separate Power Tower.
- Hunter Tower invitation, guide-led tunnel escort and serial allocation.
- One continuous tunnel competition with three ordered checkpoints, 500 tracked candidates and five named rivals.
- Baghdad tower operations, elevator/emergency lifecycle, terrain streaming, child-character safety, WGS84 anchor, Baghdad-only Star Gate hub and Greed Island return.
- Android marketplace bridge request/response correlation and allowlist behavior.

The full tower-interiors/hotel/shopping regression and current full-project workflow are still being re-run on the latest branch head. Firebase marketplace emulator tests and Android APK export/builds have passed on recent branch snapshots. These are automated checks, not physical Android visual inspection or proof of live cross-account trading between two deployed player accounts.

## Release discipline

- Continue the Al-Zawraa Marshland work on `feature/baghdad-marshland-connection-20261125` and draft PR #39. PR #38 was already merged to `main` before this marshland scope began.
- Preserve existing systems; do not recreate completed towers, interiors, tests or workflows from scratch.
- Keep PR #39 as a draft and do not merge into `main` without explicit user approval.
- Do not claim final visual/device completion from headless tests or APK export alone.
