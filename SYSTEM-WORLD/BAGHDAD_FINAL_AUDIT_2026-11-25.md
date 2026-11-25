# Baghdad Towers — Current Final Audit
Date: 2026-11-25
Repository: ahmed666alaadedt-ops/SYSTEM
Branch: feature/baghdad-five-plus-power-tower-20261122
Validated source HEAD: `b98799546259f06556b200a4dde2434a4a0e7312`
PR: #38 (open, draft; do not merge without owner approval).

## Canonical Baghdad tower registry
The district contains exactly five towers:
1. Hunter Association Tower — 200 floors, 650 m.
2. Business and Investment Tower — 36 floors, 220 m.
3. Shopping and Commerce Tower — 32 floors, 190 m.
4. Antiques and Heritage Tower — 34 floors, 205 m.
5. Technology and Innovation Tower — 40 floors, 245 m.

Power Tower is a separate destination (200 floors, 820 m) and is not one of the five. Public swimming, sports and entertainment facilities are separate public facilities, not an extra district tower. The approved Antiques Tower scope replaces the former Entertainment and Sports Tower; do not reintroduce the old tower ID into the five-tower registry.

## Exact-HEAD automated evidence
All results below refer to the validated source HEAD above unless a source SHA is explicitly stated.

- **Godot full project and Baghdad operations:** workflow run #2976, conclusion success. It imported/parses the project, launched the main scene, validated tower landmarks and lobby systems, independent pools/lockers/lifeguards, tower interiors, NPC commerce, local advertising campaigns, Power Tower arena, hotel lifecycle, Shopping Tower showcases, Hunter rivals, guide-led tunnel entry and the continuous tunnel competition.
- **Restaurant player journey:** included in the successful tower operations validator. It enters through the real table interaction route, verifies that payment is disabled before seating, performs the seat action through the UI, checks the occupied physical seat and movement lock, tests standing/releasing and reseating, then submits the order through the UI and completes waiter → kitchen/chef → waiter → meal consumption → checkout. Emergency evacuation also releases reservations.
- **Canonical Godot Android export:** workflow run #2830, conclusion success. APK artifact ID `15005286548`, size 36,799,844 bytes (about 36.8 MB), artifact SHA-256 `32639b029812c0e16c406a437f66bb50e933a1fe3a8ec225412c202913cfe7e8`. The APK itself was 36 MB; its build-log SHA-256 was `e6dee3f958ff2e0254b6e5e0ac8b50005cef04df1ed96c2aed712971e27c2165`.
- **Native SYSTEM Android app shell:** workflow run #219, conclusion success. APK artifact ID `15004304406`, size 138,573,983 bytes (about 138.6 MB), artifact SHA-256 `3c9faaca12a89c3c693fbb724c4a294d97eb25561e891754b444e32364a3cc83`.
- **Firebase marketplace and security:** workflow run #252, conclusion success. TypeScript build passed; seven Firestore rules tests and eight callable-handler/transaction tests passed against the Firestore emulator.
- Marketplace emulator coverage includes fixed-price listing escrow, atomic buyer/seller wallet settlement and ownership transfer, self-purchase/unauthenticated/insufficient-balance rejection, simultaneous double-purchase race (exactly one winner), cancellation/expiry release, outbid reservation release, auction settlement, two-player exchange, trusted currency/artifact reward idempotency, and all three scheduled expiry workers (listings, auctions, exchanges).
- **Android bridge:** versioned/allowlisted Godot protocol and request correlation have a dedicated Godot validator; the native host plugin and Firebase repository compile in the successful Android app-shell build. This proves source/build integration, not an on-device live Firebase session.
- **Baghdad OSM:** the canonical Android workflow installed the latest successful metric-cell pack and loaded Republic Bridge OSM way 1077808833 and Tigris way 24709603. The bridge deck, collision and guardrails are generated from the surveyed bridge geometry. The access causeway from the Baghdad origin to the bridge is generated game geometry, not an OSM road. This does not certify full Baghdad road coverage, official boundaries, elevation or complete geographic accuracy.

## Verified behavior and scope boundaries
- The five district towers are separately configured and connected; the Power Tower remains independent.
- Tower operations validation passed five physical elevator trips/returns, fifteen sky-garden floor mappings, staff/customer movement, and independent Power Tower behavior.
- Shopping Tower includes floor-specific product showcases, purchase routing, hotel reception/suites and restaurant floor service.
- Hotel booking, check-in, room service, checkout/refunds, housekeeping and inspection lifecycle passed automated checks. Reservation state remains local to the Godot installation; shared cross-device cloud bookings are not implemented.
- Advertising screens rotate NPC-managed local campaign messages. This is an in-world simulation, not a connected third-party ad network, paid campaign marketplace or revenue integration.
- The Hunter tunnel crowd has 500 individually indexed candidate records rendered through shared MultiMesh instances with lightweight movement/decision profiles. These are not 500 full autonomous humanoid AI agents with independent full combat/dialogue.
- The active Hunter route is the guide-led, single continuous Baghdad tunnel competition with three ordered physical checkpoints and five named rivals. Older multi-city exam-site prototypes are not the active player route; do not describe them as seven active stages.
- Candidate serial persistence is local to the installation. Global uniqueness across separate accounts/devices is not established.
- Rival combat and crowd simulation are local gameplay; online multiplayer combat/spectating is not established.

## Remaining release/production gates
1. Physical Android-device QA is still required for touch controls, visuals, frame rate, memory, thermal behavior, elevators, seating and long-session stability.
2. Firebase Functions and Firestore indexes have not been deployed to the live project. Emulator success does not prove production availability or live player-to-player trading.
3. The trusted `gameServer=true` custom claim must be provisioned securely. Reward endpoints reject ordinary clients and passed emulator tests, but no production game-server identity or verified mission-to-currency/artifact reward pipeline is deployed.
4. Hotel reservations are local, not shared cloud reservations.
5. Third-party advertising/revenue integration is not connected.
6. Baghdad geography is improved with the Republic Bridge/Tigris source cells, but full official boundary, complete road topology, elevation and citywide source-coverage verification remain outstanding.
7. The Hunter candidate serial is local, not globally coordinated across accounts/devices.
8. The 500 crowd records are lightweight shared-renderer agents, not full individual humanoid AI.
9. The PR is still draft. At this checkpoint GitHub reports it mergeable with clean merge state, but it contains 1,515 commits and 98 changed files (+28,235 / -780). Review the complete PR diff before merging.

## Merge rule
Automated source checks and APK exports are green on the validated source HEAD. Do not merge or deploy automatically. Keep PR #38 draft until the owner reviews the diff and explicitly approves the merge. Physical-device QA and live Firebase deployment remain post-merge/release gates, not claims of completion.
