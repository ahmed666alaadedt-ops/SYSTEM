# Baghdad Antiques & Heritage Tower — Approved Design

Status: approved design; authenticated marketplace server foundation, scheduled expiry/settlement jobs, native Android/Godot host wiring and emulator security/concurrency tests are implemented on the feature branch. The 25 November 2026 emulator run passed 7 Firestore rules tests and 8 marketplace transaction tests. It is NOT live until trusted reward issuance, production wallet funding, deployment/monitoring and physical-device round-trip verification are complete.

## District identity

The Baghdad five-tower district consists of:
1. Hunter Association Tower
2. Business & Investment Tower
3. Shopping & Commerce Tower
4. Antiques & Heritage Tower (replaces Entertainment & Sports Tower)
5. Technology & Innovation Tower

The Power Tower remains a separate landmark outside the five-tower count. Its combat competitions remain strictly individual 1v1; no team combat is introduced.

## سوق البتاوين للتحف والآثار (Al-Bataween Street Antiques Market) — primary player trading hub

The district display name is **سوق البتاوين** and its category/descriptor is **سوق التحف والآثار**; always show the complete combined identity **سوق البتاوين للتحف والآثار** on maps, entrance signage, interaction prompts and marketplace screens. The outdoor Al-Bataween market is a separate ground-level Baghdad neighborhood destination, not a sixth tower and not a replacement for the 34-floor Antiques & Heritage museum. Its neighborhood-center WGS84 anchor is 33.3201, 44.4205 (a neighborhood reference point, not a surveyed parcel boundary). The playable terrain is extended to this anchor and connected to the Republic Bridge approach by a clearly identified procedural access corridor; that corridor is gameplay infrastructure, not surveyed OpenStreetMap road geometry.

- Generate a walkable street-market courtyard with 24 individually identified stalls and a main entrance interaction.
- Organize stalls around Iraqi heritage, manuscripts, coins, ceramics, metalwork, player listings, appraisal and restoration.
- Every stall routes into the same authoritative player marketplace; do not create a second wallet, local-save trading ledger or duplicate economy.
- The in-world Godot interaction opens the marketplace panel. The existing native Android marketplace tab remains available and uses the same authenticated Firebase callable functions.
- Sellers list only artifacts they own and choose their fixed price. Buyers browse active offers and purchase with virtual SYSTEM currency.
- Listing escrow, balance debit, seller credit, ownership transfer and transaction receipt remain one server-side atomic transaction. Concurrent purchase attempts must still have exactly one winner.
- This district is a playable procedural first pass; it is not a claim that the surrounding Al-Bataween streets or every building have been reconstructed from OSM.

The existing 34-floor Antiques & Heritage Tower remains the museum, research, restoration and private-gallery venue. Its marketplace and auction floors may act as dealer galleries and auction rooms, but must reuse this same backend and transaction ledger.

## Antiques & Heritage Tower

A 34-floor public museum, collecting, restoration and player-commerce destination. Keep the existing Baghdad plot and the five-tower district connection unless a terrain validation requires a safe adjustment.

Proposed floor plan:
- 01–04: Iraqi heritage — Sumerian, Akkadian, Babylonian and Assyrian collections
- 05–08: Ancient Egypt and Nile civilizations
- 09–12: Greek, Roman and Hellenistic collections
- 13–16: Ancient China and Silk Road collections
- 17–20: Archaeology research, provenance archives and discovery exhibits
- 21–24: Conservation and restoration laboratories; condition assessment and expert appraisal
- 25–28: Player-owned galleries and private collection display rooms
- 29–32: Player marketplace, verified dealer stalls and live auction halls
- 33–34: Curator council, rare-artifact vault and rotating international exhibitions

Every exhibit and market object must have a stable artifact ID, display metadata, a physical 3D exhibit, an interaction Area3D and tower/floor ownership metadata. NPC curators, archaeologists, restorers, guards, auctioneers, vendors and visitors populate the public spaces.

## سوق التحف والآثار الغامضة — relic-bound historical quests

