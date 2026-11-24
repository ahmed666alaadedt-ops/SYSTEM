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
- Entertainment and Sports Tower: 34 floors, 205 m.
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