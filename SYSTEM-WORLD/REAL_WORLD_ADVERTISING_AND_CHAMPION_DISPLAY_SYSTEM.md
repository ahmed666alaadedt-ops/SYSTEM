# SYSTEM WORLD — Real-World Advertising & Champion Display System

Status: approved design. The six Baghdad towers have NPC-staff-managed internal and external physical campaign screens with six stable campaign IDs and a 38-second local rotation. Each display records campaign ID, responsible NPC manager, start time, expiry time and rotation. Local campaign controls support scheduled starts, expiry, revocation and a safe curated fallback; the Baghdad tower operations validator exercises the lifecycle. Hunter Tower exterior facade screens and local Power Tower match-result displays also exist. This remains a curated/local simulation: no live advertising provider or authoritative cross-world champion service is claimed.

## 1. Purpose and visual direction

Make the modern world feel like a living global city by placing believable digital advertising media on suitable real-world-style buildings, commercial streets, transport hubs, malls, stadiums, and the five connected Baghdad towers. Advertising must be part of the architecture and city simulation, not floating UI pasted over the map.

## 2. Physical media in the world

Support these authored placement types:
- Large rooftop billboards and building-mounted LED panels.
- Tall vertical media ribbons on selected skyscraper facades.
- Shopfront and mall display screens.
- Transit displays at airports, rail stations, bus terminals, and harbor passenger areas.
- Stadium perimeter boards and arena scoreboards.
- District landmark screens, including carefully placed displays on the five Baghdad towers.
- Small street-level posters and kiosks where zoning and sightlines permit.

Placement rules:
- Attach media surfaces to building/facade anchors with correct orientation, scale, collision clearance, and LOD.
- Do not cover entrances, windows needed for navigation, road signs, traffic lights, emergency signage, historic monuments, or protected sightlines.
- In Baghdad, preserve the Tigris channel and riverfront, Tahrir Square, the Freedom Monument, and the Karkh/Rusafa skyline. Do not place screens where they obstruct the river or protected landmarks.
- Use city/district visual styles, local language support, culturally appropriate creative, and day/night brightness limits.
- Distant screens use low-cost emissive materials; only nearby important screens may animate at full detail. Avoid one realtime light per screen.

## 3. Real advertising versus simulated advertising

The game may support both:
1. Curated in-world fictional campaigns for world-building and testing.
2. Real paid campaigns delivered only through a future approved advertising provider or a publisher-controlled campaign service.

A billboard mesh displaying sample content is not a live advertising integration. Do not claim real ads are active until provider approval, SDK/backend integration, policy review, consent handling, and device tests are complete.

Real-ad safeguards:
- Never expose player identity, precise location, private chat, health, or sensitive profile data to advertisers.
- Use contextual placement (city, district, venue, screen category) by default; do not infer sensitive traits.
- Respect age ratings, regional law, platform policies, consent and opt-out requirements.
- Filter prohibited, deceptive, political, adult, gambling, weapon, nicotine, alcohol, and other restricted categories according to applicable law and platform policy.
- Validate creative assets server-side, limit file sizes and animation rates, and provide a report/hide mechanism.
- Keep ad delivery separate from gameplay authority. Ads must never grant combat power, XP, rare items, ranking advantages, or paid access to competitive outcomes.
- Provide a fallback curated campaign when the provider is unavailable; never leave broken external URLs or blank flashing panels.
- Cache approved creatives with expiry and revoke support. Record campaign ID, placement ID, region, impression event, and policy status without collecting unnecessary personal data.
- Provide accessibility-safe brightness, reduced motion, and quiet-mode options.

## 4. Champion, mission, and gate result displays

Create a separate verified-results presentation layer that can appear on:
- The Hunter Association Tower Hall of Honor and public display walls.
- Power Tower arena screens.
- City public screens and selected skyscraper panels.
- Monster-gate perimeter briefing boards and post-clear result screens.
- Mission boards and guild halls.
- The Hunter Examination venue, including stage completion boards and final champion display.

Display categories:
- Current event leaders and completed-event winners.
- Monster-gate clear teams, fastest verified clear times, and contribution awards.
- Mission completion records and seasonal challenge winners.
- Hunter Examination stage qualifiers, finalists, and licensed graduates/champions.
- Historical champions archive, separated from current live rankings.