- A sealed Babylonian star tablet is displayed at a dedicated in-world altar in the mysterious antiques market. It is separate from ordinary player listings and cannot be bought as a normal stock item.
- Interacting with the tablet launches the Historical & Civilizations world and starts the first relic quest, **أصداء بابل**.
- The first quest requires the player to decode the Star → River → Crown inscriptions in order, then recover the Babylonian Star Tablet from its sanctum. Incorrect order is rejected without advancing progress.
- Completion unlocks a rare skill training permit for **عين صدى الأثر** (`relic_echo_sight`). The player must complete three distinct skill-practice sessions before the skill is learned; the skill is registered in the existing progression tree and save data.
- The relic skill is intentionally rare and tied to its source artifact and historical quest, not sold as a routine shop skill. Additional relics may later open their own historical missions and distinct rare skills.
- A return gate becomes usable after quest completion and returns the player to the market location.
- Current scope is a procedural first historical quest and one relic skill unlock path. The rare skill's full in-world detection/ability effect, additional historical campaigns, multiplayer quest-state persistence, and server-authoritative reward issuance remain future integration work; local progression is not proof of online reward security.

## Player-to-player artifact economy

The marketplace is for direct trading between authenticated SYSTEM WORLD players, not merely NPC shop purchases:
- A seller lists an artifact they actually own and chooses a fixed price, or opens an auction.
- A buyer purchases a listing; the server atomically transfers the artifact and credits the seller.
- Auctions support a deadline, minimum bid, bid history and automatic settlement.
- Direct exchange supports two-sided offers and explicit acceptance by both players.
- A player can cancel only their own active listing, and cannot list an artifact already in escrow.
- Ownership history, seller/buyer IDs, transaction IDs, timestamps, fees and final prices are recorded.
- Unique artifacts have globally unique IDs and cannot be duplicated by client requests.
- Rarity, civilization, authenticity, condition, restoration history and provenance affect display and valuation.
- A private gallery lets a player exhibit owned artifacts without listing them for sale.

## Implemented server foundation — feature branch

File: `functions/src/artifact_marketplace.ts`

Callable endpoints currently added:
- `getMyMarketplaceWallet`: creates a zero-balance SYSTEM wallet; it never accepts client balance changes.
- `listMyMarketplaceArtifacts`: returns only the caller's server-owned artifacts.
- `grantMarketplaceArtifact`: moderator-only trusted issuance endpoint; normal players cannot mint items.
- `grantMarketplaceArtifactFromReward`: replay-safe artifact issuance restricted to the trusted game-server custom claim; repeated quest events cannot mint duplicates.
- `browseArtifactMarketplace`: lists active fixed-price offers for authenticated players.
- `createArtifactListing`: verifies ownership and moves the artifact into escrow before creating the offer.
- `cancelArtifactListing`: only the seller can cancel their active offer and release escrow.
- `purchaseArtifactListing`: atomically debits the buyer, credits the seller, transfers ownership, closes the offer and writes transaction/audit records.
- `expireArtifactListing`: safely releases escrow for expired offers without letting another player cancel a live offer.
- `listMyMarketplaceTransactions`: returns the player's private purchase/sale history.
- `createArtifactAuction`, `browseArtifactAuctions`, `placeArtifactAuctionBid`, `listArtifactAuctionBids`, `settleExpiredArtifactAuction`, `settleExpiredArtifactAuctions`, `cancelArtifactAuction`: player auctions with reserved bid funds, bid history, anti-sniping extension, and atomic settlement after expiry. A scheduled sweep runs every 5 minutes and reuses the same transactional settlement path.
- `createArtifactExchangeOffer`, `acceptArtifactExchangeOffer`, `closeArtifactExchangeOffer`, `releaseExpiredArtifactExchangeOffers`, `listMyArtifactExchangeOffers`: two-sided artifact offers with escrow, explicit recipient acceptance, and atomic transfer of both artifacts. A scheduled sweep runs every 15 minutes and releases expired offers from escrow.

