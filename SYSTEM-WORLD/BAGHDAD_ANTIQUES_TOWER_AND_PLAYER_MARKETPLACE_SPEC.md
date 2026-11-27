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


## Yorknew-inspired global antiques market and historical relic quests

The existing marketplace is extended in place; do not create a second economy, duplicate inventory, or replace the escrow implementation.

### Market halls inspired by Yorknew City
- Global auction hall with scheduled public auctions, rare-lot showcases, bidder history and transparent server settlement.
- Restricted collector exchange for high-rarity pieces, with curator verification and provenance review before a lot can receive a verified label.
- Hidden dealer network for mysterious and cursed relics. These are fictional game items; suspicious provenance affects story risk and appraisal, never bypasses ownership or escrow checks.
- Dealer reputation, appraisal grades, restoration condition, provenance chain and historical-civilization filters.
- Player-owned gallery rooms and public museum displays remain separate from sale listings.
- NPC auctioneers, appraisers, curators, restorers, guards and dealers provide world activity and services.
- Every purchase, bid, exchange and cancellation continues to use the existing authenticated server transactions and escrow. No client-side balance or ownership mutation is permitted.

### Super-rare skills inside relics
Some artifacts contain a sealed skill, dormant power or historical technique. A relic may:
- reveal a skill immediately only when its authored rarity and unlock condition permit it;
- conceal a skill until a linked historical quest is completed;
- grant a skill only after a required relic-return choice is confirmed by the trusted game server.

Skill examples for the initial content set:
- Babylonian Star Tablet → Celestial Lightning (mythic).
- Sumerian Oath Seal → Earth Guardian (legendary).
- Akkadian Shadow Crown → Shadow Avatar (mythic).

These are authored content examples, not guaranteed drops from every artifact. Skill IDs are stable and unique; reward issuance must be replay-safe and server-authoritative. A client signal or local save must never grant a rare skill or mint an artifact.

### Historical-world quest loop
1. The player examines an eligible relic in the museum, collection or market and discovers its inscriptions and quest clue.
2. The game presents an optional invitation to enter the relic's linked historical world. The player must explicitly accept before travel.
3. The quest loads the corresponding historical setting (for example ancient Babylon, Sumer or Akkad) and its authored objectives, NPCs, puzzles, enemies and locations.
4. Progress is recorded against the specific quest and relic. Completion events must be validated by the trusted game server; a client-supplied objective-complete flag is not proof.
5. Each quest explicitly defines whether the relic is retained or must be returned to its original historical site. A return-required quest cannot complete until the server verifies the correct relic was returned to the correct site.
6. After the quest and any return condition are verified, the server grants the associated rare skill once, records the quest receipt and updates the player's progression.
7. The player returns to the present-day world. The museum, collection and marketplace refresh from authoritative ownership so a returned relic cannot remain listed, duplicated or tradable.

### Initial relic quest content
| Relic | Historical world | Quest objective arc | Relic outcome | Skill reward |
|---|---|---|---|---|
| Babylonian Star Tablet | Ancient Babylon | Locate the sealed archive, solve the celestial lock, defeat its guardian | Return to Esagila archive | Celestial Lightning |
| Sumerian Oath Seal | Ancient Sumer | Recover the three oaths and restore the temple seal | Return to the royal temple | Earth Guardian |
| Akkadian Shadow Crown | Ancient Akkad | Trace the lost dynasty, pass the shadow trial, seal the cursed chamber | Player retains the relic after server verification | Shadow Avatar |

### Required technical integration and closure gates
- Add a historical relic quest manager to the Godot world as a progression coordinator. It may request world travel, track presentation state and emit requests, but it is not an authority for rewards, ownership or quest completion.
- Connect its world-travel request to the existing historical-world transition system; do not create a duplicate historical-world loader.
- Connect quest objective events to a trusted server verification endpoint. Do not treat a boolean supplied by Godot as proof of completion.
- Connect verified relic-return events to the marketplace ownership service so the relic is removed from the player's tradable inventory atomically and its historical return is recorded.
- Connect the existing trusted reward endpoint `grantMarketplaceArtifactFromReward` only for artifact rewards and the trusted skill-progression reward path for skill unlocks. Both must be idempotent by stable quest/reward ID.
- Add emulator tests for forged objective events, wrong relic/site return, duplicate completion, replayed skill rewards, and concurrent return/listing attempts.
- Add Godot headless tests for relic discovery, opt-in travel request, objective progression, return-required and retain-relic branches, and duplicate reward prevention.
- Add Android/Godot physical-device tests for opening a relic quest from the market, travelling to the historical world, returning to the present, and seeing the updated server-owned collection.
- Production deployment, trusted server identity configuration and physical-device verification remain separate activation gates. A passing local quest-manager test does not mean the online reward or world-travel integration is live.
