# SYSTEM WORLD — Continuous Production Queue for Codex

**Status:** execution brief; not a claim that the listed work is implemented.  
**Canonical runtime:** `SYSTEM-WORLD/` (Godot 4.3 project).  
**Reference prototype:** `SYSTEM-WORLD-3D/` — preserve as a separate project.  
**Primary target:** Android first; keep architecture extensible to PC/PlayStation without claiming those ports are complete.

## Mission and operating mode

Continue the existing SYSTEM repository from its real current state. Implement the largest safe amount of production work supported by the current environment, in the order below. Do not stop after writing a plan if code, assets, tests, or documentation can actually be produced. Do not attempt an unsafe all-at-once rewrite. Work phase by phase, commit each coherent verified increment, update the relevant tracker, then continue to the next unblocked phase in the same Codex run.

If context/time limits prevent finishing the whole queue, leave an exact handoff in `SYSTEM-WORLD/CODEX_CONTINUATION_STATUS.md` naming the last completed phase, next action, changed files, commits, test evidence, and blockers. Never claim background work or completion that did not happen.

## Non-negotiable project rules

1. Read root `AGENTS.md`, `SYSTEM_MASTER_VISION.md`, `SYSTEM_WORLD_MASTER_SPEC.md`, `SYSTEM-WORLD/PROJECT_TECHNICAL_ROADMAP.md`, `SYSTEM-WORLD/ASSET_REGISTER.md`, and relevant feature specs before editing. Check nested agent instructions.
2. Preserve the Android app, Firebase/authentication/account/progression work, both Godot projects, existing scenes, systems, and all required files. Never replace the project or delete features to simplify work.
3. `SYSTEM-WORLD/` is canonical runtime. Do not merge or rename `SYSTEM-WORLD-3D/`.
4. Exactly four independent worlds must remain: Modern, Historical/Civilizations, Fantasy/Mythical, and Greed Island. Shared code is allowed; world identity, content, rules, geography and progression remain distinct.
5. Baghdad is the only star-gate hub for travel between worlds. No inter-world star gates in other cities. Monster gates may appear in any city/world where specified. Greed Island is reached through its Baghdad star gate and retains its seasonal/ticket access design.
6. Modern-world real cities/countries retain their real names, geographic placement, cultural identity and recognizable landmarks. Do not present prototype coordinates as accurate real geography. Expand the real-world registry only with verified geographic data.
7. Baghdad must preserve the Tigris as an open flowing navigable river; preserve Karkh/Rusafa, Tahrir Square and the Freedom Monument. The five-tower vertical city is one connected district across the Karkh–Rusafa corridor, with five distinct identities: Power, Hunter Association, Business, Shopping, Entertainment. Do not bury or overwhelm protected landmarks or obstruct the river.
8. AI NPCs may live, work, travel, trade, gather information, communicate, form relationships, marry and have families. They must not autonomously complete the player's main quests, solve player puzzles, fight the player's battles, or take over player organizations.
9. No fake features: a UI, marker, data model, placeholder mesh, signal, or source-code connection is not a finished gameplay feature. Clearly distinguish implemented, connected, tested, visually reviewed, and device-verified states.
10. No paid services/dependencies without explicit approval. No secrets, credentials, private data, or unsafe client-authoritative economy. Real-money rewards/payments and shared ownership require approved secure server-side design; do not simulate them as live.
11. Android performance is a first-class requirement: scalable quality tiers, streaming, LOD, pooling, efficient collision/materials/lights, memory budgets, touch controls and stable frame pacing.
12. Never copy protected game assets, characters, maps, music, logos, dialogue or distinctive scenes. Use original designs and record source/licence/attribution for every external asset.

## Phase 0 — Baseline and repository integrity

- Inspect branch, working tree, recent commits, workflows, both Godot projects, Android app, Firebase configuration, scenes, autoloads, resource paths, scripts, assets and nested instructions.
- Read the current completion tracker and reconcile it against code and workflow artifacts. Do not assume a checked item is runtime-tested.
- Inspect open branches/PRs and identify useful unmerged work. Do not merge unrelated branches or overwrite user work. Report any important unmerged production pipeline PR separately.
- Confirm actual Godot/Blender/Android tool availability and versions before running commands.
- Establish a baseline test/build record and record exact blockers.