Authoritative collections:
- `artifactRegistry/{artifactId}`: global unique-ID registry.
- `artifactOwnership/{uid}/items/{artifactId}`: server-owned artifact records.
- `systemWallets/{uid}`: server-controlled virtual SYSTEM currency balance and reserved auction funds.
- `marketplaceListings/{listingId}`: public active listing metadata; all writes are server-side.
- `marketplaceTransactions/{transactionId}`: participant-readable transaction receipts.
- `marketplaceAuctions/{auctionId}/bids/{bidId}`: immutable auction bid history.
- `marketplaceExchanges/{exchangeId}`: private two-player exchange offers.
- `artifactHistory/{artifactId}/events/{eventId}`: private append-only ownership timeline.
- `marketplaceCurrencyAwards/{awardId}`: replay-safe virtual currency rewards from the trusted game-server identity.
- `marketplaceAudit/{recordId}`, `artifactOwnershipAudit/{artifactId}`: private audit records.

The marketplace fee is currently 0 basis points; no fee is silently deducted. Currency is virtual SYSTEM currency only. No cash withdrawal, external payment or real-money trading is part of this feature.

Firestore rules deny client writes to wallets, ownership, listings, transactions, registry and audit collections. Marketplace state changes must go through authenticated callable Cloud Functions.

## Client integration status

An Android Firebase callable repository has been added at:
`app/src/main/java/com/system/irtqaa/FirebaseArtifactMarketplaceRepository.kt`

It exposes wallet and reserved-balance loading, owned artifact loading, fixed-price listing browse/create/purchase/cancel/expiry, auction browse/create/bid/history/settlement/cancellation, exchange inbox/create/accept/close, and private trade history. The native Android app now includes `SystemAntiquesMarketplaceScreen.kt` as a dedicated `برج التحف والآثار` tab with player-to-player listings, purchase/cancellation, auctions, bids, two-player exchanges, collection display and private transaction history. The versioned marketplace request/response protocol is present in `system_android_bridge.gd` and `SystemGodotMessageContract.kt`; `SystemMarketplaceGodotBridgeHandler.kt` dispatches market operations to Firebase and correlates replies by request ID. The Godot market-floor exhibit now exposes wallet, listing browse, auction browse and owned-artifact actions through the versioned bridge request API, including purchase, fixed-price listing creation and bid controls when matching responses arrive. The native Android Godot host is now present: `SystemGodotActivity` hosts `SystemGodotFragment`, and `SystemAndroidHostPlugin` registers the `SYSTEMAndroidHost` singleton expected by `system_android_bridge.gd`. The fragment loads the canonical Godot 4.3 PCK, and the plugin forwards allowlisted marketplace requests to the authenticated Firebase repository while preserving request IDs. On `bridge_ready`, Android sends the current Firebase UID and display name as explicitly untrusted display context; the UID is obtained from FirebaseAuth, never accepted from a Godot payload. The native Android app-shell build and canonical Godot APK export passed CI on the current feature branch. A physical-device round trip, live Firebase deployment and trusted reward issuance are still required before calling the online player market live. Existing local Godot wallet and inventory data are not authoritative and must never be copied into server wallets without a trusted migration/reward source.

A Firebase Functions TypeScript validation workflow has been added. The scheduled expiry and auction settlement exports are wired through `functions/src/index.ts`; Firestore composite indexes cover listing expiry (`status` + `expiresAt`), exchange expiry (`status` + `expiresAt`) and auction settlement (`status` + `endsAt`). The latest branch CI TypeScript build and Firestore emulator rules compilation passed. These checks do not deploy functions or execute the scheduled jobs against live data.

## Remaining activation gates

1. Connect verified quest rewards in the actual game-server runtime to `grantMarketplaceArtifactFromReward`; the secure endpoint exists, but the gameplay reward event source is not wired yet.
2. Configure the trusted game-server Firebase custom claim and connect verified quest/dungeon rewards to `awardMarketplaceCurrency`; ordinary players cannot mint currency.
3. Deploy and monitor the scheduled marketplace jobs: auction settlement every 5 minutes, and listing/exchange escrow expiry every 15 minutes. The scheduler code and expiry indexes are present; production activation still requires deployment.
4. Complete a physical-device round trip for login, Godot launch, market browse/list/purchase/auction/exchange, network loss and request retry through the native host plugin.
5. [COMPLETED 25 NOV 2026] Callable-function emulator coverage passed for authentication, self-purchase, insufficient funds, atomic settlement, concurrent purchases, auctions, exchanges, trusted reward replay protection and scheduled expiry workers (8/8 transaction tests).
6. [COMPLETED 25 NOV 2026] Firestore rules and marketplace integration tests passed against the Firebase Emulator (7/7 security-rule tests and 8/8 transaction tests).
7. Deploy Cloud Functions, Firestore rules and indexes only after user approval and successful tests.

