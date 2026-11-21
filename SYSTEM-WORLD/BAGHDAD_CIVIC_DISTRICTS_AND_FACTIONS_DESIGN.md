# Baghdad Civic Districts, Rare Antiquities Bazaar and Factions

Status: implementation specification paired with the first procedural venue pass.
Target branch: `feature/baghdad-streaming-lifecycle`.

## 1. Scope and world rules

This package extends the existing Baghdad and modern-city service layer. It does not replace the five connected Baghdad landmark towers, the independent 200-floor Power Tower, the Hunter Association headquarters, the five-tower sky promenade, or Baghdad's exclusive role as the inter-world Star Gate hub.

The five connected towers remain:
- Hunter Association Tower and its headquarters / exam facilities.
- Business Tower.
- Shopping Tower.
- Entertainment Tower.
- Technology Tower.

Power Tower remains a separate challenge venue and is never counted as one of those five.

## 2. Civic and faith venues

Every generated modern city can register civic worship destinations, while the currently active city receives the visible procedural blockout:
- Mosque: central dome, four minaret forms, balconies, public entrance and a respectful visit prompt.
- Church: nave roof, paired bell towers, spires, public entrance and a respectful visit prompt.
- History museum: columned entrance portico and a discoverable museum service marker.

These are neutral public places. No worship activity is forced on the player, and no religious identity or belief is assigned to the player or NPCs. City-specific architectural styles, denominations, interior layouts, cultural calendars and authored historical exhibits remain content-production tasks.

## 3. Rare Antiquities Bazaar

The Rare Antiquities Bazaar is an original SYSTEM venue. Its broad inspiration is the high-stakes collectible / card-market atmosphere of Hunter x Hunter's Greed Island and auction culture, without reproducing names, characters, cards, scenes, dialogue or exact mechanics.

Initial physical pass:
- Two market lanes.
- Ten individually named vendor stalls.
- Counter, canopy and display relic placeholders per stall.
- Discoverable commerce destination with its own map/service identity.

Planned playable loop:
1. Browse vendor catalogues and inspect provenance records.
2. Compare condition, rarity, authenticity confidence and historical period.
3. Negotiate with licensed dealers or consign an owned collectible.
4. Enter scheduled NPC-run auctions with transparent starting prices and bid increments.
5. Complete appraisal commissions for museums, collectors and guild researchers.
6. Discover occasional travelling dealers and sealed-lot events.
7. Keep a permanent ownership / transaction ledger to deter duplication and fraud.

Economy safeguards:
- Use SYSTEM's earned in-world currency only.
- No real-money wagering, cash-out or pay-to-win auction advantage.
- High-value items require provenance and authenticity checks.
- Stolen artifacts trigger a recoverable investigation and reputation consequence.
- NPC bids must respect budgets and cannot create unlimited currency.

## 4. City factions and gangs

Gangs are fictional NPC organizations with original identities and local territory stories. They are not glorified and do not target real-world groups or communities.

Proposed faction roles:
- Street crews: low-level territory disputes, intimidation and vehicle theft.
- Smuggling rings: contraband transport and hidden supply routes.
- Black-market brokers: fenced goods, forged documents and illicit auctions.
- Protection rackets: extortion cases that can be reported and investigated.
- Independent fixers: information, negotiation and recovery contracts.

Core systems:
- Each faction has an ID, public alias, leadership, members, home district, influence, heat, resources and rival/neutral/ally relationships.
- Territory influence changes through authored events and simulated NPC activity; it must not overwrite real-world map geography.
- Player choices can investigate, negotiate, expose, evade, report, or undertake lawful recovery work.
- Police response uses evidence, witnesses, case status and jurisdiction; it must not instantly know the player's location without a valid report.
- Civilians can report danger, seek shelter and remember faction incidents.
- Faction reputation is separate from general city reputation and hunter rank.
- Arrest, fines, evidence seizure and jail time follow the existing law / crime response rules.
- No gang faction is allowed to control hospitals, worship venues, schools or child-safe spaces.

Multiplayer authority, anti-cheat, online faction persistence, full combat AI and server-side economy are required before online faction wars or shared territory ownership can be enabled.

## 5. Other Baghdad venues and progression dependencies

- Five-tower district: finish interiors, vertical access, shops, public services, safety and wayfinding.
- Hunter exam tunnel: preserve the existing tunnel and public announcement board; connect it to the seven-stage Hunter Examination manager in sequence, with a real reset/retry lifecycle and permanent license after passing.
- Power Tower: retain 200 floors, ten 20-floor regions, twenty boss milestones, three checkpoints per floor and its separate arena. The visible tower's 200 floor bands are a landmark representation, not 200 finished explorable floors.
- Football stadium: retain the open 150 x 116 venue blockout; finish ball physics, teams, rules, referee logic, match UI, substitutions, tournaments and spectator behavior.
- Motorsport: retain the Baghdad track and race-control venue; finish vehicle handling, AI opponents, lap validation, pit logic, race UI and results persistence.
- Advertising: retain local rotating demo campaigns and map pins; a live advertiser marketplace requires moderation, server contracts, consent, billing and ad-network integration.
- Mosques, churches and museums: add authored interiors, accessible paths, local architectural references and NPC schedules after the city blockout pass.

## 6. Acceptance gates

A feature is not marked complete merely because a building mesh or manager script exists.

1. Static validation: scripts parse in the project's pinned Godot version.
2. Runtime validation: destination is instantiated, collision and interaction work, map identity is registered, and save/load is stable.
3. Gameplay validation: the player can complete the advertised loop from start to reward / exit.
4. Android validation: performance, touch controls, memory and visual quality are checked on target hardware.
5. Online validation: authority, persistence, moderation and anti-cheat are verified before multiplayer claims.

Current status of this document's paired venue pass: procedural mosque/church/museum/rare-bazaar exteriors and destination records are being added; interiors, transactions, auctions, faction AI and online persistence are not complete.