**Acceptance:** baseline report and no unrelated changes/deletions.

## Phase 1 — Complete Baghdad source-mapped buildings and real entrances

Current starting evidence in the tracker: an OSM Baghdad boundary pack and a source-mapped entrance layer exist; 188 entrance points were extracted, with 30 in the initial 5×5 sample of 200 m cells. This is source coverage, not a guarantee that every building has an entrance. A successful Godot validation and Android APK export are recorded, but physical-device gameplay is not established.

- Validate source data, attribution/ODbL obligations, IDs, geometry, coordinate reference, cell boundaries and missing/duplicate features.
- Associate each mapped entrance node with the correct building polygon/OSM building ID using distance, topology, containment and confidence scoring. Reject ambiguous associations; never invent a real entrance from a nearest-road guess.
- Preserve access, private, service, emergency and wheelchair tags. Enforce access restrictions in interaction logic.
- Create original door meshes/animations only where a reliable mapped or manually authored entrance exists. Add collision, interaction ray targets, open/close state and safe doorway clearance.
- Build reusable interior architecture for homes, apartments, shops, hotels, hospitals, offices and public buildings: floors, rooms, stairs, lifts, exits, loading and unloading.
- Ensure the player cannot be unloaded or stranded during cell streaming. Persist discovered entrances, doors, owned/rented property and interior state.
- Provide Arabic-first interaction prompts and readable mobile inspection UI.
- Keep OSM source IDs and attribution in the data pipeline.

**Acceptance:** entrance-to-building association report with confidence and rejected cases; automated geometry/data tests; Godot import/scene/interior transition tests; streaming tests; Android performance evidence where available. Do not claim all Baghdad buildings are enterable if source coverage is incomplete.

## Phase 2 — Baghdad geography and five-tower connected city

- Continue from the existing metric-cell OSM streamer and current map foundation. Expand coverage through staged geographic packs; do not load the entire municipal area as one unbounded scene.
- Validate official boundary, roads, district data, elevation, hydrology and land/water alignment before production promotion.
- Build the five towers as a connected multi-level district integrated into real central Baghdad geography. Retain five distinct tower identities and clear skyline silhouettes.
- Keep the Tigris visibly open below/through the district, preserve river navigation and riverfront access, and protect Tahrir Square/Freedom Monument sightlines.
- Add tested skybridges, promenades, ramps, elevators, pedestrian paths, accessible routes, service/emergency access, parking and public transit links. Visual shafts and ramp blocks are not working lifts/roads.
- Create actual usable interiors and facilities: Power Tower arenas/training; Hunter Association reception, mission hall, exam offices, training, research, medical support and honor hall; Business Tower offices; Shopping Tower malls/shops/food/cinema; Entertainment Tower parks, pools, sports, events and family recreation.
- Validate from Karkh, Rusafa, Tigris waterfront and Tahrir Square views.

**Acceptance:** geographic alignment checks, collision/navigation checks, playable entry/exit, lift/ramp tests, river and landmark clearance checks, Android streaming/performance checks.

## Phase 3 — Roads, vehicles, transport and racing

- Turn road visuals into a connected road graph with lane direction, intersections, sidewalks, crossings, signs, traffic rules, collision and emergency access.
- Complete the existing vehicle prototype: dedicated accelerator/reverse/brake/exit HUD; steering, suspension, traction, braking, damage, recovery, camera modes, mobile input and safe vehicle entry/exit.
- Implement garages, dealerships, ownership, keys, parking, repairs, fuel/charging, towing, resale and persistent inventory. Keep prototype local credits clearly separated from any future secure shared economy.
- Implement lane-aware traffic AI, signals, yielding, parking, emergency vehicles, density streaming and pedestrian safety.
- Complete race circuits and street racing: GT, formula-style, endurance, drift, rally, drag/quarter-mile and city street events; checkpoints, lap timing, results, rewards, leaderboards, safe resets, police response and spectator areas.
- Add police pursuits with escalation, roadblocks, arrest, fines, impound and reputation consequences. Keep civilian safety and anti-griefing rules.
- Turn airport, rail, bus, taxi, port, ferry and ship prototypes into usable transport only when route, schedule, boarding, fare, controls, collision and save/network behavior exist.

