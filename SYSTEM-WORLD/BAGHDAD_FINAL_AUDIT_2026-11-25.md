# Baghdad Towers — Final Audit Checkpoint
Date: 2026-11-25
Repository: ahmed666alaadedt-ops/SYSTEM
Branch: feature/baghdad-five-plus-power-tower-20261122
PR: #38 (draft; do not merge without explicit owner approval).

## Scope and tower registry
The current tower operations configuration defines five Baghdad towers plus a separate Power Tower:
- Hunter Association Tower: 200 floors, 650 m.
- Business and Investment Tower: 36 floors, 220 m.
- Shopping and Commerce Tower: 32 floors, 190 m.
- Antiques and Heritage Tower: 34 floors, 205 m.
- Technology and Innovation Tower: 40 floors, 245 m.
- Power Tower: separate destination, 200 floors, 820 m.
Power Tower is not counted as one of the five Baghdad district towers.

## Evidence reviewed
- Godot operations workflow run 45488435317 completed successfully. Its job included Baghdad tower landmark/lobby checks, tower interiors/NPC commerce/advertising/Power Tower arena checks, shopping product showcase routing, Hunter rival competition, hidden tunnel entry and seven-stage exam checks.
- Canonical Android export workflow run 45488435304 completed successfully, including project import/parse, main-scene launch, Baghdad OSM runtime geometry checks and APK artifact upload.
- Earlier successful runs 45184789456 and 45184789462 were also inspected.
- The branch test source includes coverage for tower floor access, elevator/staff behavior, emergency exits, shopping displays, restaurant order state progression, Power Tower individual-match rules, prediction UI, 48 seats and crowd reactions.
- These successful runs are not proof for every later edit unless the exact tested commit is matched. The tracker and TEST_RESULTS file still contain explicit pending exact-HEAD gates.

## Confirmed implementation present in source
- Five Baghdad towers are separately configured, with Power Tower independently configured.
- Tower operations manager creates staff, customer populations, lobby cafes, advertising surfaces and progression boards.
- Shopping Tower product displays have product-specific interaction areas and a purchase-preview route.
- Shopping Tower specialist catalogues are divided by floor; the regression checks expected stock, display mapping and purchase controls.
- Restaurant code has four tables per generated dining room, four seat markers per table, a player seating transition, seat release, order payment, waiter/kitchen status progression, meal consumption and completion logic.
- Power Tower source and validator include individual 1v1 enforcement, a prediction board routed to the shared virtual-credit ticket UI, 48 reservable seats, owner-only release, floor-aware cleanup and eight procedural audience actors.
- The Hunter tunnel crowd script creates 500 individually indexed candidate records, rendered through shared MultiMesh body/head instances, with lightweight behavior profiles and staggered movement/decision waves.

## Outstanding blockers — do not mark complete
1. Restaurant end-to-end physical seating regression is incomplete. The current tower validator checks that tables and interaction bodies exist, but its order lifecycle test directly sets system_restaurant_seated_table_id and system_restaurant_seated metadata before calling _place_restaurant_order. It therefore bypasses _seat_player_at_restaurant and does not prove the actual seat interaction, movement tween, occupied-seat rejection, standing/release and then order flow as one end-to-end player journey.
2. Power Tower newest spectator features need exact-HEAD proof. Seat/fan-board/audience assertions exist in the operations validator, but TEST_RESULTS still says the new audience/seating and fan-board milestones have no confirmed Godot run and canonical APK export for the exact final feature HEAD. Do not infer completion from source assertions or an older general run.
3. Six Hunter exam environments remain unbuilt/unconnected according to the completion tracker: Cairo, Alexandria, Paris, Babylon, Tokyo and Highland Frontier. The current runtime validator's seven-stage coverage does not by itself prove those six distinct physical environments exist; the tracker explicitly leaves them unchecked.
4. The 500 tunnel competitors are not 500 full independent humanoid AI agents. They have individual candidate records and behavior metadata but use two shared MultiMesh renderers and lightweight decision/movement logic. Do not describe them as fully autonomous character NPCs with independent full AI, combat and dialogue.
5. Physical Android-device QA remains outstanding. APK export and headless Godot checks do not prove touch controls, real-device visuals, frame rate, memory use, thermal behavior or long-session stability.
6. Exact tested-commit alignment must be recorded. The inspected workflow runs succeeded, but the evidence reviewed here does not establish that every newest Shopping Tower and Power Tower source change is on the exact commit those runs validated.