## Security and technical requirements

- All online listings, bids, purchases, escrow, wallet changes and ownership transfers must be server-authoritative through authenticated Firebase Cloud Functions and Firestore transactions.
- Never trust client-supplied prices, seller IDs, buyer IDs, wallet balances, ownership claims or artifact rarity.
- Prevent self-purchase, duplicate settlement, stale bids, double-spending, replayed requests and simultaneous purchase races.
- Keep marketplace data separate from public player profile fields. Firestore client rules must deny direct writes to authoritative market, escrow, wallet and ownership records.
- Public fixed-price and auction browse responses expose only the seller's chosen display name and a server-derived `isSeller` boolean; bid history exposes bidder display names only. Personal trade history returns an `isBuyer` flag, and exchange inboxes return the counterparty display name. Never return seller, buyer, bidder, initiator or recipient Firebase UIDs in client-facing marketplace projections.
- Firestore rules deny direct client reads of listing, auction/bid, exchange and transaction backing documents. The Android and Godot clients must use authenticated callable functions, which return filtered projections rather than raw internal records.
- A transaction must atomically verify seller ownership, lock the artifact in escrow, debit the buyer, credit the seller, transfer ownership and close the listing.
- Audit records are append-only and must not expose private email addresses.
- SYSTEM currency is virtual in-game currency only. No real-money trading, cash withdrawal or external payment is part of this feature.

## Existing implementation boundary

The current tower vendor stock, NPC purchases and player wallet in the Godot tower operations manager are local-save prototypes. The Android application already contains Firebase Auth/Firestore repositories, but the Godot progression inventory is not yet synchronized as server-authoritative artifact ownership. Therefore, the player-to-player marketplace must not be described as live or cross-device until the Cloud Functions, inventory ownership synchronization, Android/Godot client bridge and concurrency/security tests all pass.

## Recreation and sports

Do not count the independent Power Tower as one of the five district towers. Sports and leisure activities may be retained in separate public recreation facilities; they must not remain as departments of the Antiques & Heritage Tower. Do not silently delete existing sports gameplay code while relocating it.

## Acceptance tests

1. Exactly five connected district towers are reported; the independent Power Tower remains outside that count.
2. The fourth tower is named and identified as Antiques & Heritage Tower in landmarks, elevator directory, staff, NPC schedules, public displays and interaction routing.
3. All 34 floors generate the correct museum, restoration, private-gallery, market and auction departments.
4. Exhibit items have unique IDs, physical display meshes, interaction areas and correct floor/tower metadata.
5. A player cannot list an artifact they do not own or list one already in escrow.
6. Concurrent purchase attempts result in exactly one successful transfer.
7. Buyer debit, seller credit, escrow release, ownership transfer and audit record are atomic.
8. Auction settlement and two-party exchange are tested against expired, cancelled, replayed and conflicting requests.
9. The existing Hunter Association, Shopping, Business, Technology and standalone Power Tower regressions remain green.
10. No changes are merged into main without the user's separate explicit approval.


## Second historical relic quest — Nineveh Guardians

- The market has a separate sealed Assyrian royal seal altar; it is not a tower and does not replace the Babylon Star Tablet altar.
- The quest travels to the Historical & Civilizations world and requires the clue order: Winged Lion, Tigris tablet, Royal Seal, then recover the Assyrian seal.
- Correct completion grants a training permit for the mythic rare skill `ashur_guardian_aegis` (درع الحارس الآشوري); three verified training sessions are required before use.
- The mobile AEGIS control activates a 12-second defensive barrier after mastery, reducing incoming damage by 65%; cost 35 energy, 60-second cooldown. The player receives a visible amber shield effect.
- The return gate returns the player to the market. This is an initial procedural quest environment, not a final cinematic historical level.