**Acceptance:** playable driving/racing loops, route and collision tests, AI traffic tests, persistence tests, Android touch tests and measured performance.

## Phase 4 — Living modern city and public services

- Complete pedestrians, residents, vendors, workers, families, schedules, homes, jobs, needs, sleep/rest, food/water, relationships and local social activity.
- NPC simulation must be persistent enough to resume state, but use distance/importance-based simulation tiers to fit mobile budgets.
- Make hospitals, police/fire, hotels, markets, shops, restaurants, cafes, garages, schools, universities, stadiums, banks, pharmacies, bakeries, parks, cinemas and fitness facilities genuinely interactive.
- Add jobs, salaries, business ownership, rent, property, inventories, supply/demand, trade, repair and legal transactions. Protect accounts and shared economy against client-side cheating.
- Add crime, witnesses, evidence, dispatch, patrols, arrests, jail, fines, vehicle impound, reputation and access consequences.
- Add public transport schedules and city events. Do not make all city life combat-centric.

**Acceptance:** end-to-end interactions for each service category, save/load tests, NPC schedule/needs tests, economy integrity tests and performance limits.

## Phase 5 — Modern-world terrain, climate, nature and complete map systems

- Continue existing continent, archipelago, biome, coastal, hydrology, river, mountain, canyon, plains, forest, wildlife and marine managers; reconcile ownership and avoid duplicate geometry/water overlays.
- Build natural landforms with coherent elevation, watersheds, rivers, lakes, coastlines, islands, beaches, cliffs, caves, ravines, mountain passes and traversable routes.
- Add city/rural links, farms, orchards, villages, fields, local services and regional economies.
- Complete day/night, real-time calendar, seasons, weather, fog, dust, wind, rain, wet roads, puddles, snow only in suitable climates, and climate-appropriate ambience.
- Add wildlife habitats, population limits, animation, daily activity and safe interactions.
- Finish map discovery, waypoints, fast travel activation only after discovery, hospitals/healers, transport and persistent map state.
- Keep real-world place names and geography accurate; expand each city only after its verified data pack exists.

**Acceptance:** geography/data validation, terrain/water continuity, traversal/collision tests, streaming/LOD checks, day/night/weather inspection and Android performance measurements.

## Phase 6 — Historical and civilizations world

- Preserve a distinct historical world with accurate, research-based civilizations and period-specific architecture, materials, clothing, tools, weapons, trade, transport and social structures.
- Build original explorable regions for Mesopotamia/Sumer/Babylon, ancient Egypt, Alexandria, Greece, ancient China and other approved civilizations as separate regional content.
- Add archaeology, ruins, settlements, markets, farms, ports, temples, palaces, roads, historical NPC roles, daily life, trade, quests and environmental storytelling.
- Separate documented history from mythic/fictional elements. Mythic-historical figures and stories may appear only with clear world-lore treatment and must not collapse the Fantasy world into this one.
- Build interiors, traversal, combat and mission loops appropriate to each era; do not reuse modern vehicles/weapons where historically inappropriate.

**Acceptance:** region identity and period review, playable exploration, NPC/service loops, collision/navigation and Android asset budgets.

## Phase 7 — Fantasy and mythical world

- Maintain a fully independent original fantasy setting with kingdoms, castles, settlements, guilds, factions, magic, dragons, mythical creatures, caves, forests, mountains and unique biomes.
- Implement world-specific traversal and combat such as magic, wings and flight only where designed; keep balance, stamina, collision, camera and mobile controls coherent.
- Create original creatures with AI states, animation, habitats, combat behaviors, drops and encounter rules.
- Add dungeons, raids, bosses, guilds, crafting, equipment, abilities, healing and persistent injury consequences.
- Build explorable interiors, NPC societies and distinct visual/audio identity.