## Required closure gates
- Add an end-to-end restaurant regression that uses the actual table interaction route and _seat_player_at_restaurant, waits for the seating transition, proves ordering is blocked before seating, proves a real seat is occupied and released, then completes waiter → kitchen → chef → waiter → meal consumption → completion and persistence.
- Run the full Godot operations and showcase validators on the exact resulting branch HEAD.
- Run the canonical Android APK export on that same exact HEAD and record commit SHA, workflow run, artifact ID, size and SHA-256.
- Inspect the APK on a physical Android device for touch, visibility, movement, elevators, seating, floor changes, memory and sustained performance.
- Keep PR #38 draft and unmerged until the owner explicitly approves.

## Audit rule
A feature is complete only when implementation, integration, regression coverage, exact-HEAD validation and required device QA are all evidenced. A file, design note, test assertion or APK export alone is not sufficient.

## Follow-up implementation checkpoint — 2026-11-25
This section supersedes older tower-name and Hunter-entry-flow notes above where they conflict with the current approved design.

### Canonical Baghdad layout
- The five district towers are Hunter Association, Business and Investment, Shopping and Commerce, Antiques and Heritage, and Technology and Innovation.
- The Power Tower remains a separate destination and is not counted among the five.
- Swimming, sports and entertainment facilities remain public/independent facilities; they are not a sixth district tower and must not be deleted during tower reorganization.

### Hunter tunnel route
- The active player route is invitation/registration at the Hunter Association Tower, followed by an actual guide-led escort to one continuous tunnel competition.
- The guide is moved with the player and remains available inside the tunnel. The player receives and retains a permanent candidate serial.
- The exact tested commit `ab61630bff9755989e86443ceca2df4f09570b29` passed the guide-led entry and continuous competition validator: one tunnel entry, three in-tunnel progression checkpoints, 500 individually indexed candidate records and five named rivals.
- The former restaurant secret-door/seven-stage route is not the approved active player entry flow. Legacy code may remain for compatibility but must not be reactivated as the route.

### Hotel corrections
- Early checkout refund arithmetic was corrected so every unused night is refunded, including an exact 24-hour remaining period; the number of refunded nights is capped by the booking's original nights.
- The tower operations validator now asserts that an immediate checkout of a one-night booking returns the full unused-night amount while keeping the room unavailable until cleaning and inspection.
- Room-service status text now correctly says the charge is deducted from the player's wallet when the order is placed, rather than saying it is merely added to a later invoice.
- Hotel reservation persistence is still local to the Godot installation. Shared cloud reservations across players are not yet implemented.

### Marketplace expiry and integration
- A scheduled Firebase Function, `releaseExpiredArtifactListings`, now sweeps active listings every 15 minutes and atomically returns matching escrowed artifacts to their owners. A composite Firestore index for listing status/expiry was added.
- This scheduler and index are source changes only until the Firebase Functions and Firestore indexes are deployed; no live deployment is claimed.
- The Android Compose marketplace, Firebase callable repository, Cloud Functions for direct listings/auctions/exchanges, and the Godot-side versioned request adapter exist in source.
- The native Godot Android AAR/host Activity/plugin transport is still absent. Consequently, the Godot in-world marketplace is not yet live-connected to the Android Firebase handler. The Compose marketplace and its Firebase path must be validated separately.

### Advertising status
- Baghdad tower screens currently rotate NPC-managed local campaign messages every 38 seconds and show the responsible staff member.
- This is an in-world advertising simulation, not a connected third-party ad network, paid campaign marketplace, or revenue integration.

### Exact-head validation gate
- Hotel refund, room-service text, marketplace scheduler, export and index changes were made after the Hunter-tested commit above.
- Run Godot operations validation, Firebase Functions TypeScript build, Android app build and canonical Godot APK export on the latest branch HEAD before treating these follow-up changes as validated.
- Keep PR #38 draft and unmerged until the owner explicitly approves.


### Scheduled marketplace lifecycle follow-up
- Direct-sale listings now have a 15-minute scheduled expiry sweep that atomically releases the listed artifact from escrow when the listing expires.
- Player-to-player exchange offers now have a 15-minute scheduled expiry sweep that releases the offered artifact from escrow.
- Auctions now have a 5-minute scheduled settlement sweep; it reuses the same atomic settlement transaction as the authenticated manual settlement endpoint. Winner escrow validation also rejects reserved balances greater than the wallet balance.
- Firestore composite indexes exist for listing status/expiry and exchange status/expiry. The auction status/end-time index already existed.
- These are not live until Cloud Functions and indexes are deployed to Firebase. Exact-HEAD TypeScript build and Firestore emulator checks are pending for commit `1b83e5ca73d2e12a9cddbe6c936a9647757383e6`.