## Cross-world artifact origins, rare skill relics and discovery missions — 27 November 2026

The artifact market is a shared destination for discoveries from two distinct gameplay worlds. It must preserve provenance and never collapse the historical and fantasy sources into one generic loot pool.

### Historical & Civilizations world
- Historical artifacts originate only from civilization-specific expeditions, archaeological sites, sealed sanctums, archive recovery and their linked quests.
- Existing quest anchors remain distinct: Babylon Echoes `babylon_echoes_relic_trial` yields the Babylonian Star Tablet / `relic_echo_sight`; Nineveh Guardians `nineveh_guardians_relic_trial` yields the Assyrian Royal Seal / `ashur_guardian_aegis`.
- Further Sumerian, Akkadian, Egyptian, Greek, Roman and Chinese relic campaigns are planned content, not implemented quests until their world runtime, objectives, persistence and tests exist.

### Fantasy world
- Fantasy gems and crystals originate only from fantasy expeditions, guardian trials, hidden shrines, mana veins and fantasy quest rewards. They must not be mislabeled as historical archaeological finds.
- Initial planned relic families include Dragon Star Crystal, Moon Diamond, Ancient Mana Core, Phoenix Ember Gem and Void Shadow Prism. Each has its own quest/source identity and a distinct skill concept in `data/system_cross_world_relic_catalog.json`.
- Fantasy quest IDs and skill IDs in the catalog marked `planned_quest` are data/design reservations only; they are not claims of implemented or playable quests.

### Rare relic skill ownership and player control
- Only selected Rare, Epic, Mythic and Unique artifacts may carry a skill. Ordinary artifacts and ordinary gemstones do not automatically grant abilities.
- The player must recover the real source relic, complete its linked quest, pass the awakening/training requirement and learn the skill into the existing player progression tree. Once learned, the skill must be equipable and manually activated/controlled through the combat or exploration ability UI, with server-verified unlock provenance.
- A skill-bearing relic is extremely scarce; Unique relic templates may have a one-per-world/storyline issuance cap. The registry must enforce this server-side, not by client-side drop chance.
- Default trade policy: an unawakened relic may be listed if the server confirms ownership and eligibility; after awakening, the skill is bound to the character and the relic cannot be sold or transferred in a way that duplicates, deletes or strips the learned skill. Unique relic transfers require explicit server validation.
- Listing price is selected by the seller, while authenticity, rarity, provenance and uniqueness are server-derived and displayed to buyers. High prices are permitted, but the client cannot forge rarity, source or ownership.

### Scalable artifact catalogue and anti-exploit issuance
- Initial content target: at least 3,000 distinct artifact instances, expandable through data-driven templates, civilization/material/condition/provenance variants and unique server-issued IDs. This is a content target, not a claim that 3,000 playable meshes already exist.
- Keep reusable 3D mesh templates and material variants separate from unique artifact instance records; do not create thousands of unrelated hand-authored meshes.
- Every instance must carry `artifactId`, `templateId`, `sourceWorld`, `civilizationOrRealm`, `sourceQuestOrDiscovery`, `rarity`, `provenance`, `condition`, `marketValueBand`, `skillId` (nullable), `awakeningState`, `ownerId` and `tradePolicy`.
- Only trusted game-server reward/discovery events may issue artifacts through the existing replay-safe reward endpoint. The client may request or display a discovery, but cannot mint an item, choose its rarity, claim a quest completion or assign a skill.
- The registry file is a content seed/schema reference. It does not itself wire world generation, quest runtime, combat effects, Firebase reward issuance or production marketplace deployment.