**Acceptance:** playable region/quest/combat loops, creature AI tests, animation/import review and mobile performance checks.

## Phase 8 — Greed Island (independent fourth world)

- Preserve Greed Island as a distinct floating-island world reached only through its star gate in Baghdad.
- Implement its seasonal access schedule and gameplay-earned tickets; do not make access subscription-only.
- Build original island geography, biomes, settlements, card system, collection, crafting, secrets, puzzles, challenges, monsters, guild activities and high-tier rewards.
- Ensure card acquisition/use, inventory, progression, trading and event rules are clear and persistent. Prevent duplication/exploit abuse in shared play.
- Keep unique island lore, art direction, audio and mechanics; do not turn it into a small side area of the Fantasy world.

**Acceptance:** complete enter/exit flow, seasonal/ticket logic, card persistence, puzzle/challenge loops and multiplayer integrity tests where supported.

## Phase 9 — Shared combat, gates, dungeons, abilities and progression

- Reconcile existing combat, ability, player stats, equipment, damage, status effects, loot, XP and save systems before adding replacements.
- Implement modern-world monster gates in eligible cities; inter-world star gates remain only in Baghdad.
- Add fixed and dynamic gates, dungeon layouts, difficulty tiers, bosses, raids, drops, elixirs and gate currency.
- Keep injuries persistent after combat/death according to severity and require a real hospital/healer visit and treatment time; do not auto-heal.
- Complete the optional Hunter Examination as seven playable stages and keep it distinct from the optional 100-floor Power Tower challenge. Implement actual environments, puzzles, NPC candidates, encounters, fair retry rules and license records.
- Add player-specific abilities, ranks, guilds and optional tests without forcing a single playstyle.

**Acceptance:** end-to-end combat/gate/dungeon/exam/tower playtests, persistence, balance, anti-cheat boundaries and mobile controls.

## Phase 10 — Characters, NPC visuals, animation and audio

- Audit existing humanoid GLB models and the character runtime loader before generating duplicates.
- Build original, diverse character bodies, faces, ages, proportions, skin/material variation, hair, clothing, armor and world-specific outfits; avoid stereotyped or sensitive-trait inference.
- Add production-quality rigs, locomotion, idle, interaction, facial expressions, combat, injury, swimming, climbing, riding, emotes and lip-sync where supported.
- Add creature and wildlife rigs/animations.
- Create original ambient, UI, cinematic and world audio. Respect licensing; do not use unlicensed game music.
- Keep source project files, deterministic generation scripts, GLB exports, metadata, licences and asset register entries.

**Acceptance:** GLB validation, Godot import, visual/animation review, scale/rig checks, LOD and Android memory review.

## Phase 11 — Online, accounts, social and secure persistence

- Preserve existing Firebase/Auth and Android account flows. Audit the current Android-to-Godot bridge before claiming it is live.
- Design secure identity mapping, cloud save, conflict resolution, authoritative progression, inventory, property, vehicles, economy, rewards and multiplayer ownership.
- Add friends, unified chat, global chat, teams/clans, roles, notifications, guilds, hunter association and mission boards as connected features.
- Add server-authoritative validation for competitive records, Hunter exams, Power Tower rankings, rare rewards, trading and any shared economy.
- Add privacy, moderation, rate limits, abuse reporting, anti-cheat and data minimization. Do not store secrets in client code.
- Do not introduce real-money incentives, payouts, subscriptions or paid services without explicit approval and secure legal/technical design.

**Acceptance:** authenticated end-to-end flows, security review, offline/reconnect tests, synchronization tests and no exposed credentials.

## Phase 12 — Player experience, UI, controls and cinematic presentation

- Reconcile existing UI before replacing it. Keep touch controls usable on phones and add keyboard/controller mappings for future platforms.
- Complete character creation/customization, third-person default and optional first-person camera, accessibility, map, inventory, missions, guild, chat, profile, settings and save feedback.
- Preserve SYSTEM's original identity and the helper character Mayar. Add onboarding/tutorial and contextual help.
- Build original cinematic intro, world arrival, transitions, quest presentation, environmental storytelling and sound/animation feedback.
- Support Arabic-first UI and robust localization layout; avoid clipped text on narrow mobile screens.

