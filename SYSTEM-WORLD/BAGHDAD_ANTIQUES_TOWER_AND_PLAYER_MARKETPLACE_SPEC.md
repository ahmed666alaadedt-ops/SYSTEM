# Baghdad Antiques & Heritage Tower — Approved Design

Status: approved design specification; gameplay implementation and online activation are not yet complete.

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

## Security and technical requirements

- All online listings, bids, purchases, escrow, wallet changes and ownership transfers must be server-authoritative through authenticated Firebase Cloud Functions and Firestore transactions.
- Never trust client-supplied prices, seller IDs, buyer IDs, wallet balances, ownership claims or artifact rarity.
- Prevent self-purchase, duplicate settlement, stale bids, double-spending, replayed requests and simultaneous purchase races.
- Keep marketplace data separate from public player profile fields. Firestore client rules must deny direct writes to authoritative market, escrow, wallet and ownership records.
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