### Required cross-world acceptance tests
1. Historical quest rewards always record `sourceWorld=historical` and their correct civilization and quest provenance.
2. Fantasy quest rewards always record `sourceWorld=fantasy` and cannot be issued from historical loot tables.
3. A client cannot request a Mythic/Unique relic or skill by sending a forged rarity, template, quest ID or skill ID.
4. A quest reward replay cannot issue a second copy; one-per-world Unique caps are enforced transactionally.
5. Awakening adds the authorized skill to progression once; the skill can be equipped/activated and its effect is tested in combat or exploration.
6. An awakened bound relic cannot be traded to duplicate the skill or remove the skill from its legitimate owner.
7. Market listings show origin, provenance, rarity and trade eligibility without exposing private player identifiers.
8. Existing Babylon Echoes, Nineveh Guardians, artifact marketplace, wallet, auctions and exchanges regressions remain green.


## Supernatural relic abilities — healing, combat, movement, flight and petrification

Relics and fantasy gemstones may grant supernatural abilities, but only selected, provenance-authenticated rare items may do so. Abilities are learned through the existing progression/awakening flow, then equipped and manually activated by the player. A catalog entry is not proof that its quest, skill effect or runtime integration is complete.

### Ability families
- Healing: healing over time, burst recovery, energy restoration and tightly limited emergency recovery. No repeated revival exploit or resurrection after a finalized death state.
- Combat: temporary strength, guard breaking, defensive resistance, elemental attacks and counter barriers. Bonuses have caps and diminishing returns.
- Speed and movement: sprint bursts, dashes, evasions and controlled aerial movement.
- Wings and flight: relics may manifest visible wings on the character or grant temporary flight. Flight has stamina/energy costs, duration and landing control; disable it in restricted interiors, protected quest spaces and selected PvP arenas.
- Petrification and control: rare gaze relics can briefly petrify a valid enemy. The target must have a break/escape rule, resistance and diminishing returns; bosses and players receive appropriate resistance. No indefinite stun, chain-lock or client-side hit confirmation.
- Other utility: stealth, detection, shields and elemental resistance.

### World provenance examples
- Historical world: Sumerian Life Vessel (healing), Babylonian War Standard (combat), Assur Wind Sandals (speed), Horus Sky Wings (flight/wings), and Medusa Obsidian Gaze (petrification). These belong to civilization-specific historical questlines and must be recovered from their associated historical locations.
- Fantasy world: Phoenix Heartstone (healing), Titan Core (combat), Wind Dragon Feather (speed), Sky Seraph Crystal (wings/flight), and Basilisk Eye Gem (petrification). These originate only from fantasy expeditions, guardian encounters, shrines or fantasy quest rewards.
- These examples are registered as planned quest content unless a corresponding playable quest/runtime is explicitly implemented and tested. Never present planned content as already obtainable.

### Combat and security requirements
- The server validates ownership, awakening, learned skill, cooldown, energy cost, range, line of sight, target eligibility, PvP rules and effect duration before accepting an ability use.
- The server owns damage, healing, petrification, movement/flight authorization and effect expiry. Client animations are presentation only.
- Effects cannot stack beyond configured caps; repeated control effects apply diminishing returns and temporary immunity windows.
- Wings must be visible character equipment/animation, not merely a stat flag. Flight must have real movement controller integration, collision handling, stamina and safe landing.
- Petrification must have a readable visual state, a short maximum duration, an escape/break condition, boss/player resistance and server-side anti-chain-lock enforcement.
- Healing must respect max health, combat state and death-state transitions. Strength/speed buffs must not bypass movement, attack-rate or damage caps.

### Acceptance tests before calling these abilities complete
1. Each item can only be issued from its registered world and quest/discovery source; forged client drops are rejected.
2. Awakening and skill unlock are idempotent and persist across relog/device changes.
3. Each learned ability can be equipped and manually activated; cooldown, resource cost and target validation are enforced server-side.
4. Healing, strength, speed, wings/flight and petrification each produce their actual gameplay effect, not only a catalog description or animation.
5. Petrification cannot permanently disable another player or boss; escape, resistance and immunity windows work under latency and simultaneous hits.
6. Flight collision, indoor restrictions, landing and PvP restrictions are tested.
7. Existing historical quests, fantasy world, player progression, artifact market and Android/Godot bridge regression suites pass.


## Four primordial elements — rare quest relics