**Acceptance:** full-screen and narrow-screen UI checks, touch navigation, accessibility review, localization review and complete user journeys.

## Phase 13 — Android integration, optimization and release readiness

- Audit the Compose Android app, Godot project/export, AAR/host integration, message router and Firebase bridge. Do not claim Godot is embedded or connected unless a real end-to-end test proves it.
- Preserve the existing app identity and data. Verify install/upgrade behavior, account linking, save migration and no progression reset.
- Add quality tiers, dynamic resolution where supported, LOD, culling, texture compression, pooling, streaming, audio budgets and memory/thermal controls.
- Test low-, mid- and high-tier Android configurations when devices are available; use automated CI evidence where physical devices are not available and label it accurately.
- Keep PC/PlayStation readiness architectural only until actual platform builds and certification checks are performed.

**Acceptance:** clean import, parser, scene startup, gameplay tests, Android APK/AAB export, install/upgrade/account persistence, crash-free test session and documented performance metrics.

## Phase 14 — Final audit and release gate

- Update `MODERN_WORLD_COMPLETION_TRACKER.md`, world-specific trackers, roadmap and asset register with evidence-based statuses.
- Run parser/import, scene startup, automated tests, data validation, asset validation, Android build and available device tests.
- Inspect all diffs for accidental deletion, stale paths, duplicate systems, secrets, licence issues and documentation drift.
- Create a concise final report with exact commits, changed files, tests run, build artifacts, device checks, remaining blockers and what is not finished.
- Never mark the entire game complete while any required gameplay or release gate remains open.

## Execution protocol for this queue

For every phase:
1. Inspect current code and dependencies; fetch latest file contents before editing.
2. Write a small implementation plan, then implement the highest-value safe slice immediately.
3. Add/modify code, scenes, tools and real assets—not documentation alone—when the environment supports it.
4. Run relevant checks; capture workflow IDs/artifact IDs or exact local command outputs.
5. Update trackers and asset register; commit the coherent increment.
6. Continue to the next unblocked phase. Do not ask the user to repeat approved requirements.
7. If blocked by missing tools, credentials, device access, data licence, or an unresolved design conflict, continue with independent safe work and record the exact blocker.
8. Do not merge unrelated branches or PRs automatically. Review their diffs and integration risks first.

**Immediate next task:** resume Phase 1 from the current entrance-enabled Baghdad baseline: spatially associate the 188 source entrance points with building footprints, produce confidence/rejection reporting, then implement only verified entrance-door-interior paths. Do not restart OSM extraction or claim every building is enterable.


## Cross-world feature requirement — advertising, event champions and Hunter Examination

Read and implement `SYSTEM-WORLD/REAL_WORLD_ADVERTISING_AND_CHAMPION_DISPLAY_SYSTEM.md` as part of the modern-world, mission, gate, and Hunter Examination phases. This is a required feature, not an optional note.

- Add architecturally attached digital advertising surfaces to appropriate buildings, skyscrapers, commercial facades, transport hubs, malls, stadiums, and the five Baghdad towers. Protect landmarks, entrances, road signage, Tigris views, Tahrir Square, and the Freedom Monument.
- Distinguish curated fictional campaigns from real commercial ads. Real ads require a compliant approved provider, privacy/consent controls, moderation, opt-out, fallback content, and platform/legal review; never claim live ads before integration and tests.
- Add verified champion/result boards for monster gates, missions, Power Tower events, and Hunter Examination stages/finals. Use authoritative server records, privacy-safe display names, anti-cheat, and separate provisional from final standings.
- The Hunter Examination must publish stage qualifiers, finalists, and the verified overall winner in the Hunter Association Hall of Honor and selected public displays. Do not expose puzzle solutions or private player data.
- Ads must not grant gameplay power, progression, competitive advantage, or exclusive ranking rewards.