Fairness and verification:
- Only publish results confirmed by the authoritative game service; local client claims are not enough.
- Separate solo, party, level bracket, difficulty, and event categories.
- Record event season, ruleset, completion time, team roster, and verified result ID.
- Prevent duplicate rewards, spoofed times, replay exploits, and altered client submissions.
- Show player-chosen display names only; allow privacy controls, hide-from-public-board options, and moderation/reporting.
- Do not reveal real names, account identifiers, exact locations, or private player data.
- Clearly label provisional live standings versus final verified winners.
- Never advertise an unverified player as a champion.

## 5. Monster-gate and mission presentation

At a discovered gate, the exterior board may show gate class, public danger rating, party requirements, entry status, event timer, and the last verified clear record. It must not reveal hidden dungeon layouts, puzzle answers, unrevealed boss mechanics, or another team's private information.

After a clear, show a result ceremony/summary with verified participants, contribution roles, time, rank, rewards granted, and a link to the public event archive. Mission boards use the same verified result service, with separate filters for daily, weekly, guild, regional, and seasonal missions.

## 6. Hunter Examination presentation

The examination is a multi-stage, skill-based quest chain. Each stage has its own:
- Briefing board and rules.
- Start/end state and timer where relevant.
- Checkpoint/qualification record.
- Fair scoring criteria and anti-cheat validation.
- Public stage leaderboard that does not expose puzzle solutions.
- Final results ceremony and Hall of Honor archive.

Only candidates who pass all required stages under the active ruleset receive the examination completion credential. The final board distinguishes qualifiers, finalists, and the verified winner; it must not imply that a display placement alone grants a license.

## 7. Runtime architecture

Recommended separation:
- `world_media_anchor`: scene-level anchor metadata for building-mounted screens.
- `advertising_campaign_service`: approved campaign metadata and creative delivery; provider adapter remains optional.
- `media_surface_renderer`: pooled materials/textures, distance LOD, update throttling, and brightness controls.
- `verified_event_results_service`: authoritative result records for gates, missions, arenas, and examinations.
- `public_champion_board`: safe display-name projection with privacy filtering.
- `event_archive`: season-scoped historical results and audit references.

All screen updates should be event-driven and throttled. Do not poll every billboard every frame. Reuse materials and textures, cap simultaneous animated surfaces, and stream only nearby high-resolution creatives.

## 8. Acceptance checklist

- [ ] Define building/facade anchor schema and authoring workflow.
- [x] Add physical emissive campaign screens and labels to the six Baghdad towers; add curated Hunter Tower exterior facade screens.
- [ ] Verify screen orientation, occlusion, collision clearance, day/night brightness, LOD, and Android performance.
- [x] Add an NPC-staff-managed curated local campaign rotation across the six Baghdad towers (six messages, 38-second rotation).
- [x] Add local campaign start/end timestamps, expiry/revocation handling, and a safe curated fallback when a campaign is withdrawn.
- [ ] Implement approved provider integration only after legal, platform, consent, and privacy review.
- [ ] Implement authoritative verified result records for monster gates and missions; current arena/tower result displays are local runtime displays, not a global authoritative service.
- [ ] Implement Hunter Examination stage records, qualifiers, finalists, winner, and Hall of Honor archive.
- [ ] Connect public boards to privacy-filtered display names and moderation.
- [ ] Test anti-cheat, duplicate submissions, disconnect/reconnect, and season rollover.
- [ ] Verify that ads do not affect competitive balance or gameplay rewards.
- [ ] Inspect placements in Baghdad without obstructing the Tigris, Tahrir Square, or the Freedom Monument.
- [ ] Run Godot parser, scene, and Android performance tests before marking any feature complete.

## 9. Non-claims

The curated tower campaign screens, 38-second local rotation, NPC manager attribution, local start/expiry/revocation controls, safe fallback, Hunter exterior facade panels, and local Power Tower match-result presentation are implemented as in-world simulations. This does not mean live commercial ads or remote provider delivery, public global champion leaderboards, monster-gate boards, or the complete Hunter Examination display system are connected to a production backend.
