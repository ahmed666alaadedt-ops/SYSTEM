# SYSTEM WORLD — City Advertising and Public Campaign Network

## Purpose

Create one consistent advertising network for the modern world. A campaign shown on a physical street display is represented by a matching advertisement marker on the world map. The street display, map entry, and interaction detail must resolve to the same board and current campaign.

## Current implementation in this branch

- A dedicated `SYSTEMCityAdvertisingManager` creates three procedural street display boards in every generated modern-world city.
- Each board has a visible frame, two supports, illuminated display surface, Arabic campaign text, and an interaction area.
- The current campaign set rotates on a timed schedule. Boards use deterministic city/board offsets so every display does not show the same campaign at the same time.
- Campaign details include category, title, body, suggested destination/action, and expiry timestamp.
- Interacting with a street board shows the current campaign details in the in-world interaction prompt.
- Every board is registered in the world-map advertisement collection, independent of ordinary discovered-location markers.
- The map draws a distinct pink diamond marker for each advertisement and lists its city, campaign title, and category.
- The map can show campaign details and, for Baghdad boards, request a route through the existing Baghdad road-navigation service.
- The map manager updates campaign details only when a campaign changes, avoiding needless map refreshes.
- Existing city media towers and Baghdad tower advertising panels remain separate architectural displays. Public event/champion boards continue to show local gameplay results.

## Current demo campaign categories

1. Hunter Association tests and registration.
2. City commerce and shopping.
3. Power Tower challenges.
4. Football and stadium activities.
5. Motorsport events.
6. Seasonal city festivals.

These are locally authored demo campaigns. No advertiser account, payment, external ad network, or server-delivered commercial campaign is connected yet.

## Required production behavior

### Physical placement
- Street-facing digital billboards at major roads, intersections, transit hubs, shopping streets, stadium approaches, and civic plazas.
- Smaller static posters and notice boards for local shops, guilds, public services, and community events.
- Building facade displays and large city-center screens, with city-specific architectural styling.
- Keep walkways, traffic sightlines, building entrances, and accessibility routes unobstructed.
- Avoid placing a board in water, inside buildings, across roads, or in restricted/private property.

### Map behavior
- Give each physical display one stable advertisement ID shared by its world object and map marker.
- Distinguish advertisement markers from services, discovered landmarks, gates, missions, and player-created markers.
- Show the current campaign title/category and expiry; expired campaigns must be hidden or marked expired.
- Let the player open campaign details from the map. Baghdad map entries may request a route only when the road graph can produce a valid path.
- Filters should eventually support all ads, events, commerce, guilds, sport, transport, and public notices.
- Do not reveal undiscovered private locations through advertising markers.

### Campaign lifecycle
- Draft → review/moderation → scheduled → active → expired/paused/removed.
- Each campaign needs a unique ID, advertiser/owner, city/region targeting, start/end time, display priority, language, category, content, and destination.
- Enforce per-board rotation fairness and frequency caps; prevent one campaign from monopolizing all screens.
- Cache campaign data locally and handle offline mode without blocking world startup.
- Use server-authoritative time and campaign state for online play; local system time is only a prototype fallback.
- Record impressions and interactions only with appropriate privacy controls and without collecting unnecessary personal data.

### Safety, quality, and economy
- Review text and images for scams, impersonation, harassment, illegal goods, and age-inappropriate content.
- Provide report/hide controls and a way to mute categories.
- Keep gameplay-critical directions, emergency notices, and system alerts visually separate from commercial advertising.
- Never let paid ads grant combat power, progression, exclusive map access, or unfair gameplay advantages.
- Any future paid advertiser marketplace needs transparent pricing, moderation, billing, fraud prevention, and server-side authorization.
- Add accessibility options: readable contrast, large text, reduced animation, language selection, and audio-free operation.
- Use LOD, shared materials, batched geometry, and a capped number of visible animated displays for Android performance.

## Not yet complete

- Final high-quality billboard models, animated video/material playback, weather/night adaptation, and per-city art direction.
- In-world campaign management terminal and authorized advertiser tools.
- Backend synchronization, account permissions, moderation queue, billing, reporting, analytics, and anti-fraud controls.
- Direct map-pin touch selection and full map filter/search controls.
- Campaign scheduling from a real calendar/event service.
- Physical Android tests for readability, draw calls, thermal load, and touch interaction.
- Campaigns for historical, mythic/fantasy, and Greed Island worlds; this first implementation is for the modern-world city network only.

## Validation boundary

Godot parser/headless CI can validate scripts and scene startup. It cannot prove that street displays are visually placed correctly in every generated city, that touch/map controls feel right on a phone, or that a real online ad marketplace is operational. Those require in-game and device testing.