The rare-relic system includes all four classical elements: **Fire, Air, Water and Earth**. These are special artifact/gem abilities, not ordinary vendor skills or common loot. Players earn them by completing their linked missions, exploration routes or guardian trials in the correct world.

- **Fire — قلب اللهب البدائي** (`primordial_flame_heart`): controlled flame burst and temporary fire resistance; offensive focus.
- **Air — ختم ريح العاصفة** (`stormwind_sigil`): wind blades/gusts and a short aerial dash; mobility focus.
- **Water — لؤلؤة قلب المد** (`tideheart_pearl`): water barrier, cleansing and limited healing wave; defense/support focus.
- **Earth — جيود جذر العالم** (`worldroot_geode`): earth armor, ground spikes and a brief breakable root effect; defense/control focus.

These four are currently **planned quest content** in the catalog, not yet playable or obtainable. They must be awarded only by trusted server-verified quest/discovery completion; ordinary market vendors cannot stock them. Rarity, source world, quest provenance and any Unique issuance cap are server-owned. Awakening binds the learned ability to the player under the existing no-duplication trade policy.

Elemental combinations (Fire+Air, Water+Earth and exceptionally all four) may be introduced only as ultra-rare multi-stage quest rewards. They require completion of every linked trial, have strict energy/cooldown and PvP/boss resistance rules, and cannot be created by combining ordinary market items client-side.

### Elemental acceptance checks
1. Each element drops only from its registered quest/world source; cross-world and forged reward requests are rejected.
2. Fire, Air, Water and Earth each produce a distinct tested gameplay effect after awakening.
3. Elemental resistance, damage, healing and control respect caps, cooldowns, target rules and PvP/boss resistance.
4. Elemental combination rewards require all server-verified prerequisite trials and are issued once only.


## Nen as the primary power — elemental relics as secondary power

Nen is the required foundational power system for every supernatural elemental relic ability. A relic does **not** grant Nen and cannot replace Nen training. It supplies a secondary elemental affinity that the player learns to channel through their own Nen.

### Activation and progression gates
1. The player must unlock Nen through its own training/progression path before any elemental relic skill can activate.
2. The player must own and recover the eligible rare relic from its registered quest/discovery source, then complete its separate awakening trial.
3. The skill becomes usable only when both checks pass: the relic is awakened and the player's Nen mastery meets that skill's minimum threshold.
4. Without Nen, the relic remains dormant: it may be inspected and stored, but its supernatural ability cannot be activated.
5. Beginner Nen permits only weak, short effects with high energy cost and fatigue. Trained Nen enables stable controlled effects. Advanced mastery improves precision and efficiency within strict caps. Expert mastery plus linked trials is required for exceptional multi-element combinations.
6. The server validates Nen unlock, mastery tier, relic ownership, awakening, learned skill, energy, cooldown, target and effect. The client cannot assert its own Nen level or successful activation.

### Five elemental affinities
- Fire: focused flame bursts and heat resistance.
- Air: wind blades, gusts and short aerial movement.
- Water: barriers, cleansing and limited healing.
- Earth: armor, ground control and breakable rooting.
- Lightning: precise lightning arcs, brief interrupts and controlled mobility bursts.

All five affinities are secondary channels of Nen, not independent free powers. Their effects must be distinct, balanced and costly enough that mastery matters. Dual-element and five-element combinations are endgame-level rare rewards requiring high Nen mastery and multiple verified quest trials; no ordinary market fusion or client-side crafting can create them.

### Nen-elemental acceptance tests
1. A player without Nen cannot activate any elemental relic ability, even with the relic equipped.
2. A player with insufficient Nen mastery is rejected or receives only the explicitly configured beginner effect and cost.
3. Relic awakening without Nen does not unlock activation; Nen training without the relic does not grant the element.
4. Server rejects forged Nen tier, relic ownership, quest completion, skill unlock and replayed activation.
5. Fire, Air, Water, Earth and Lightning each have distinct effects, costs, cooldowns, caps and boss/PvP resistance.
6. Relogging preserves verified Nen mastery and relic skill state without duplicating unlocks.
7. Existing non-elemental skills and marketplace transactions continue to work.
