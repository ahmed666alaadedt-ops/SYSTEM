## Current authoritative Hunter route — 25 November 2026

This current section supersedes older historical entries below that describe the former multi-stage examination or the restaurant secret-door route.

- The active examination is one permanent underground tunnel competition beneath the Baghdad five-tower district, with three ordered physical checkpoints.
- Discovery begins in the Hunter Association Tower lobby with an Arabic become-a-Hunter invitation and explicit accept/decline choices.
- On acceptance, the player follows the visible Hunter Guild guide, who escorts them to the tunnel. The candidate serial is allocated and saved only on tunnel arrival, then reused on re-entry.
- The Shopping Tower restaurant retains its independent dining, waiter, chef and meal lifecycle; it is not the current examination entrance.
- The crowd has 500 individually tracked lightweight background candidates and five named interactive rivals. Do not describe the crowd as 500 full physics/pathfinding combat agents.
- The Marshland remains separate and unconnected until a future explicit design update.
- Automated runtime checks on recent branch snapshots passed the Hunter invitation, guide escort, serial behavior and continuous tunnel competition. Physical Android presentation checks remain outstanding.
- PR #38 remains draft; main is unchanged and must not be merged without explicit user approval.

---

## Historical record: superseded stage-based Hunter prototype — 24 November 2026

- [x] Restored the canonical seven-stage progression: Baghdad heritage, Cairo buried market, Alexandria lighthouse, Paris catacombs, Babylon guardian, Tokyo urban pursuit, and Highland Frontier survival.
- [x] Aligned the manager's first stage ID with the Baghdad heritage runtime (baghdad_heritage_trial); this fixes the prior stage-ID mismatch that rejected artifact recovery.
- [x] Replaced the obsolete one-stage validation with a seven-stage regression covering stage order, evidence checks, Baghdad clue order, seven physical spike obstacles, relic unlock/recovery, the six additional stage environments, rival initialization, candidate persistence, and final provisional-license progression.
- [x] Updated the main runtime stage-start handler to accept all seven stage IDs, rebuild the stage environment on each transition, move the player to the next environment, and connect rival event feedback.
- [x] Restored the actual exam-start action: the start request now begins the exam only after the player is registered and physically inside the tunnel; otherwise it follows the invitation/guide/registration path.
- [x] Connected the first playable examination environment directly after the physical tunnel floor (local Z=40), eliminating the prior isolated spawn location; stage transitions now rebuild the next environment and reposition the player at its entry.
- [ ] Exact-head Godot validation and Android export are running on PR #38; do not mark the new progression verified until both exact-head runs complete successfully.
- [x] Added 500 individually tracked tunnel competitor records (serials 2001–2500), visible low-poly body/head MultiMesh instances, unique archetypes, skill/cooperation/error profiles, and staggered movement.
- [x] Added lightweight individual non-combat decisions for scouting, observing, practicing, cooperating with a nearby candidate, and recovering from mistakes; each candidate tracks decision, cooperation and mistake counts. The first two decisions in each wave explicitly exercise cooperation and mistake recovery.
- [x] Added exact operations, tunnel-entry and stage-runtime assertions for all 500 visible instances and behavior profiles, unique serial lookup, decision waves, cooperation events, and mistake-recovery events.
- [ ] The 500-person population is still a lightweight background simulation rather than 500 full physics/pathfinding agents with individual dialogue or combat. Five named rivals retain the fully interactive theft/recovery and individual-duel behaviors; crowd cooperation is non-combat only.
- [ ] The six non-Baghdad stage environments currently use procedural route blockouts with stage-specific labels/objectives/materials; distinct production-grade city environments, travel transitions, and visual inspection remain open.
- [x] Implemented the concealed entrance inside Shopping Tower restaurant floor 29: the Eye → River → Crown clue sequence resets on wrong order, the disguised stone slab remains locked until formal Hunter Association registration, and the revealed elevator performs a timed physical descent to the underground tunnel.
- [x] Moved formal candidate registration to the Hunter Association Tower menu, made the guild guide direct registered candidates to the restaurant, and gated exam start on both solved riddle and physical tunnel arrival.
- [x] Rewrote the tunnel-entry regression to exercise invitation decline/acceptance, tower registration, wrong-order reset, clue sequence, registration gate, stone-door reveal, elevator descent, persistent serial, 500-candidate crowd, and Baghdad stage-one activation.
- [x] Full Godot validation passed on commit `049e7359fbcd7a8ec51eabc99d38b4cccbb10a78`, workflow run [45488435317](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45488435317). All steps passed, including the five Baghdad towers, 200-floor Power Tower, shopping showcases, rival competition, restaurant riddle/physical descent, 500-candidate behavior assertions, and all seven examination stages.
- [x] Canonical Android APK exported successfully from the same commit in [run 45488435304](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45488435304). Artifact `14965456591`, 36,733,527 bytes, available until 2026-12-08 21:13 UTC. The Godot operations validation log is artifact `14965018625`, available until 2026-12-01 21:20 UTC.
- [ ] Manual Android-device visual/performance verification remains outstanding; CI export does not replace testing the APK on a physical phone. Full physics/pathfinding, dialogue, and combat for every background candidate remain outside the lightweight 500-person behavior simulation.

## Baghdad Towers — approved skyline visual expansion — 24 November 2026

- [x] Preserved the user's exact approved Baghdad Towers image as the canonical visual reference; do not substitute another city design or alter its identity.
- [x] Extended the existing upper-city scene with three broad circular floating platform tiers and luminous perimeter rims, inspired by the reference composition.
- [x] Added sixteen structural support pylons, ten decorative glass skyline towers with illuminated crowns, and a central glass SYSTEM spire with the blue S insignia.
- [x] Kept these additions as decorative skyline architecture only: they do not add functional towers, alter the five connected Baghdad district towers, or pull the independent Power Tower into the district.
- [x] Added regression assertions for the three platform tiers, rims, ten glass skyline towers, central S insignia, five-tower district count, and separate Power Tower.
- [x] Canonical Godot runtime validation passed on visual-expansion code commit `b5007eea458926b476be171cf4e034a0318fb6af`; the tower-landmark validator, hidden tunnel, all seven exam stages, full tower operations/elevator/emergency checks, terrain streaming, child-character safety, WGS84 anchor integration, Star Gate/Greed Island checks, and main-scene launch all passed in run `45419115879`.
- [x] Canonical Android APK export passed on the same code commit in run `45419115697`; artifact `14933632005`, 36,639,382 bytes, expires 8 December 2026.
- [ ] Actual Android visual inspection remains pending; the new architecture is procedural geometry and must be reviewed against the saved reference image before claiming a finished art match.


## Baghdad Hunter Examination Tunnel entrance — 24 November 2026

- [x] Added a concealed Hunter Examination entrance beneath the Baghdad five-tower district, separate from the independent Power Tower; removed the exposed public ramp, glowing portal frame, and bilingual tunnel sign.
- [x] Added three low-profile stone clues around the district. The player must inspect them in the correct sequence (Eye → River → Crown); a wrong clue resets the sequence.
- [x] The final blank masonry wall disguises the secret door. Solving the three-clue sequence slides the concealed stone slab upward, removes its blocking collision, illuminates the reveal, and reveals the descending passage.
- [x] Connected the hidden door interaction to the existing Hunter Examination registration and `begin_exam()` flow; unregistered players are directed to register at the Hunter Association.
- [x] Closed the alternate guild-menu start path: the test cannot start until the three-clue riddle is solved and the player is registered; successful start places the player at the physical tunnel entrance. The guild menu now explains these access requirements in Arabic.
- [x] The concealed-door interaction is blocked until the riddle is solved. After registration, starting the existing exam progression moves the player to the revealed underground passage entrance and clears player velocity.
- [x] Added a physical Baghdad heritage-site stage environment to the hidden passage: collidable stone chamber, entrance and perimeter walls, carved Eye/River/Crown tablets, a physical spike-trap obstacle lane with side routes, an artifact pedestal, and an initially concealed relic.
- [x] Connected stage-start events to the runtime builder and routed tablet/relic interactions into ordered objective progression. Wrong inscription order resets the sequence; the relic becomes visible and recoverable only after all three clues are read correctly; recovery completes stage one through the existing sequential exam manager.
- [ ] Build and connect the remaining six physical examination environments (Cairo, Alexandria, Paris, Babylon, Tokyo, Highland Frontier) with their own stage-specific objectives and transitions.
- [x] Added `tools/validate_hunter_exam_stage_runtime.gd` and inserted it into the canonical Godot validation workflow. The regression covers physical floor/wall collision, all seven spike obstacles, rejection/reset of a wrong clue order, successful Eye → River → Crown progression, artifact visibility gating, artifact recovery, and sequential advancement to Cairo.
- [ ] Run the new stage regression plus full Godot runtime/operations checks and Android APK export on the exact updated PR head. No validation or APK success is claimed until those exact-head runs pass.
- [ ] Review the physical chamber, spike collision and relic interaction in an actual Android build; the current environment is a procedural gameplay prototype, not finished cinematic art.
- [ ] Review the entrance placement and visibility in the actual Android build; the current structure is a functional geometry prototype, not the finished cinematic underground complex.

## Validation runtime diagnosis — 24 November 2026

- [x] Confirmed the canonical Android debug APK export on commit `92f3f47b02845de66777b8cd192ea8b1f230ac89` succeeded; artifact `14867240819` is available through 7 December 2026.
- [x] Confirmed the main-scene mesh diagnostic reported `mesh_instances=5945`, `null_mesh_instances=0`, `multimesh_instances=137`, and `invalid_multimeshes=0`; the repeated dummy-renderer `Parameter \"m\" is null` messages occur during the separate transient child-character QA scene and are not evidence of missing meshes in the canonical runtime scene.
- [ ] The extended operations validation was cancelled at its 20-minute job timeout before reaching its later Power Tower arena and restaurant checks. Added trace checkpoints around sovereign boss phase frames, reward settlement, and Shopping Tower floor generation; increased this validation job's timeout to 45 minutes so the next run can identify and complete the slow section.
- [ ] Do not mark the extended validation passed until its complete workflow succeeds.
## Power Tower — safe spectator prediction lifecycle prototype — 23 November 2026
- [x] Strengthened the 200-floor regression validator to require exactly one human opponent, `INDIVIDUAL_1V1`, `ONLINE_1V1`, and `ai_fallback=false` on every floor; this prevents team formats or AI substitution from silently entering the official competition profile.
- [ ] Re-run the extended Godot operations validator and canonical Android export on the exact updated PR head before marking this regression verified.

- [x] Added local match registration for exactly two distinct fighters and stable match IDs.
- [x] Added fan prediction submission before lock; fighters cannot predict their own match, and duplicate/invalid/late entries are rejected.
- [x] Added match-start locking and one-time result settlement through the local combat-authority path; invalid or untrusted results are rejected.
- [x] Correct predictions award one non-purchasable, non-transferable spectator point; wrong predictions do not deduct wallet credits or points. No real-money stakes, transfers or cash value exist.
- [x] Added a transparent cap of 20 free predictions per spectator per UTC day and persisted match, point and daily-count data separately from the SYSTEM credits wallet.
- [x] Added regression assertions for fighter self-prediction, duplicate entries, lock timing, untrusted/repeated settlement, correct/incorrect rewards, daily limit and save/reload.
- [ ] The new lifecycle code and regression additions still require canonical Godot validation and Android export on the latest PR head; the new workflow result has not yet been confirmed.
- [ ] A playable spectator interface, NPC/player match scheduling, global online predictions, server-authoritative settlement and production anti-cheat remain open. The local prototype must not be represented as live global competition.
- PR #38 remains a draft on `feature/baghdad-five-plus-power-tower-20261122`; do not merge into `main` without explicit user approval.

## Entertainment Tower — expanded indoor aquatic facilities — 23 November 2026

- [ ] Expanded the existing pool floors 18–20 without replacing the swimming trigger, buoyancy, swim-stroke movement or lap activity.
- [ ] Added separate men's and women's changing suites on each pool floor, with lockers, benches, shower partitions, shower fixtures and floor signage.
- [ ] Added a lifeguard station, rescue ring, pool ladders and clear Arabic/English zone labels.
- [ ] Differentiated the three pool floors: floor 18 lap lanes and starting blocks; floor 19 family splash pool and fountains; floor 20 spa hot tubs, thermal pool, sauna and steam room.
- [ ] Extended the Godot operations validator to require all three floor layouts, changing suites, lockers/showers, lifeguard station and floor-specific aquatic features.
- [ ] Awaiting canonical Godot validation and Android export on the resulting PR head; no Android device inspection has been claimed.
- Scope remains the five connected Baghdad district towers. The independent 200-floor Power Tower remains separate; no merge to main.

## Baghdad tower staff elevator duty and floor workstations — 23 November 2026

- [x] Added floor-to-role duty assignments across all 542 floors in the six Baghdad towers: Hunter Association (200), Business & Investment (36), Shopping & Commerce (32), Entertainment & Sports (34), Technology & Innovation (40) and Power Tower (200). Every valid floor now resolves to a persistent staff member within that tower's roster.
- [x] The assigned persistent employee boards the actual tower elevator car, travels with the car, then exits onto the active floor and walks to a generated 3D desk/terminal workstation with a role and floor sign. The employee remains a normal interactable staff NPC.
- [x] On floor changes, the previous duty employee is safely returned to the correct lobby before its floor is replaced. On lobby return, the active employee rides the elevator back, resumes the original four-waypoint lobby patrol and retains the same NPC identity.
- [x] Return-to-lobby now restores customer visitors to their correct public lobby before the active floor is removed.
- [x] Extended the tower operations validator to exercise the Shopping Tower chef's elevator boarding, arrival at the floor-29 workstation, physical emergency-exit evacuation, staff return to lobby patrol and restoration of all four persistent Shopping Tower customers.
- [x] Focused tower elevator/emergency validation passed in canonical Godot run #456 (run ID `45078571741`) on exact HEAD `77f2d02b1aff937bf2d6bee061fb581e8f9394a1`.
- [x] Android build #1240 passed on the same exact HEAD. APK artifact `14775914279`, 35,957,009 bytes, SHA-256 `cd910faa4ee7cc9fa45a705edfa4ee6f95b53220bf9384acb1039b1a9bc079b3`; expires 6 December 2026.
- [ ] Physical Android inspection of elevator staff boarding/arrival, emergency-exit trigger and lobby restoration remains outstanding.
- [ ] Add multi-stop autonomous work routes and shift changes; current routing assigns one duty employee to each floor when the player visits it.
- [ ] Full PR validation #1503 (run ID `45078548523`) still fails at the existing VR-course floor collision assertion (`VR course floor is missing its physical collision surface`). No VR course, arcade or robot gameplay code was changed as part of this Baghdad tower work; the focused canonical tower checks passed.

## Baghdad tower floor emergency evacuation — 23 November 2026

- [x] Added a marked emergency exit doorway to every generated tower floor, with a clear wall opening, bilingual Arabic/English floor-specific signage, illuminated beacon, emergency light, route marking and alarm call point.
- [x] Added a physical Area3D exit sensor; the player must enter the exit volume to trigger evacuation back to the public lobby through the tower elevator return sequence. Leaving an active Power Tower floor through this route safely abandons that floor rather than awarding a clear.
- [x] Extended the tower operations validator to inspect emergency exits across representative floors in all six Baghdad towers, verify the sensor/collision/signal and lighting, assert that the doorway is not blocked by the circular wall, and exercise the physical evacuation-to-lobby lifecycle.
- [x] Canonical Godot runtime validation #439 passed (run ID `45076778138`) on exact HEAD `037c937cfb88944089eb4b260dc0ca38b812aa64`.
- [x] Android export #513 passed (run ID `45076777972`) on the same exact HEAD. APK artifact `14775691617`, 35,851,988 bytes, SHA-256 `2f370b4ab223fdd5bcbc86ee7d9c875847c049d96d4b163afc64699d6dbfecb2`; expires 6 December 2026.
- [ ] Physical Android inspection of the new exit collision, touch-free trigger, evacuation transition and tower-floor visuals remains outstanding.
- [ ] PR-wide Godot validation #1487 (run ID `45076724851`, earlier head `6490a87b396bb1a8bc9b1b3a86a154c18bdf16c0`) failed in the pre-existing child-character safety QA step after its PASS message, with repeated engine errors `Parameter "m" is null` from `mesh_get_surface_count`; the separate canonical runtime validation on current HEAD passed. Investigate that QA teardown issue before declaring the full PR workflow green.

## SYSTEM ARCADE — playable number-puzzle cabinet mode — 22 November 2026

- [x] Added a fourth selectable arcade game mode, a five-question arithmetic puzzle, to the six-cabinet arcade gallery.
- [x] Each question presents four answer choices; correct answers advance and add 20 points, wrong answers consume one of three lives, and the session completes only after all five questions are solved.
- [x] Added a dedicated puzzle prompt and four answer buttons, routed cabinet 4 directly to the puzzle mode, and prevented the generic projectile action from bypassing the puzzle.
- [x] Extended Godot regression coverage for four-mode selector mapping, valid/wrong/last/invalid puzzle answers and all six cabinet interaction routes.
- [x] Godot 4.3 full validation #1475 passed (run `45072584636`) and canonical Android export #1212 passed (run `45072584567`) on exact PR HEAD `efb97b6b489073e02ef587f8b68c864901e2f332`.
- [x] Android APK artifact `14773853528`, 35,937,509 bytes; expires 6 December 2026.
- [ ] Six fully distinct cabinet games, cabinet-specific art/audio and physical Android playtesting remain open; the gallery currently offers four playable modes across six cabinets.

## SYSTEM VR Lab — traversable three-gate simulation course — 22 November 2026

- [x] Replaced the VR lab's generic checkpoint-only room with a generated 3D simulation course containing a marked floor route, start/finish markers, three framed energy gates with physical Area3D checkpoint sensors, four holographic obstacles and an illuminated exit beacon.
- [x] Checkpoints now advance only when the player enters the expected physical sensor in sequence; out-of-order gates are rejected, and the session reward is granted only after all three gates are crossed.
- [x] The VR activity panel now instructs the player to traverse the course and hides the manual checkpoint button, so the activity is completed through movement rather than repeated UI taps.
- [x] Extended the Baghdad tower operations validator to require all three checkpoint sensors and exercise out-of-order rejection plus successful ordered traversal through all gates.
- [x] Godot 4.3 full validation #1473 passed (run `45072078820`) and canonical Android export #1210 passed (run `45072078816`) on exact PR HEAD `225a8888445006eaaa0f57153ce80c4b1f730ef7`.
- [x] Android APK artifact `14773292675`, 35,934,311 bytes; expires 6 December 2026.
- [ ] Native immersive headset support (OpenXR, stereoscopic rendering, tracked head/controllers or hand input), comfort testing and physical Android/headset playtesting remain open. This milestone completes the traversable 3D simulation-course prototype, not full VR hardware immersion.

## SYSTEM tower staff — autonomous lobby waypoint patrols — 22 November 2026

- [x] All 45 tower employees now receive four safe local lobby waypoints around their assigned service area; patrol paths alternate direction by staff index to reduce overlap between adjacent staff.
- [x] Each employee follows a repeating tween-driven route, turns toward each waypoint, switches the rigged NPC model to its walk animation while moving, and returns to idle during waypoint pauses.
- [x] Patrol tweens are bound to the employee node, tracked in metadata and safely restarted without duplicate concurrent routes.
- [x] Extended validator coverage across all five district tower lobbies to require patrol metadata/waypoints for every employee, then restart a sample patrol and verify real position change plus the walk activity state.
- [x] Godot 4.3 full validation #1457 passed (run `45070266061`) and Android export #1194 passed (run `45070266053`) on exact PR HEAD `7553490f1c9dcfa883a27eb437e7edb21daa3790`.
- [x] APK artifact `14773350892`, 35,923,632 bytes; SHA-256 `5093fafbac4b199ab49cc71086f8f23d15eab88907c779ef97f4b34b9c4062a6`; expires 6 December 2026.
- [ ] Cross-floor navigation, staff movement to assigned workstations, elevator use and task-driven service routing remain open; this milestone completes autonomous lobby patrols only.

## SYSTEM robotics lab — five-part animated robot assembly — 22 November 2026

- [x] Expanded the display robot from three static pieces to five assembled components: base, torso, head and two arms, each with its own material and target position.
- [x] Each of the five assembly steps animates its part from above the model into its correct position with scale/rotation easing.
- [x] After the final part lands, the robot begins a repeating idle animation with independently moving arms and head; previously completed assemblies restore in their completed pose and resume idle motion.
- [x] Extended the technology tower validator to require all five visible/assembled parts, wait for the assembly tweens to settle, verify each target position and scale, and confirm the idle arm animation is moving.
- [x] Godot 4.3 full validation #1453 passed (run `45069526833`) and Android export #1190 passed (run `45069526808`) on exact gameplay/validator HEAD `55173b411dc1eae5cf110019e7ad336eef50c1f7`.
- [x] APK artifact `14772722703`, 35,921,595 bytes; SHA-256 `83b2031751e70b97cf003c82300bdf99f24fa57ade2dc9df8ff495fca52bb79d`; expires 6 December 2026.
- [ ] Autonomous robot navigation, AI-driven task behavior and robotics beyond the assembly showcase remain open; this milestone completes the animated assembly/idle-motion subtask only.

## SYSTEM ARCADE — timed reflex mini-game — 22 November 2026

- [x] Added a third playable arcade mode, timed reaction challenge, alongside the physical target shooter and color-memory game.
- [x] Each round waits a randomized 1.0–2.4 seconds before showing the signal; pressing early consumes one of three lives, while successful responses score by measured reaction time. Five successful rounds complete the session; exhausting lives ends without reward.
- [x] Added session IDs to reflex timers so stale delayed signals cannot advance a newer round; updated cabinet mode routing so the six physical cabinets are distributed across shooter, memory and reflex modes.
- [x] Extended deterministic validator coverage for mode mapping and reflex scoring at fast, slow and invalid reaction times; corrected the UI to show the active game's status/instructions and correct goal count.
- [x] Godot 4.3 full validation #1449 passed (run `45069046046`) and Android export #1186 passed (run `45069046075`) on exact PR head `10ae1880b313627b985620063eb49542f194f0f5`.
- [x] APK artifact `14772358338`, 35,919,755 bytes; SHA-256 `5ab08d9e259587db93a86d1549f8d406702b80fbd80e01f5e59d1b27fcf0a02c`; expires 6 December 2026.
- [ ] Full cabinet-specific game variety beyond the three current modes, advanced cabinet visuals/audio and physical Android play testing remain open; full arcade feature remains in progress.

## SYSTEM ARCADE — direct cabinet interaction — 22 November 2026

- [x] Added six individually addressable arcade cabinet interaction areas with collision shapes, SYSTEM interaction prompts, tower/floor metadata and cabinet IDs.
- [x] Added emissive cabinet display panels and assigned the six cabinets to the currently playable physical target-shooter or color-memory mode.
- [x] Routed direct world interaction from each cabinet through `main.gd` to `open_arcade_cabinet`, which opens the correct facility panel and selects the cabinet's game mode.
- [x] Extended the full tower validator to verify all six cabinet interaction areas, their interactable group membership, stable IDs and supported mode metadata.
- [x] Godot 4.3 full validation #1440 passed (run `45068515109`) and Android export #1177 passed (run `45068515127`) on exact gameplay/validator HEAD `610bc56d5f6a29f16b9241786a7ebe23795762e0`.
- [x] APK artifact `14772695982`, 35,916,791 bytes; SHA-256 `ee77964c4a9f54cc672675accb10f59f1f86ac751caceb92208be0158511b948`; expires 6 December 2026.
- [ ] Distinct full games for all six cabinets, additional cabinet-specific mechanics and physical Android interaction testing remain open; do not mark the complete arcade system finished.

## SYSTEM ARCADE — color-memory cabinet mini-game — 22 November 2026

- [x] Added an arcade game-mode selector with the existing physical projectile target challenge and a distinct color-memory cabinet mini-game.
- [x] Memory mode presents a five-color sequence for a timed preview, then accepts player input through four dedicated color buttons; correct inputs advance the sequence and score, wrong inputs reset progress and consume one of three lives, and exhausted lives end the round without a reward.
- [x] Added deterministic validator coverage for correct input, wrong-input reset, sequence completion and invalid post-completion cursor; retained six individually addressable arcade cabinet nodes and the existing physical target-sensor tests.
- [x] Fixed a GDScript type-inference issue in the robotics assembly target-position setup discovered by the Godot parser during this validation cycle.
- [x] Godot 4.3 full validation #1438 passed (run `45068152660`) and Android export #1175 passed (run `45068152569`) on exact PR head `d3c5c4f8e120c391adda03505b52fa2c9d16838a`.
- [x] Android APK artifact `14771998841`, 35,914,561 bytes; SHA-256 `0dd8f59177fee08b2d6da6e685fb7c60c24ad9078564b0d315bcc8c1084ece8b`; expires 6 December 2026.
- [ ] Cabinet-specific full games for each physical cabinet, individual cabinet interaction/start routing and real-device play inspection remain open. This milestone adds a second playable mini-game mode; it does not close the full arcade-cabinet feature.

## SYSTEM cinema original three-scene program — 22 November 2026

- [x] Replace the cinema's single generic attendance confirmation with a three-scene in-game viewing sequence using original SYSTEM story cards: "نداء بغداد", "أسرار برج النور", and "رحلة الصياد الأول".
- [x] Generate an emissive cinema screen and a visible 3D program title; advance the displayed scene and screen glow as the player progresses through the three viewing steps.
- [x] Award the activity score/reward only after all three scenes have been viewed; retain the existing local activity-stat persistence.
- [x] Extend the Baghdad tower operations validator to require the cinema screen/title nodes and verify all three displayed scene numbers in sequence.
- [x] Godot 4.3 full validation #1428 passed (run `45067209969`) on exact gameplay/validator HEAD `b6b8fabaacc89dc3a65ce8347a69832811f70c7d`; script import/parser, main-scene launch, tower landmark checks and the complete tower operations validator all passed.
- [x] Android export #1165 passed (run `45067210032`) on the same exact HEAD. APK artifact `14771728504`, 35,906,678 bytes, SHA-256 `b1a16cc656bc4127bfa17f3fd470bd20add6a439de567a1d961120f22c06cca0`; expires 6 December 2026.
- [ ] Physical Android visual/touch inspection remains outstanding. This milestone is an original three-scene in-game program display, not licensed film playback or a full cinema media player; actual film programming/playback remains open.

## Baghdad sports gameplay physics — 22 November 2026

## Authoritative status and supersession note — 22 November 2026

This status block is authoritative over older historical backlog notes below. Older entries are retained for project history; where they say a feature is absent or unverified, use the later verification records and the status here.

- The five connected Baghdad district towers and the independent 200-floor Power Tower remain on draft PR #38; nothing is merged into `main`.
- The hotel is beyond a visual blockout: local-save room booking, rank-gated room selection, payment/refund, check-in/check-out, housekeeping plus inspection, and paid room-service orders with guarded `placed → preparing → delivered` transitions are implemented. This is a local prototype, not a server-authoritative online hotel.
- Pool swimming physics, full ten-frame bowling with strike/spare/tenth-frame bonuses, a ten-possession basketball 1v1 match against a physical-shot AI opponent, a ten-shot SYSTEM ARCADE target game with lives/combos, Shopping Tower dine-in, hotel housekeeping/room-service, and original cinema scene progression are implemented and covered by the full tower operations validator. Godot validation #1432 (run `45067580400`) and Android export #1169 (run `45067580289`) passed on exact PR head `40fcf61c87244fab825e96aab27c419c30d0ea95`.
- Bowling scoring regressions cover a perfect 300 game, a zero-pin game and ten consecutive spares (150). Basketball match regression covers ten alternating possessions, player/opponent score tracking and win/draw/loss result. Arcade regression covers target values, capped combo bonuses, invalid target handling, lives and a ten-shot round; the six cabinets now route to three playable modes (target shooter, color memory and timed reflex), but full cabinet-specific games remain open. Cinema advances through three original SYSTEM story scenes; actual video playback remains open. Robotics now has a verified five-part assembly animation and moving idle arms/head; advanced autonomous robotics behavior remains a future enhancement. Physical Android inspection remains outstanding. Online/team sports, immersive VR, staff navigation between floors/workstations and completed room interiors remain open; all tower lobby staff now have tested autonomous waypoint patrols with walk/idle animation.
- Do not call the five-tower district fully complete while these explicitly open gameplay and physical-device checks remain. Keep PR #38 as draft and do not merge without the user's explicit approval.

- Shopping Tower restaurant dine-in workflow is implemented and verified on source commit `6a9f1391581d408ca45b8ede9f6f9d4ddd530bdf`: four interactable tables per restaurant floor (29–32), multi-item paid orders, persisted order states, chef preparation controls, waiter serving controls and guest table release. Godot validation #1419 passed (run `45066493197`) and Android export #1156 passed (run `45066493084`) on that exact source commit. APK artifact `14771617600`, 35,903,279 bytes, SHA-256 `c6090d16e02e74edf34b11bac3b8fa18c0b00141bf993c462ec7e71b00746a3b`, expires 6 December 2026. Physical Android play inspection remains outstanding.

---

- [x] Upgrade the bowling floor with a collidable lane, one physical bowling ball per throw, ten rigid-body pins, collision-driven pinfall scoring and pin reset between frames.
- [x] Add ten scored bowling frames with per-frame pinfall, cumulative score, a lock while the ball is moving and completion rewards.
- [x] Upgrade the basketball court with a collidable court surface, backboard, visible rim, scoring Area3D and a launched rigid-body basketball; score only when the ball enters the hoop sensor.
- [x] Add five basketball attempts with two points per detected basket and a final result that records whether the last shot scored.
- [x] Add touch-friendly horizontal aim sliders for bowling, basketball and arcade target shooting, so the player can adjust direction on a phone without keyboard input.
- [x] Add five glowing arcade targets with Area3D hit sensors and physical energy projectiles; award points only when a projectile reaches a target sensor.
- [x] Extend the Godot operations validator to check bowling lane/pin generation, await ten physical throws, check the basketball sensor and await five physical shots, then validate all five arcade target sensors and physical projectile attempts.
- [x] Godot 4.3 full validation #1403 passed on exact gameplay commit `41fe553514b0f448bf4019ca39a2dceef6e0af0f` (run ID `45065541279`): import/parser, headless launch, tower landmarks and complete tower operations validator, including physical bowling pinfall, basketball baskets and arcade target hits.
- [x] Canonical Android APK build #1140 passed on the same exact commit (run ID `45065541351`); APK size 35,892,104 bytes; SHA-256 `051c6b4e2d6c6bb9bb840da2baccc1fd140053caa454052428438ea6f9e7d355`; artifact expires 6 December 2026.
- [ ] Tune physical ball trajectories, collision response and touch aiming after a real Android play session; the headless Godot physics validator now confirms at least one physical pinfall, basketball basket and arcade target hit.

## Baghdad pool movement integration — 22 November 2026

- [x] Add a dedicated 3D water-volume Area3D inside the pool, with player body enter/exit detection.
- [x] Set and clear the player's swimming state and water-surface height when entering/leaving the pool.
- [x] Add reduced horizontal swim speed, buoyancy toward the water surface and a jump/swim-stroke impulse in the main player physics loop.
- [x] Extend the tower operations validator to check water-volume generation, swimming-state entry/exit and the swim-stroke impulse.
- [x] Godot 4.3 validation #1405 passed on tested source commit `976ffdf2a2b92dede330b617303ab847ae07c878`; the full tower operations validator includes pool water-volume entry/exit, swimming state, buoyancy and swim-stroke checks. Android export #1142 passed on the same source commit. Physical Android pool inspection remains pending.

## Baghdad tower facility activity loops — 22 November 2026

- [x] Route specialized facility interaction targets to their own activity panel before the generic floor-services handler.
- [x] Add a repeatable three-lap pool session with progress, completion and local reward tracking; this is a lap-count activity, not swimming physics.
- [x] Add an eight-set fitness session and a five-shot sports-court scoring challenge.
- [x] Add a ten-frame bowling scoring loop with a recorded score and completion reward.
- [x] Add a cinema attendance/session confirmation interaction; actual film playback, licensed programming and seating occupancy remain open.
- [x] Add a five-target arcade challenge and a three-station family-zone discovery activity.
- [x] Add a rooftop photo/exploration completion activity.
- [x] Add three-step robotics assembly, AI signal-analysis and VR checkpoint challenges.
- [x] Persist completed rounds, best scores, cumulative scores and rewards locally; extend the operations validator to exercise every activity and verify save/load persistence.
- [ ] Replace remaining prototype controls with full movement-driven gameplay: pool water-volume/buoyancy/swim-stroke behavior is implemented and passed Godot validation #1405; bowling has physical ball/pins and a ten-frame loop; basketball has a physical ball and hoop sensor. Full bowling bonus scoring, complete sports matches, actual cinema playback, full arcade cabinet gameplay, animated robotics assembly and immersive VR simulation remain open.
- [x] Godot 4.3 full validation passed on gameplay commit `bdbcf4e0c607d0aef37ca1d087163dc10ecc36a1`: validation run #1365 (run ID `45062732609`), including script import/parser, headless launch, Baghdad tower landmark checks, and the complete tower operations validator with all eleven activity loops plus local save/load regression.
- [x] Canonical Android APK export passed on the same exact gameplay commit: build #1102 (run ID `45062732606`); APK size 35,877,768 bytes; SHA-256 `52aeb1e53e558922eda631ade2f4a856ac1451415981022ddb449838a9fd4630`; artifact expires 6 December 2026.
- [ ] Inspect the exported build on a physical Android device after a fresh export.

## SYSTEM Hotel room-service workflow — 22 November 2026

- [x] Add a room-service menu for checked-in hotel guests with Iraqi food, drinks and desserts.
- [x] Charge the guest wallet when an order is placed and persist the order with its item, price and timestamp in the room booking record.
- [x] Add explicit order states: placed, preparing, delivered; only allow the valid forward transitions.
- [x] Expose preparation and delivery confirmation controls in the active hotel stay interface.
- [x] Extend the Baghdad operations validator with a paid order lifecycle regression and restore the original hotel booking/wallet fixtures after the test.
- [ ] Room-service processing is currently local and staff-confirmed through the hotel interface; server-backed kitchen dispatch, autonomous waiter navigation and physical table/room occupancy are not implemented.
- [x] Run the updated Godot validator on exact commit `54e7ad39ecdc8ecd2076ebb18154dcf9342592d2`; GitHub Actions validation run #1359 completed successfully (run ID `45062020997`).
- [x] Export the canonical Android APK from the same exact commit; GitHub Actions Android build #1096 completed successfully (run ID `45062020991`).
- [ ] Physical-device Android gameplay inspection remains pending; successful export does not certify device-side visuals, controls, frame rate or persistence.

# Baghdad living tower district — canonical implementation update — 22 November 2026

This section supersedes older tower-role notes below wherever they describe the obsolete standalone weapons tower or an earlier four-staff roster.

## Canonical district
- [x] Keep exactly five connected Baghdad towers: Hunter Association, Business & Investment, Shopping & Commerce, Entertainment & Sports, and Technology & Innovation.
- [x] Keep Power Tower separate from the district, with its own 200-floor progression and four dedicated operations staff.
- [x] Keep weapons, armour, equipment, Nen research, elixirs, hotel and restaurants inside Shopping & Commerce Tower; no separate weapons tower is generated.
- [x] Put the Global Hunter Association headquarters on floor 200 of the Hunter Association Tower, with the Global Council chamber on floor 195 and Hall of Honor on floor 100.

## Staff, uniforms and customers
- [x] Expand the four non-shopping district towers to eight professional NPC employees each: tower director/management, reception, department specialists, customer relations and advertising.
- [x] Expand Shopping Tower to nine employees: tower manager, weapons merchant, elixir pharmacist, hospitality manager, chef, waiter/customer service, hotel receptionist, housekeeping supervisor and advertising manager.
- [x] Retain four separate Power Tower employees. Current expected total: 46 persistent tower employees after adding a dedicated advertising manager to the Antiques and Heritage Tower.
- [x] Alternate female and male employee appearances and apply distinct uniform palettes for the Hunter Association, business, shopping, hotel, restaurant, entertainment, technology and Power Tower teams.
- [x] Create 100 persistent customer NPCs in each of the five connected Baghdad towers (500 total), with visible child, elderly and adult character models, wallet data, family/guardian links, visitor schedules and local tower locations. Each tower has 20 children, 20 elderly visitors and 60 adults; children remain civilian-only and their purchases are handled by adult guardians.
- [x] Move visible customer NPCs around tower public lobbies on a periodic local schedule.
- [x] When the player arrives at an authored floor, bring two persistent tower customers into that floor as visitors; update their local society location/action data and let them wander/socialize there, including Shopping Tower dining and hotel floors.
- [x] Return floor visitors safely to their public lobby before the active floor is replaced or the player travels to another tower.
- [x] Simulate NPC purchases from each tower's catalog, deduct customer wallets and shared vendor stock, and persist the local NPC sales ledger. Player purchases continue to use the same tower vendor stock.
- [ ] Expand customer navigation into independently scheduled multi-floor routes, every individual shop/restaurant/hotel room, and persistent queue/seating/room occupancy behaviors; current implementation brings two visitors into the active floor selected by the player.
- [ ] Replace local-only economy and customer records with server-authoritative shared inventory, transactions, anti-duplication and cross-device synchronization before online multiplayer commerce.

## Tower departments and signature amenities
- [x] Add a staffed public cafe and visitor seating lounge to each of the five district tower lobbies; each cafe routes to its tower's NPC staff service and each tower catalog includes cafe drinks/snacks.
- [x] Business Tower: add a purchasable service catalog for company registration, business banking, consultations, office passes, investment certificates, market participation and recruitment listings; add a trading hall, conference center and investor lounge floor builds.
- [x] Shopping Tower: retain the weapons/armour/outfit and Nen/elixir catalogs, forge and elixir laboratory on floor 14, SYSTEM Hotel on floors 27–28, and restaurants/dining on floors 29–32; add the dedicated ninth advertising/marketing employee.
- [x] Entertainment Tower: add ticket products for pools, sport, cinema, bowling, arcade, fitness, spa, family areas and rooftop events; generate pool, gym, sports court, bowling, cinema, arcade, family-zone and rooftop-leisure floor props.
- [x] Technology Tower: expand the catalog for robotics kits, AI compute access, VR simulation, prototype-lab access and diagnostics; generate robotics, AI, VR and rooftop innovation floor props.
- [x] Hunter Association Tower: add training rooms, guild lounge, archive/library, Hall of Honor, Global Council and top-floor Global Headquarters facilities.
- [x] Add swimming movement/physics, water entry/exit and a pool activity loop; pool movement and swim-stroke regression passed Godot validation #1405. [ ] Lifeguard routines and physical Android inspection remain open.
- [ ] Add playable cinema programming, bowling/arcade minigames, full sports matches, live business-market simulation, and hands-on robotics/VR experiences; current additions establish their floor layouts, service points and catalog entries.
- [ ] Complete floor-by-floor furniture, accessible routes, elevators, emergency exits, lighting, sound, staff navigation and visual polish across every tower floor.

## Active-floor customer visits — 22 November 2026

- [x] Add a floor-visit lifecycle for persistent customer NPCs: two customers from the visited tower are moved from its public lobby into the active floor after the elevator arrives.
- [x] Update each visiting customer's local society location, current activity and last-visit timestamp; customer models wander/socialize inside the selected floor.
- [x] Return all floor visitors to their correct public lobby before the previous active floor is removed or a different tower is entered.
- [x] Extend the Godot operations validator to check the Shopping Tower restaurant floor receives two customers, the lobby retains two, and both visitors return safely so all four customers are visible in the lobby again.
- [x] Pass the new floor-visit regression, complete Godot 4.3 import/parser, headless startup, Baghdad landmark checks, and full tower-operations/Power Tower regression on gameplay commit `64422bf2209b8a400a3c92577c305d8ea72a6220` (validation run #1348, 22 November 2026).
- [x] Export the canonical Android APK for this gameplay commit — GitHub Actions build #1085 passed on exact code HEAD `64422bf2209b8a400a3c92577c305d8ea72a6220`; artifact size 35,864,379 bytes; SHA-256 `2a193b85823f89486de2e92fd1fa2ca1230e1ead662c2389a6fc93bae932678f`; expires 6 December 2026.
- Note: this is active-floor visitor behavior, not an autonomous multi-floor schedule or full restaurant seating/room occupancy simulation.

## Validation status for this revision
- [x] Latest room-service commit `54e7ad39ecdc8ecd2076ebb18154dcf9342592d2` passed GitHub Actions Godot validation #1359 and Android APK export #1096.
- [x] Extend the Godot operations validator for the five connected towers plus independent Power Tower, 45 staff, 20 customers, uniform presence, staffed cafes, NPC purchases, pools, cinema, trading hall, AI lab, Hall of Honor, Global Council, Global Headquarters, Shopping Tower forge/lab, hotel and dining.
- [x] Run the complete Godot 4.3 import/parser, main-scene launch, tower landmark and tower operations validators on the latest branch head — passed in GitHub Actions validation run #1343 (22 November 2026).
- [x] Confirm the fresh GitHub Actions Godot validation result is green (run #1348); Android export is a separate pending check.
- [x] Export canonical Android APK for gameplay code revision `393880387de3ac27113943676a4cf9ee8401f29c` — GitHub Actions build #1080 passed; artifact size 35,861,631 bytes; SHA-256 `9b482bd6c91da27299d51b9288e818fa2871ff72cec81781eb8082dc4398c3eb`; expires 6 December 2026.
- [x] Export canonical Android APK for the new active-floor customer visit code revision `64422bf2209b8a400a3c92577c305d8ea72a6220`; GitHub Actions build #1085 passed and uploaded artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,864,379 bytes), expires 6 December 2026.
- [ ] Inspect all five towers on a physical Android device; headless validation and APK export do not replace device-side visual, touch, thermal and performance review.
- [ ] Keep PR #38 as draft and do not merge to main without the user's explicit approval.

---

## SYSTEM Hotel booking gameplay — 22 November 2026

- [x] Add eight persistent room records to the Shopping Tower hotel catalog: four standard rooms, two deluxe rooms, a Hunter Suite (A rank), and an Elite VIP Suite (S rank).
- [x] Add local ConfigFile persistence for reservations, including room identity, guest, nightly rate, booking time, check-in time, check-out time and reservation status.
- [x] Add 1-, 3- and 7-night booking controls with availability checks, rank eligibility and SYSTEM-credit payment.
- [x] Add hotel receptionist interaction controls for booking, guest check-in and checkout; checkout releases the room and refunds unused nights beyond the first night.
- [x] Add validator coverage for reservation payment, check-in state persistence and checkout room release, restoring test wallet/booking fixtures after the test.
- [ ] Hotel booking, room-service orders and housekeeping are functional local-save workflows. Server-authoritative shared room inventory, real-world calendar dates, guest NPC occupancy, autonomous waiter/staff navigation and cross-device synchronization remain future integration work.
- [ ] Run Godot 4.3 parser/import and the updated hotel/Baghdad validators on the exact latest PR head. No fresh green run has been returned by GitHub Actions yet.

## Baghdad public event-board tower map alignment — 22 November 2026

- [x] Replace the obsolete Weapons/Equipment/Elixirs tower entry in the public event-board tower map with Business & Investment Tower.
- [x] Keep Shopping Tower as the sole mapped landmark for retail, weapons, armour, elixirs, restaurants and hotel services.
- [ ] Re-run the complete landmark and operations validators after the final public-board mapping update; the previous CI failure was the stale landmark validator and no fresh green run has yet been observed.

## Correct Baghdad tower count and integrated Shopping Tower — 22 November 2026

- [x] Replace the obsolete standalone Weapons/Equipment/Elixirs landmark with the missing Business & Investment Tower; Baghdad now generates the intended five connected towers: Hunter Association, Business & Investment, Shopping & Commerce, Entertainment & Sports, and Technology & Innovation.
- [x] Keep the 200-floor Power Tower as a separate landmark outside the five-tower district.
- [x] Move weapons, armour, equipment, Nen research and elixir facility metadata onto Shopping Tower; add restaurant, cafe, bakery and hotel/guest-suite department metadata there.
- [x] Update Shopping Tower's floor directory to include weapons/workshops, elixir laboratories, SYSTEM Hotel on floors 27–28, and restaurants on floors 29–32.
- [x] Update the landmark validator to require the five correct connected towers, assert integrated Shopping Tower facility categories, and reject the obsolete standalone weapons tower.
- [x] Update the operations validator to check the Shopping Tower forge/elixir lab, hotel reception/suites and eight staff roles.
- [ ] Run the updated Godot 4.3 landmark and operations validators on the latest branch head. Earlier CI run failed because the old landmark validator still expected the obsolete weapons tower; the validator and landmark manager have since been corrected, but a fresh green run is still required.
- [ ] Verify the complete Android APK export and physical device runtime after the fresh CI run.

## Shopping Tower inventory expansion — 22 November 2026

- [x] Expand the shared Shopping Tower catalog with additional nen stabilization/focus/recovery elixirs, deep-wound treatment, regeneration, antidotes, resistance and rank-gated elite elixirs.
- [x] Add modern sidearms/rifles/shotguns, traditional blades, dual blades, great sword, crossbow, reinforced arrows and war hammer.
- [x] Add armor progression from E through SSS in addition to the existing F–SSS hunter outfit series; rank checks remain enforced by the existing purchase flow.
- [x] Add Iraqi, Arab, international and premium dining choices, bakery goods and specialty coffee to the Shopping Tower food catalog.
- [ ] Validate unique catalog IDs, stock generation, rank restrictions, buy/sell behavior and save/load through Godot 4.3. This is source expansion, not a verified gameplay test yet.

## Baghdad Shopping Tower hospitality and validator alignment — 22 November 2026

- [x] Expand Shopping Tower staffing to eight dedicated NPC roles: tower manager, weapons merchant, elixir pharmacist, hospitality manager, chef, waiter/customer service, hotel receptionist, and housekeeping supervisor.
- [x] Arrange the eight visible lobby staff in a centered formation that fits the expanded roster.
- [x] Keep SYSTEM Hotel inside Shopping Tower floors 27–28: reception/lounge and reservation interaction on floor 27; eight guest-suite doors and suite-booking interaction on floor 28.
- [x] Keep restaurants/dining areas on floors 29–32; the existing food-hall furniture and restaurant catalog remain within Shopping Tower.
- [x] Align the Baghdad tower validator to the five connected towers plus the independent Power Tower; move forge/elixir lab checks to Shopping Tower floor 14 and add hotel/staff assertions.
- [x] Local hotel gameplay now includes persistent room records, availability, 1/3/7-night pricing, rank checks, payment/refund, check-in/check-out, housekeeping/inspection turnover and paid room-service order states. [ ] Server-authoritative shared inventory/payments, real calendar reservations, autonomous guest NPC occupancy/staff navigation and finished room interiors remain open.
- [ ] Run Godot 4.3 import/parser and the full Baghdad tower validator on the latest branch head; then build and test the Android APK. No test pass is claimed yet.


## SYSTEM Hotel inside the Baghdad Shopping and Commerce Tower — 22 November 2026

- [x] Reserve floors 27–28 for the hotel within the existing Shopping Tower: floor 27 reception/lounge and floor 28 guest rooms/suites; restaurant floors remain 29–32.
- [x] Add a hospitality manager staff role and attach hotel reception/booking interaction metadata to both hotel floors.
- [x] Add first-pass 3D reception desk, lounge feature, suite-door visuals, and interaction areas; no separate tower is created.
- [x] Implement local room inventory/availability, reservation, check-in/check-out, pricing, paid room service and persisted booking/order records. [ ] Server-authoritative payment and shared online guest/room persistence remain open.
- [ ] Replace hotel blockout geometry with complete room interiors, beds, bathrooms, lighting, accessibility, fire exits, and staff navigation.
- [ ] Run Godot parser/import, scene interaction, save/load, economy, visual, and Android-device tests. This source change is not runtime-verified yet.

# SYSTEM WORLD — Modern World Completion Tracker

## Baghdad tower mobile combat integration — 22 November 2026

- [x] Instantiate the existing ModernWorldCombatSystem in the live modern-world startup and explicitly bind it to the active player, camera, and progression manager.
- [x] Connect mobile attack, skill-one, skill-two, and dodge signals to real combat actions; ignore combat actions while driving.
- [x] Connect skill one to the existing rank-four Nen Burst, applying its timed damage/defense/movement/cooldown effects before the empowered strike.
- [x] Connect skill two to a charged heavy strike that consumes weapon durability and uses progression/elixir damage bonuses.
- [x] Extend the Baghdad tower operations validator to verify combat-manager creation, player binding, mobile signal wiring, Nen Burst activation, charged strike, and dodge movement.
- [ ] Inspect touch-control placement and combat feedback on a physical Android device; balance hit range, strike damage, and cooldown feel.

This is the acceptance checklist for the modern-world map. The project must not be described as complete, and work must not move to the portal phase, until every required item is implemented, connected, and verified in Godot on the target platforms. A visual placeholder is not accepted as a completed gameplay system.



## Baghdad five-tower district role update — 22 November 2026

- [x] Preserve Business & Investment Tower as one of the five connected towers; weapons, armour, equipment upgrades and all elixirs remain departments inside Shopping & Commerce Tower, not a separate tower.
- [x] Preserve the existing tower site and connected-district membership for this replacement; update its stable landmark ID and the public event-board node mapping together.
- [x] Define the tower's equipment scope: swords, spears, axes, bows, firearms, shields, helmets, armor, combat outfits, and equipment upgrades.
- [x] Define its elixir scope: Nen acquisition, Nen control and ability development, healing, strength, speed, endurance, energy, and rare/legendary elixirs.
- [ ] Build the tower's navigable interior, shops, crafting stations, inventories, purchase/equip flows, elixir recipes, and progression-safe unlock rules.
- [ ] Implement and balance Nen-acquisition/development systems and elixir effects; no elixir or Nen gameplay is claimed to be playable by this landmark metadata.
- [ ] Add server-authoritative inventory, trading, crafting, anti-duplication, and save synchronization before online economy use.
- [ ] Run Godot parser/import, scene startup, interaction, visual inspection, Android performance, and physical-device tests; this role replacement is source-level only until those checks pass.
- Note: the tower remains a procedural exterior landmark and connected-district member. Its actual interior and equipment/elixir gameplay are unfinished. The standalone 200-floor Power Tower remains separate and unchanged.


## Baghdad tower exterior identity and public display coverage — 22 November 2026

- [x] Add a distinct architectural identity pass for the Hunter Association Tower, Business & Investment Tower, Shopping & Commerce Tower, Entertainment & Sports Tower, and Technology & Innovation Tower.
- [x] Add a separate tournament/champion identity detail to the standalone Power Tower without adding it to the connected district.
- [x] Store each landmark's floor count, approximate height, and connected-district membership as node metadata.
- [x] Add the Technology Tower to the Baghdad tower public advertising/champion display node map; all five connected towers and the standalone Power Tower now have explicit node mappings.
- [ ] Verify the new procedural identity geometry in Godot for scale, overlaps, silhouette, collision, readability, river/Tahrir view corridors, and Android rendering cost.
- Note: this pass adds exterior identity blockout meshes and metadata only. No tower interior, elevator ride, shop transaction, equipment equip flow, elixir effect, or live online leaderboard is claimed complete.

## Baghdad tower entrance directory metadata — 22 November 2026

- [x] Attach floor count, approximate height, and connected-versus-standalone status to each tower entrance interaction marker.
- [x] Extend the existing interaction response with a tower directory for Hunter Association, Business & Investment, Shopping & Commerce, Entertainment & Sports, Technology & Innovation, and the standalone Power Tower.
- [x] Explicitly label floor directories as informational until real interior floors and elevator transitions exist; do not imply that selecting a tower entrance grants access to all floors.
- [ ] Replace the text-only directory with a mobile-friendly interactive floor selector and validated elevator transitions after interior scenes and collision-safe arrival points exist.
- [ ] Test entrance targeting and directory readability in Godot and on Android; no physical-device visual test is claimed.

## Baghdad public tower lobby pavilions — 22 November 2026

- [x] Generate an accessible ground-level open lobby pavilion at each of the five connected towers and the standalone Power Tower.
- [x] Add a walkable lobby floor with collision, a canopy, support columns, a directory kiosk, and a visible tower-name sign.
- [x] Add ray-interactable directory kiosks carrying the tower ID, floor count, height, and district membership without registering duplicate map landmarks.
- [x] Route both tower entrance markers and lobby kiosks through the same Arabic tower-directory response; keep the Power Tower floor-request status visible after the directory.
- [ ] Replace pavilion blockouts with detailed architectural lobbies, security/reception, NPC staff, doors, accessible circulation, and real tower-core connections.
- [ ] Implement elevator cars, floor selection, travel transitions, interior floor scenes, emergency stairs, and validated collision/navigation.
- [ ] Verify all lobby geometry and interactions in Godot and on Android; current code is source-level and automated validation is pending.

## Baghdad tower floor zoning and reception blockouts — 22 November 2026

- [x] Define floor zoning for the Hunter Association headquarters, Business & Investment, Shopping/Commerce, Entertainment/Sports, Technology/Innovation, and standalone Power Tower.
- [x] Attach floor zoning data to the tower root, public entrance, and lobby directory kiosk.
- [x] Display the floor ranges and department labels on each lobby's 3D directory sign.
- [x] Add a first-pass reception counter and security-gate frame to each public lobby pavilion, with collision on the counter and gate posts.
- [ ] Turn the reception/security blockouts into staffed, functional access control with faction/rank/permit checks, NPC staff, queues, and accessibility support.
- [ ] Implement floor-specific interior scenes, real elevator travel, stairwells, floor arrival points, and safe return/exit transitions.
- [ ] Validate lobby collision, sign legibility, interaction reach, and mobile performance in Godot and on Android.

## Baghdad enclosed lobby and lift-core blockout — 22 November 2026

- [x] Enclose the public lobby with collidable side walls and split back/front wall sections while preserving a clear walk-in entrance.
- [x] Add a lift-core door visual and collision panel at the back of each lobby; explicitly mark it as a visual-only placeholder.
- [x] Preserve the separate reception counter, security gate, directory kiosk, floor zoning sign, and walkable floor.
- [ ] Cut a real lift-core opening into the tower shell and connect it to safe, navigable interior floor scenes; the current lift door is closed and non-functional.
- [ ] Add glazing, automatic doors, accessibility routes, lighting, interior materials, and detailed architecture after the collision layout is validated.
- [ ] Run Godot interaction/collision traversal and Android visual/performance tests for all six lobbies.

## Current verified repository foundations

- [x] Fourteen city labels and eight district labels per city are defined in modern_world_region_manager.gd; only Baghdad is currently connected to the provisional WGS84 registry anchor, while the other thirteen centers remain prototype-layout coordinates.
- [x] Each city style index generates a distinct original civic landmark silhouette to improve skyline and local identity.
- [x] Ten rural settlement seeds are defined.
- [x] City road strips, plaza markers, green-belt markers, airport/rail visual hubs, and map discovery registration exist.
- [x] Baghdad tower landmarks are created by the region manager.\n- [x] Tower exteriors now include stepped podiums, facade fins and illuminated crowns; the Power Tower adds tournament display blades and concentric arena terraces, while the Hunter Association Tower adds monumental wings and a Hall of Honor display. These remain architectural blockouts; interior arenas, live champion data and playable headquarters rooms are not complete.\n- [x] Power Tower's 200-floor data model now cycles through duel, team, survival, elite-gauntlet and championship challenge profiles, with every tenth floor assigned a boss trial. This is challenge metadata; spawning, playable arena rooms, matchmaking and server-verified rankings remain open.
- [x] City road-tunnel visual prototypes are generated where terrain sampling finds a continuous, sufficiently level land alignment; rejected sites are skipped.
- [x] Rural village anchors are retained and first-pass access-road meshes are generated when a continuous all-land route to a city is found.
- [x] Every resolved district receives batched visual road-grid, sidewalk, and pedestrian-crossing meshes.
- [x] Land-valid city race-circuit prototypes receive outer safety-barrier geometry, curb strips, a start/finish gantry, pit-garage block, and grandstand tiers.
- [x] Airport visual prototypes include passenger halls, terminal wings, apron markings, and control towers.
- [x] Rail visual prototypes include passenger platforms, canopies, concourses, and departure signage.
- [x] Harbor visual prototypes include cargo warehouses, loading aprons, and freight-container yards.
- [x] Terrain-checked access-road meshes are attempted for airports, stations, and harbors; water-crossing candidates are skipped.
- [x] Accepted bridge spans receive visual side railings and marker lights.
- [x] Inter-city corridor prototypes include dashed center and lane-edge markings.
- [x] Generated inter-city highway surfaces now have matching static triangle-mesh collision bodies; this is a source-level implementation and still needs Godot runtime/Android driving-surface validation.
- [x] Generated inter-city corridor segments attempt roadside rest-stop scenery with market, fuel canopy, EV chargers and parking markings on adjacent land.
- [x] City centers attempt elevated boulevard flyover prototypes with ramps, barriers, lane markings and support piers when the alignment remains on land.
- [x] Harbor prototypes receive a waterfront promenade with benches, bollards and signage.
- [x] Procedural city street fixtures now cover the generated boulevard and ring-road corridors, with plaza lantern fixtures.
- [x] A capped pool of 24 shadowless dynamic lights is moved to the nearest street fixtures around the player; fixture meshes use emissive materials.
- [x] Ambient traffic catalog now contains eight visual archetypes per resolved city, up to 112 vehicles for fourteen cities.
- [x] Existing day/night, sky/weather, ambience, terrain, water, forest, mountain, marine, and wildlife managers remain in the project.
- [ ] None of the above has been confirmed by a Godot runtime or Android visual/performance test in this work session.

## City and district completion gates

- [x] Acquire and verify a current BBBike/OSM Iraq snapshot, extract Baghdad Municipality relation 5638803, and export eight boundary-clipped GeoJSON layers with source checksum, ODbL attribution and feature counts (workflow run 44697711925; artifact 14610809943).
- [ ] Complete official-boundary comparison, source-coverage review, road topology/turn connectivity checks, district-boundary sourcing and elevation-data acquisition; only then approve the Baghdad data pack for production use.
- [ ] Extend the WGS84 registry and region projection pipeline to each additional city only when its approved geographic data pack is available; do not promote prototype coordinates to real locations.
- [ ] Replace the 2.24 km × 1.58 km procedural continent prototype with a streamed real-scale region architecture before loading the approximately 36.0 km × 34.1 km Baghdad municipal area.
- [ ] Validate 1 km region-cell streaming, cross-cell roads/water, LOD, collision/navigation streaming, memory and frame-time budgets on Android.
- [ ] Replace generic block clusters with distinctive city architecture, skyline silhouettes, landmarks, local street furniture, signage, vegetation, and cultural details.
- [ ] Build connected, navigable street grids inside every district, including sidewalks, crossings, curbs, intersections, traffic islands, signs, barriers, and collision.
- [x] Add first-pass discoverable service-location definitions for hospitals, police/fire stations, hotels, markets, garages, schools, universities, football stadiums, shopping streets, restaurants, banks, malls, pharmacies, bakeries, cafes, fuel/charging stations, public parks, bus stations, post offices, libraries, rail stations, harbor terminals, cinemas, and fitness centers.\n- [ ] Turn these service-location prototypes into fully functioning interiors, jobs, inventories, transactions, medical/legal services, public transport schedules, and interactive recreation.
- [ ] Add residents, pedestrians, vendors, workers, schedules, crowds, public services, and city activity that responds to time and weather.
- [ ] Make the ten rural settlements functional and connect them to roads, services, farms, orchards, fields, and local economies.

## Global road, bridge, and race gates

- [ ] Complete a continuous, optimized inter-city and rural road graph; current corridor and village-access meshes are visual prototypes and some routes are intentionally skipped.
- [ ] Convert the first-pass tunnel props and urban flyovers into connected, terrain-integrated and collision-tested routes; add complete bridge, overpass, underpass, ramp, coastal-road, mountain-pass, junction, and drainage networks. Bridge railings and marker lights are visual details only.
- [ ] Add road markings, lane graph, traffic rules, traffic lights, pedestrian crossings, speed zones, signs, and collision.
- [ ] Add race circuits, street races, checkpoints, timing, results, rewards, leaderboards, and safe reset/respawn rules.
- [ ] Implement fuel/charging, repair, garages, service stations, towing, parking, and roadside incidents; current rest-stop props are visual only.

## Vehicle completion gates

- [ ] Replace ambient-only movement with lane-aware traffic AI, intersection logic, yielding, parking, emergency dispatch, and traffic-density streaming.
- [ ] Add actual drivable vehicle physics and controls with mobile input, camera modes, suspension, braking, steering, collision, damage, and recovery.
- [ ] Add player vehicle ownership, secure purchase/sale, garage inventory, vehicle persistence, customization, keys, summon/park flow, and recovery.
- [ ] Connect ownership and vehicle state to authenticated accounts and an authoritative multiplayer backend; local save alone is not sufficient for shared-world ownership.
- [ ] Add network interest management so only nearby relevant player vehicles are replicated and rendered.
- [ ] Verify vehicle counts, physics cost, network load, and frame rate at Android quality tiers.

## Global lighting completion gates

- [ ] Extend fixture placement to all secondary streets, alleys, bridges, tunnels, stairways, parks, waterfronts, airports, ports, stations, parking structures, and rural roads.
- [ ] Add building entrances, interiors, apartment windows, shopfronts, signs, billboards, neon districts, traffic signals, headlights, brake lights, and emergency lighting.
- [ ] Use baked/static lighting where suitable, emissive distant fixtures, and a small nearby dynamic-light budget; avoid thousands of shadow-casting realtime lights.
- [ ] Add per-city and per-district lighting profiles, sunset/sunrise transitions, weather/fog response, and wet-road reflections.
- [ ] Validate night readability and performance on low-, mid-, and high-tier Android devices; provide scalable quality presets.

## Transport, ports, and waterways

- [ ] Turn airport and rail visual hubs into usable terminals with routes, schedules, boarding, fares, arrivals, and map integration; current terminal geometry is scenery only.
- [ ] Build ports, docks, marinas, cargo terminals, ferry routes, ship lanes, navigable vessels, and coastal logistics.
- [ ] Add usable passenger/cargo ships, aircraft and trains only after their controls, collisions, route logic, and save/network behavior are implemented.
- [ ] Connect bridges and waterways to the actual continent terrain and validate every crossing.

## World life and environment

- [ ] Complete NPC schedules, needs, jobs, family/social life, local commerce, and crowd behavior without allowing NPCs to perform player-only main quests.
- [ ] Complete regional soundscapes: crowds, markets, engines, horns, river/water, forest insects, birds, aircraft, ships, weather, and interiors.
- [ ] Complete weather effects, wet surfaces, puddles, fog, dust, wind response, climate-appropriate snow, and seasonal changes.
- [ ] Complete wildlife species, animation, habitats, population limits, and player/world interactions.
- [ ] Complete injury services, hospitals, police/jail consequences, reputation, and emergency response.

## Map streaming, mobile performance, and verification

- [ ] Implement region/cell streaming and LOD for geometry, NPCs, traffic, audio, lighting, foliage, and interiors.
- [ ] Define device quality tiers and memory/CPU/GPU budgets.
- [ ] Verify discovery, waypoints, fast travel, transport, collisions, save/load, and world transitions.
- [ ] Run Godot parser checks, scene startup tests, gameplay tests, and Android device tests; fix all errors and regressions.
- [ ] Inspect every city and the inter-city routes in-game, by day and night, on foot and in vehicles.
- [ ] Only after every required gate is checked and the final build is reviewed may the modern-world map be declared complete and portal work begin.

## Honesty rule

A checked repository foundation does not mean a finished gameplay feature. Visual meshes are not drivable vehicles; terminal-shaped meshes are not usable transport; road strips are not a connected road network; fixture meshes are not complete city lighting; and code committed to GitHub is not runtime-tested until Godot actually runs it.

- Added a first procedural mosque landmark pass for Baghdad OSM Muslim worship point amenities, plus one emissive demo billboard prototype per generated city. Live advertising remains disabled pending a secure approved provider integration; polygon mosque coverage and Godot/Android runtime validation remain outstanding.
- Expanded modern-city service prototypes to include schools, university, football stadium, shopping street, restaurant, bank and mall alongside existing hospital, police, fire, hotel, market and garage. Added city service interaction markers, a visible stadium pitch/stands/goals, school courtyards and shopfronts. Functional gameplay and Godot/Android runtime validation remain outstanding.


## Baghdad connected five-tower district plus separate Power Tower — design direction updated 22 November 2026

- [ ] Build the five distinct district landmark towers as one connected vertical urban district spanning central Baghdad's Karkh–Rusafa corridor; build the standalone Power Tower as a separate destination outside that network.
- [ ] Keep the Tigris visibly open and flowing beneath the district; preserve the river channel, riverfront access, navigation clearance, and views.
- [ ] Preserve Tahrir Square and the Freedom Monument as recognizable, explorable public landmarks on the Rusafa side; do not cover, replace, or overwhelm them.
- [ ] Connect the five towers with skybridges, elevated promenades, public terraces, and carefully designed cross-river links while keeping the river unobstructed below.
- [ ] Create a multi-level public district with ground streets/plazas, mid-level shopping and services, and upper sky gardens/recreation decks.
- [x] Implement the five connected district identities: Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation.
- [ ] Keep the 200-floor Power Tower separate, with its own entrance/map marker; exclude it from the five-tower skybridge and vehicle-deck loop.
- [ ] Add accessible pedestrian routes, transit access, emergency/service circulation, wayfinding, and clear public connections to the existing Baghdad street network.
- [ ] Validate the district in Godot from Karkh, Rusafa, Tigris riverfront, and Tahrir Square viewpoints; ensure the Freedom Monument and river remain visually legible.
- Design approval/documentation is recorded in `HUNTER_TOWERS_AND_EXAMINATION_DESIGN.md`. The connected city, bridges, detailed interiors, and river engineering are not yet implemented or runtime-tested; the six-landmark source correction is on a feature branch pending Godot validation.


## Vehicle physics foundation — 20 November 2026

- [x] Add a reusable Godot VehicleBody3D-based vehicle controller prototype with four VehicleWheel3D nodes, chassis collision, suspension setup, keyboard throttle/steering/reverse/brake inputs, and a mobile-control setter API.
- [x] Add a runtime manager that can spawn the first owned/selected vehicle near a dealership in the active modern-world scene.
- [x] Add a first-pass enter/exit flow, hide/disable the player collision while driving, and hand the camera to a vehicle-follow view.
- [x] Route the existing mobile movement joystick to vehicle throttle/reverse and steering; route the existing jump button to a short brake input.
- [ ] Add dedicated on-screen accelerator, reverse, and brake controls with clear driving-mode labels.
- [ ] Tune wheel suspension, traction, braking, mass, collision, and maximum speeds using in-engine driving tests.
- [ ] Test driving on flat roads, slopes, turns, elevated decks, and parking ramps on desktop and Android.
- Note: the controller is now connected through `system_vehicle_runtime_manager.gd` and `main.gd` to a first-pass dealership interaction, owned-vehicle spawning, player handoff, camera follow, and existing touch inputs. This is source-level integration only; it has not been parsed or run in Godot, and no Android driving test was performed.

## Connected Baghdad district — collision and access blockout update — 20 November 2026

- [x] Add static collision shapes matching the generated elevated promenade and vehicle-deck box geometry.
- [x] Add collision shapes to the visual parking-level slabs and parking-ramp deck segments.
- [x] Add a three-level parking-garage blockout with thirty visual parking-bay markings.
- [x] Add two visible vertical-access shaft placeholders for passenger/service lifts.
- [ ] Add actual player vehicle spawning, enter/exit, mobile steering/throttle/brake controls, vehicle physics, and camera handoff.
- [ ] Replace the parking-ramp straight prototype segments with a continuous tested ramp route and safe grade/turn radius.
- [ ] Implement elevator movement, doors, floor selection, emergency controls, and accessible pedestrian paths.
- [ ] Validate all collision surfaces, clearances, ramp slopes, and vehicle handling in Godot and on Android.
- Note: collision-backed decks and parking slabs are source-level additions; no runtime or driving test was run in this update. Lift shafts and parking bay markings remain visual blockout, not interactive systems.

## Baghdad five-tower sky gardens — 24 November 2026

- [x] Add three elevated sky gardens to each of the five connected civic towers (15 total); keep the standalone Power Tower excluded.
- [x] Give each garden four physical collidable deck sections around the tower shaft, preserving central shaft clearance.
- [x] Add transparent perimeter safety rails, four planter beds with soil, four trees, two benches, four path lights and Arabic/English garden signage per garden.
- [x] Add an interactable garden trigger with the owning tower ID, garden level and corresponding tower-floor metadata.
- [x] Extend `validate_baghdad_towers.gd` to check all fifteen gardens, floor collisions, railings, landscaping, seating and floor interaction metadata.
- [ ] Run canonical Godot validation and Android APK export on the exact updated PR head; do not mark the gardens runtime-verified until both workflows pass.
- [ ] Connect the garden floor metadata to confirmed elevator destination routing and add living garden activities/NPC routines; current implementation is a physical geometry and interaction prototype.

## Connected Baghdad district — vehicles and public life — 20 November 2026
- [x] Record the five connected district identities: Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation; keep Power Tower separate.
- [x] Expand the separate Power Tower progression model to 200 floors; playable interiors, opponent encounters, and server-verified records remain open.
- [x] Add an initial procedural five-tower district blockout with elevated promenade/vehicle-deck link geometry and ramp-segment placeholders; add the separate Power Tower landmark outside that connection loop.
- [x] Add placeholder public amenity deck geometry and a planned facility inventory for recreation, hospitality, shopping, health support, parking, and emergency access.
- [ ] Implement validated drivable ramp paths, vehicle physics, lane widths, slope limits, collision barriers, traffic rules, and safe merges from Baghdad streets.
- [ ] Implement parking garages, vehicle elevators/ramps, drop-off points, pedestrian crossings, and service/emergency circulation.
- [ ] Expand beyond the current local gameplay prototypes: water-park/amusement-park systems, complete hotel room interiors, full restaurant seating/service, cinema programming/playback, complete sports matches, and public-facility life simulation remain open. The fifteen physical sky-garden decks are tracked separately below.
- [ ] Position and validate the full district against the real in-game Tigris corridor, Karkh/Rusafa geography, Tahrir Square, and the Freedom Monument; preserve river navigation and protected landmark sightlines.
- [ ] Run Godot parser/editor/runtime checks and inspect the five-tower blockout in-game before calling this milestone validated.
- Note: the checked items above indicate repository geometry/documentation was added, not that vehicles can already drive on the decks or that the amenities are playable.


## Vehicle runtime integration — 20 November 2026

- [x] Add `system_vehicle_runtime_manager.gd` to spawn an owned vehicle near a dealership in the active world.
- [x] Connect the manager to the player, camera, spring arm, local garage manager, and active world from `main.gd`.
- [x] Route mobile joystick input to vehicle throttle/reverse and steering while driving; route the existing jump touch button to a brief brake.
- [x] Add first-pass enter/exit, player visibility/collision handoff, and vehicle-follow camera behavior.
- [ ] Add a dedicated driving HUD with accelerator, reverse, brake, and exit controls.
- [ ] Verify dealership proximity, spawn placement, camera restoration, wheel orientation, suspension, collision, and player recovery in Godot.
- [ ] Test desktop and Android driving, including city streets, slopes, bridges, elevated tower decks, and parking ramps.
- Note: the runtime manager and main-scene connections are committed source code, not verified gameplay. Godot parser, scene startup, and device tests have not been run; the existing jump button temporarily doubles as brake while driving.


## Vehicle showroom and garage UI — 20 November 2026

- [x] Add a responsive in-game vehicle showroom panel listing the current catalog, vehicle categories, prices, and ownership state.
- [x] Display the player's local vehicle-credit balance and report insufficient funds without completing a purchase.
- [x] Connect purchase and selection actions to the existing local garage manager and its save file.
- [x] Add a resale action using the garage manager's existing resale calculation and active-vehicle protection.
- [x] Connect the selected owned vehicle to runtime spawning and the first-pass enter/drive flow.
- [x] Add a return-to-garage action for a parked vehicle when the player is near a dealership.
- [x] Make showroom panel dimensions adapt to the current viewport and refresh its world-root reference after world changes.
- [ ] Replace prototype credits with the intended authenticated, server-authoritative economy before any shared-world or real-money use.
- [x] Add a procedural 3D vehicle-preview blockout to the showroom, with body, cabin, wheels, lighting, and a preview floor.
- [x] Add five paint-color choices and persist each owned vehicle's selected paint locally in the garage save.
- [x] Apply the saved paint to the spawned drivable vehicle and update its material when the player changes paint.
- [ ] Replace the generic preview blockout with distinct high-detail vehicle models and accurate category-specific proportions.
- [x] Expand the catalog with premium, luxury, supercar, electric-performance, and off-road vehicle classes, using clearly marked unlicensed brand-class references.
- [x] Add dedicated motorsport catalog classes for GT, formula single-seater, endurance prototype, drift, rally, drag, and track hypercar vehicles.
- [ ] Add test-drive mode, purchase confirmation, and a dedicated driving HUD with accelerator, reverse, brake, and exit controls.
- [ ] Verify UI layout, purchase/save/load, selling, spawning, enter/exit, and mobile touch behavior in Godot on Android.
- Note: the showroom and garage actions are source-level integrations committed to GitHub. Ownership and credits still use the existing local prototype save; no Godot parser, runtime, or Android test has been run. Vehicle previews and dedicated driving controls are not included yet.


## Vehicle 3D preview and paint customization — 20 November 2026

- [x] Add an in-showroom 3D preview scene with a procedural body/cabin/wheel blockout, camera, lighting, and floor.
- [x] Add blue, red, black, white, and gold paint swatches.
- [x] Save a separate paint color for each vehicle in the local garage configuration.
- [x] Apply saved paint when a vehicle is spawned and apply paint changes to the currently spawned vehicle.
- [ ] Replace the generic blockout with final distinct vehicle assets, materials, glass, lights, interiors, and correct proportions for each catalog entry.
- [ ] Add preview rotation/zoom, vehicle-specific paint options, and visual damage/customization.
- [ ] Validate SubViewport rendering, UI fit, paint persistence, and material updates in Godot on Android.
- Note: this is a procedural preview blockout, not a final vehicle model. Paint and ownership are stored locally on the device; no Godot parser, runtime, or Android validation has been performed.


## Global automotive market and motorsport catalog — 20 November 2026

- [x] Expand the vehicle catalog beyond basic city transport to include premium executive sedans, grand tourers, supercars, electric performance cars, and off-road 4x4s.
- [x] Add a broad international-market direction with manufacturer-class references spanning Mercedes-Benz, BMW, Audi, Aston Martin, Bentley, Ferrari, Lamborghini, McLaren, Tesla, Porsche, Lucid, Toyota, Land Rover, Jeep, Bugatti, and Koenigsegg.
- [x] Add dedicated race inventory classes: GT3 circuit, formula single-seater, endurance prototype, drift, rally, drag, and track hypercar.
- [x] Mark brand references as unlicensed placeholders; no official manufacturer endorsement, trademark license, or authentic brand asset is claimed.
- [ ] Obtain the required manufacturer/trademark permissions for official branded vehicles, logos, liveries, and authentic models before release.
- [ ] Create distinct high-detail vehicle models, interiors, lights, sound, handling, damage, and category-specific previews for every class.
- [ ] Build racing systems: licensed/fictional championships, circuits, qualifying, laps, timing, pit stops, penalties, AI opponents, multiplayer races, and rewards.
- [ ] Balance prices, unlock requirements, progression, and availability through the intended shared economy.
- Note: catalog metadata and vehicle class entries are source-level foundations only. They do not yet provide authentic manufacturer models, completed racing gameplay, or validated driving physics.


## First-pass motorsport event framework — 20 November 2026

- [x] Add a reusable motorsport manager with event definitions for city sprint, GT championship, formula grand prix, endurance, drift, rally, and quarter-mile drag.
- [x] Validate that the selected event exists, the player owns the entered vehicle, and its catalog class is eligible for that discipline.
- [x] Add ordered checkpoint registration, lap progression, elapsed-time tracking, finish/cancel flow, and race lifecycle signals.
- [x] Add a local prototype wallet reward method and connect event completion to its fixed participation reward.
- [x] Instantiate the motorsport manager from `main.gd` at startup and provide the existing player garage manager.
- [ ] Connect race event selection and physical race routes to the active world; instantiate real start/finish gates and checkpoint Area3D nodes.
- [ ] Build race tracks and route geometry for circuits, drag strips, drift arenas, rally stages, and endurance layouts.
- [ ] Add countdowns, false-start detection, lap timing UI, position tracking, AI competitors, penalties, pit stops, damage rules, and reset/respawn handling.
- [ ] Add event menus, qualifying, championships, seasonal events, leaderboards, multiplayer synchronization, anti-cheat validation, and server-authoritative rewards.
- [ ] Validate all event flows and rewards in Godot and on Android.
- Note: the manager is instantiated by the main game script, but this is still a source-level race lifecycle/checkpoint foundation only. No track/checkpoint nodes, race UI, or AI opponents are built, and rewards remain local-device prototype currency.


## Dedicated motorsport, illegal street racing, and police response — 20 November 2026

- [x] Restrict purpose-built race-class vehicles to dedicated track context in the vehicle runtime manager; spawning or entering GT, Formula, endurance, drift, rally, drag, and track-hypercar vehicles is rejected outside an approved track context.
- [x] Require dedicated-track context before a sanctioned motorsport event can start.
- [x] Clarify that the City Sprint Cup is a closed, sanctioned city circuit, not racing on open public roads.
- [x] Define player-versus-player wager rules as fictional SYSTEM credits only; wager creation remains disabled until authenticated multiplayer escrow, server authority, anti-cheat, and dispute handling exist.
- [x] Add a police-report entry point for unsanctioned street-racing incidents, witness report metadata, wanted-level escalation, and dispatch of a police pursuit toward the reported vehicle.
- [x] Add a first-pass police-arrival response that stops the reported illegal-racing vehicle and records the incident.
- [ ] Build physical dedicated motorsport venues with access gates, paddocks, garages, pit lanes, spectator areas, and track-zone trigger volumes that call the track-context API.
- [ ] Build a separate illegal street-racing activity using road-legal street cars, hidden meetups, rival crews, witness detection, escape routes, police roadblocks, pursuit navigation, arrest/impound, fines, reputation loss, and repeat-offender consequences.
- [ ] Connect police reports to actual active player vehicles and multiplayer participants; current report API requires the race activity to explicitly submit its target vehicle.
- [ ] Implement secure server-authoritative player-to-player wager escrow, opt-in consent, limits, settlement, refunds, anti-collusion and dispute handling; no real-money betting.
- [ ] Run Godot parser, scene integration, AI pursuit, vehicle stopping, and Android tests before treating any of these features as playable.
- Note: the changes are source-level foundations only. No track trigger volumes or playable race venues have been built, the crime manager does not yet automatically detect street races, and the new police response has not been runtime-tested. The dedicated-track context setter must be connected to future physical track zones.


## Baghdad International Motorsport Park blockout — 20 November 2026

- [x] Add a procedural first-pass motorsport venue manager for the modern world.
- [x] Create a 32-segment oval-style circuit surface with static road collision, inner guide line, and safety barriers.
- [x] Add a basic paddock with eight garage bays, pit lane, and simple spectator grandstands.
- [x] Add an approved-track Area3D zone; entering/exiting with the player toggles the dedicated-track context in both vehicle runtime and motorsport managers.
- [x] Integrate the venue manager into modern-world startup from main.gd.
- [ ] Replace procedural blockout meshes with detailed track art, curbs, runoff zones, pit buildings, race control, lighting, signage, and crowd assets.
- [ ] Add track-specific layouts and validated checkpoint transforms, starting grids, finish lines, timing sectors, and track marshal posts.
- [ ] Add track access gates, garage selection, race registration UI, spectator events, and AI competitors.
- [ ] Verify player collision layer/mask and test entering/exiting the Area3D in Godot; run parser and Android performance tests.
- Note: the venue is a source-level procedural blockout, not a finished or tested playable race track. The track zone is a broad access volume around the venue and currently toggles permission; the racing manager still needs actual checkpoint nodes and event registration integration.


## Baghdad motorsport start grid and checkpoint route — 20 November 2026

- [x] Add a visible start/finish gantry and four-lane starting-grid markings to the Baghdad circuit blockout.
- [x] Add four ordered checkpoint trigger areas around the oval route, with visible checkpoint gate markers.
- [x] Connect vehicle-body checkpoint entry to the existing motorsport manager's ordered checkpoint/lap/timing lifecycle.
- [x] Add a track event start API that requires the player to be inside the approved venue, actively driving an owned vehicle, and positioned near the start grid; event and vehicle-class validation remains delegated to the motorsport manager.
- [ ] Build a registration/menu interaction that lets the player choose an eligible event and call the track start API in-game.
- [ ] Add countdown, false-start detection, timing sectors, race HUD, restart/retire flow, AI competitors, and spectator/event presentation.
- [ ] Validate checkpoint collision masks, checkpoint order, lap completion, and start-grid placement in Godot; run Android driving tests.
- Note: this update adds source-level track geometry and trigger-to-manager integration. It is not yet a fully playable race event: there is no in-game event-selection UI or countdown, and no Godot parser/runtime or Android test has been run.


## Baghdad residential and worship fabric — 20 November 2026
- [x] Classify OSM building footprints as low-rise detached houses, apartment/residential blocks, commercial buildings, mosques, churches, or general buildings where source tags permit.
- [x] Use OSM height/level tags when present and add conservative category-specific fallback heights when they are absent.
- [x] Preserve OSM feature identity and attach a building-type metadata label for future interaction and district systems.
- [x] Add first-pass roof markers for polygon worship buildings and distinct point-landmark blockouts for Muslim mosques and Christian churches.
- [ ] Audit the Baghdad OSM cell pack coverage for houses, apartment blocks, building levels, mosques, churches, and all worship-place polygons; report missing or untagged features rather than fabricating exact real locations.
- [ ] Build complete Baghdad neighborhood logic: residential/commercial/mixed-use zoning, street hierarchy, blocks, alleys, sidewalks, courtyards, parking, utilities, and public spaces.
- [ ] Turn residential buildings into enterable, multi-floor structures with apartments, stairs, elevators, doors, furniture, lighting, utilities, and safe navigation.
- [ ] Add house/apartment ownership, purchase/rent, household residents, family schedules, maintenance, and neighborhood services.
- [ ] Refine Baghdad mosque and church models using locally appropriate architectural references, distinct building scales, courtyards, entrances, and interiors while preserving religious respect and accessibility.
- [ ] Connect worship places and residential blocks to the city map, discovery, pedestrian navigation, and NPC daily-life schedules.
- [ ] Validate all building geometry, collisions, streaming, performance and visuals in Godot and on Android; source-level tags and blockouts are not runtime-verified.

## Baghdad OSM building discovery interaction — 20 November 2026

- [x] Attach world-interaction metadata to the collision body of each streamed OSM building footprint so the existing camera ray interaction manager can resolve the building as an interactable target.
- [x] Preserve the OSM feature ID and building classification on the collision body; assign a stable per-feature discovery ID, Baghdad region ID, non-fast-travel location type, and an Arabic display label that prefers the source name when available.
- [x] Keep this as a discovery/information interaction only. It does not claim that the building has a usable door, accessible interior, apartment floor plan, ownership, rent, inventory, or NPC residents.
- [x] Cross-check the Baghdad region ID against `ModernWorldRegionManager.register_map_locations`: building discovery now uses the same `region_baghdad` key as the registered Baghdad city map entry. Runtime discovery registration still requires Godot verification.
- [ ] Add actual entrance/door placement, entrance approach points, interior scenes, apartment/shop use cases, and save-backed discovery state after the interaction flow is runtime-validated.
- [ ] Run Godot parser, scene startup, ray-interaction, cell unload/reload, and Android performance tests; none were run for this source update.

## Baghdad building discovery details and map positioning — 20 November 2026

- [x] Calculate an approximate footprint-center position from each streamed building polygon and store it as discovery metadata, including terrain elevation at that point.
- [x] Store source-derived building height and a clearly estimated floor count (height divided by the configured 3.2 m floor heuristic); these are estimates, not surveyed floor data.
- [x] Update the existing interaction manager to register the stored footprint position instead of the collision body's origin, so discovered building markers are not all registered at world origin.
- [x] Show a short building inspection readout after interaction: display name, classification, estimated floors, estimated height, and an explicit note that interiors/access are not implemented.
- [ ] Improve the readout presentation for mobile screens and verify it with the actual HUD layout.
- [ ] Validate polygon-center quality for concave/irregular footprints; current arithmetic vertex average is an approximation and may not lie inside every footprint.
- [ ] Implement real entrance locations and enterable interiors only after reliable entrance data/placement and runtime validation are available.
- [ ] Run Godot parser, map registration, interaction, UI, streaming, and Android performance tests; none were run for this source update.

## Baghdad road-side building approach markers — 20 November 2026

- [x] Build OSM road meshes before building interaction markers so the same cell's tagged road geometries can inform an approach estimate.
- [x] For each polygon building, find the nearest tagged highway segment to its approximate footprint center, then project that road-side point onto the closest polygon edge and offset a small distance outward.
- [x] Create a visible, interactable approach marker only when a tagged road is within the configured 40 m search radius; register it as a normal discoverable location, never as a fast-travel point.
- [x] Store the approach distance, building category, estimated height and estimated floor count; the existing inspection readout is shown when the approach marker is used.
- [x] Label the prompt as an approximate frontage/approach inspection. This is not a verified architectural entrance, door, sidewalk, accessible route, or permission to enter.
- [ ] Validate approach positions against actual Baghdad building frontage, sidewalk widths, gates, walls, courtyards, and road-side geometry; the current nearest-road heuristic can be wrong.
- [ ] Add entrance nodes only from verified entrance data or manually authored building-specific placements, then connect them to real interior scenes and access rules.
- [ ] Run Godot parser, ray-target selection, collision, map discovery, cell streaming/unloading, and Android performance tests; none were run for this source update.

## Baghdad source-mapped entrances — 20 November 2026

- [x] Extend the OSM extraction workflow with a dedicated entrance-node layer sourced from node tags `entrance`, `door`, and `building=entrance`; preserve source OSM IDs and selected access/accessibility tags.
- [x] Add the entrance layer to boundary clipping and the 200 m metric cell-pack generator. Point features are assigned to their containing cell and remain in the same local coordinate frame as buildings and roads.
- [x] Add runtime loading for entrance points, with a visible interactable marker and stable discovery ID derived from the OSM feature ID. The marker is only emitted for mapped point features; no synthetic door is placed when source data has no entrance node.
- [x] Show mapped entrance type, source access tag, and wheelchair tag when the player interacts. Unknown accessibility remains explicitly unknown.
- [x] Keep the interaction honest: a mapped entrance point is not a built door mesh, verified building-to-door association, openable door, interior scene, or permission to enter; private/no access tags are surfaced as restricted.
- [x] Add a GitHub Actions cell-pack assertion that every emitted entrance feature is a Point with a source entrance/door/building tag.
- [x] Run the updated OSM workflow successfully (run 44736344496; artifact 14629100933): the Baghdad boundary clip contains 188 mapped entrance points, and the initial 5×5 / 200 m sample cell pack contains 30 entrance points. This confirms source coverage in the sample, not that every building has a mapped entrance.
- [ ] Associate entrance nodes with their correct building footprints and building IDs using spatial/topological validation; the current runtime marker is independently discoverable.
- [ ] Build door visuals, access checks, enter/exit transitions, interiors, floors, and apartment/shop functionality only after source-to-building associations and scene integration are validated.
- [x] Canonical Godot 4.3 validation workflow 44736373468 passed project import/script parsing and headless main-scene launch after the entrance-loader changes; project validation workflow 44736373505 also passed.
- [x] Android debug APK workflows passed: canonical SYSTEM WORLD build 44736373661 (artifact 14628179091), SYSTEM WORLD export 44736373583 (artifact 14629175553), and SYSTEM build 44736373546 (artifact 14628741580).
- [x] Follow-up canonical build 44736784123 downloaded the new successful entrance-enabled OSM pack (source run 44736344496; artifact 14629100933), installed all 25 sample metric cells into the project, passed the Baghdad OSM runtime-cell validation, and exported APK artifact 14628622619.
- [ ] Run entrance-specific ray-target, location discovery, cell boundary/unload, and marker-to-building association tests; inspect the APK on a physical Android device. A successful APK export is not a physical-device gameplay test.


## Evidence-based entrance association tooling — 20 November 2026

- [x] Added `tools/geospatial/associate_baghdad_entrances.py` to analyze the generated metric OSM cell-pack ZIP and associate source entrance nodes with OSM building footprints.
- [x] Reassembles building polygon fragments split across multiple 200 m cells before measuring entrance distances; this avoids incorrectly treating a clipped cell fragment as the full building footprint.
- [x] Produces explicit accepted, review, restricted, and rejected outcomes with OSM IDs, distances, source tags, candidate ambiguity information, and summary counts. The tool does not generate or claim an unverified physical door.
- [x] Preserves access restrictions: `access=no/private` is reported as restricted, and explicit `entrance=no` / `door=no` points are rejected as non-entry points.
- [x] Added unit tests for contained entrances, ambiguous neighboring buildings, private access, and no-nearby-building rejection in `tools/geospatial/test_associate_baghdad_entrances.py`.
- [ ] The association report has not yet been run against the latest Actions artifact in this session; test execution and report output remain pending.
- [ ] The report is not yet consumed by `baghdad_osm_cell_streamer.gd`; runtime door/interior transitions remain unimplemented. Do not mark mapped entrances as enterable until that integration and its Godot tests pass.

Run from `SYSTEM-WORLD/` after installing the same Shapely dependency used by the cell-pack generator:

```bash
python tools/geospatial/associate_baghdad_entrances.py --pack path/to/baghdad-cell-pack.zip --output reports/baghdad-entrance-associations.json
python -m unittest discover -s tools/geospatial -p 'test_associate_baghdad_entrances.py' -v
```


## Advertising media and public champion displays — 20 November 2026

- [x] Add the design and implementation acceptance specification at `REAL_WORLD_ADVERTISING_AND_CHAMPION_DISPLAY_SYSTEM.md`.
- [x] Define facade-mounted billboards, rooftop LED panels, skyscraper media ribbons, shopfront, transit, stadium, and Baghdad five-tower display placements.
- [x] Define protected placement rules for entrances, traffic/emergency signage, the Tigris, Tahrir Square, and the Freedom Monument.
- [x] Separate curated in-world campaign content from real paid advertising; require provider approval, privacy/consent safeguards, moderation, opt-out, fallback, and platform/legal review before live ads.
- [x] Specify verified public-result displays for monster-gate clears, missions, Power Tower events, and Hunter Examination qualifiers/finalists/winners.
- [x] Specify authoritative verification, anti-cheat, privacy-safe display names, provisional-versus-final status, and a Hall of Honor archive.
- [ ] Implement facade anchor metadata, actual 3D screen meshes/materials, campaign rotation, and distance-based LOD in Godot.
- [ ] Implement the authoritative verified-event-results service and connect it to gates, missions, Power Tower, and Hunter Examination.
- [ ] Integrate a real advertising provider only after approvals, consent/privacy review, moderation, and platform compliance.
- [ ] Run Godot parser/scene checks and Android performance tests for screen count, texture memory, animation, brightness, and night visibility.
- Note: this commit records the requested system specification and required work; it does not mean live ads, public leaderboards, or event boards are already running in the game.


## City advertising skyscrapers and public champion boards — 20 November 2026

- [x] Add `scripts/system_public_event_board.gd` as a shared 3D display manager for the modern-world city map.
- [x] Replace the previous detached demo billboard routine with a procedural skyscraper facade in each configured city, carrying a curated advertising panel and a separate public event-results panel.
- [x] Add facade-mounted advertising and results panels to the five connected Baghdad towers plus the standalone Power Tower: Hunter Association, Business & Investment, Shopping, Entertainment, Technology, and Power.
- [x] Connect completed monster-gate clears to publish gate rank, gate ID, and XP to the public boards.
- [x] Connect verified mission-reward events to the public boards.
- [x] Connect Hunter Examination stage completion and final license-earned signals to the public boards.
- [x] Connect Power Tower floor-clear events to the public boards.
- [x] Persist the most recent 40 local-session event records in a user config file and show the latest four on every city/tower results display.
- [x] Keep the advertising mode explicitly curated/demo; live commercial ads remain disabled until a compliant provider/backend, consent, moderation, privacy and legal review are implemented.
- [ ] Implement server-authoritative cross-player champion rankings, global winner history, anti-cheat validation and privacy controls; current records are local to the player's device/session and are not a global leaderboard.
- [x] Godot 4.3 project import/script parsing, missing-resource scan, and headless main-scene launch passed in GitHub Actions run 44741267042 on commit `efb156486d857c1a842fcbfb9278b3453923fd80`.
- [ ] Validate facade orientation, screen readability, night brightness, occlusion, LOD, memory and Android frame rate on physical devices.
- [ ] Complete Android APK export workflow and inspect the generated build on a device.
- Note: CI confirms project parsing and headless scene startup, not visual correctness, gameplay feel, or physical-device performance. Local event records are not cross-player global rankings; an authoritative online service remains required.


## Mountain cave passage blockout — 21 November 2026

- [x] Add `scripts/modern_world_cave_passage_manager.gd` for the four existing mountain cave sites without moving their coordinates or changing the continent.
- [x] Generate a walkable passage floor with static collision, side-wall collision, an arched ceiling mesh, and a larger inner chamber floor.
- [x] Tag each generated passage as a cave landmark and mark it explicitly as geometry blockout requiring runtime validation.
- [ ] Add validated entrance-to-building association, proper terrain excavation, complete chamber wall/ceiling collision, cave lighting, audio, navigation, discovery persistence, and player interaction.
- [ ] Run Godot parser/import, scene startup, collision traversal, and Android performance tests. The new geometry is committed source code and has not yet been run in Godot or on a device.

## Baghdad tower lobby Godot validation — 22 November 2026

- [x] Godot 4.3 resource import and GDScript parse passed on branch commit `f97aebce63ac06076bb622f5c0b32a619e3a3b81` in GitHub Actions run [45035625980](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45035625980).
- [x] Runtime scene missing-mesh scan and headless main-scene launch passed in the same run.

- [x] Add a dedicated Godot SceneTree validation script and CI step for six tower landmarks, exactly five connected towers, Power Tower separation/200 floors, lobby collision/kiosks/signs, floor zoning, weapon/elixir categories, and Technology public-display mapping.
- [x] First structural validation exposed that the original Shopping Tower plot had no nearby land inside the initial 192 m search radius; widen the local land search and relocate the Shopping Tower to the nearest generated land point.
- [x] Re-run the structural validation successfully on commit `9f32efa09e64a51e5ff807b5634430ce2af5e4c7`, GitHub Actions run [45035977040](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45035977040): all six towers were generated, five remain connected, Power Tower remains separate at 200 floors, all six lobby kiosks/floor directories exist, and Technology is present on the public event board.
- Note: the Shopping Tower plot was relocated by 264 m, Power Tower by 96 m, and Technology Tower by 48 m in this runtime layout. Godot visual review must confirm the final positions remain coherent with the Baghdad district, Tigris corridor, and protected Tahrir Square/Freedom Monument views.

- [x] Canonical SYSTEM WORLD Android APK export and artifact upload passed on the same code commit in GitHub Actions run [45035977001](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45035977001).
- [ ] Install and inspect that APK on a physical Android device; export success does not establish mobile visual quality, touch interaction, collision traversal, or frame-rate performance.

- [ ] Visual review of the six tower lobbies, collision traversal, kiosk ray targeting, sign readability, and Baghdad landmark sightlines remains pending; headless launch does not verify visual quality or gameplay interaction.
- [ ] Canonical Android APK export and physical-device review remain pending for the current branch head.



## Baghdad tower operations, NPC workforce, commerce, interiors and Power Tower runtime — 22 November 2026

Implementation added on the feature branch; automated runtime validation is pending.

- [x] Add system_baghdad_tower_operations_manager.gd and connect it to the canonical main scene.
- [x] Generate four persistent civilian NPC employees for each of the six Baghdad towers (24 staff total): tower-specific service roles plus a dedicated advertising manager. Staff identity and employer/location data are stored in the existing NPC society records.
- [x] Add visible, ray-interactable employee characters in each public lobby. Interacting with an employee opens the relevant service panel.
- [x] Add local-session player credits, persistent wallet storage, NPC-supervised purchase transactions, inventory item grants, and sale of owned inventory items back to tower staff.
- [x] Add initial catalogs for weapons, armour, shields, Nen/elixir items, shopping supplies, entertainment tickets, technology devices, and Hunter supplies.
- [x] Add rotating NPC-managed advertising text to internal lobby displays and external tower advertising displays; each tower's advertising manager is identified in the campaign label.
- [x] Add on-demand procedural interior floor rooms for all six towers, with floor collision, perimeter walls, department signage, service kiosks, and elevator return markers.
- [x] Add an elevator travel transition between the lobby and selected floor; generated floor rooms are unloaded when leaving to limit mobile memory/render cost.
- [x] Keep Power Tower progression independent and sequential across 200 floors; the operations manager requests the next floor through the existing progression manager.
- [x] Add a reusable Power Tower opponent actor with health, pursuit movement, close-range attacks, and damage handling compatible with the modern combat raycast.
- [x] Spawn opponent waves from each floor's challenge data; boss floors spawn a stronger boss opponent. Completing the final wave calls the existing trusted floor-clear integration hook and awards the configured XP/rank.
- [x] Generate distinct first-pass arena obstacle layouts from duel, team, survival, elite, championship, and boss-trial floor profiles; floor 200 is configured as a boss trial.
- [x] Abandon an active Power Tower attempt without crediting a clear if the player is wounded; return the player to the lobby for hospital treatment.
- [ ] Pass the new Godot 4.3 operations validator and inspect any runtime errors from the current CI run.
- [ ] Review the generated interiors, NPC models, elevator movement, arena combat and mobile frame rate in a physical Android build.
- [ ] Expand the generic procedural floor rooms into individually authored, themed floors with complete department-specific activities and interactive furnishings.
- [ ] Add actual equipment/equip slots and balanced, functional Nen/elixir effects; current purchases are inventory items only and do not yet grant combat/stat effects.
- [ ] Add crafting recipes/stations, upgrade materials, stock refresh, NPC vendor restocking, and supply-chain/economy simulation.
- [ ] Replace the local wallet with server-authoritative currency, inventory, trade validation, anti-duplication and cloud save before enabling online trade or real-value purchases.
- [ ] Connect advertisements to a governed campaign system with campaign ownership, pricing, moderation, display scheduling, and any future revenue accounting. Current campaigns are local in-game display content, not paid external ad inventory.
- [ ] Build authoritative online matchmaking, player rankings, anti-cheat verification and multiplayer spectator systems for Power Tower. Current floor records and rewards use the existing local save path.
- Note: the current commit implements a playable first-pass systems layer and generated floor geometry, not a production-complete commercial economy or 200 individually handcrafted arena scenes. The PR remains draft and must not be merged into main without explicit user approval.


### Elevator cabin and Power Tower final sovereign trial extension — 22 November 2026

- [x] Add a visible elevator cabin with floor/roof panels, glass side walls, sliding doors and an animated car/player transition between lobby and selected tower floor.
- [x] Allow the floor directory/elevator marker inside a generated floor to reopen the floor selector; the player can choose another floor or return to the lobby.
- [x] Keep only the active generated floor room loaded during normal tower traversal; free the cabin after a return to the lobby.
- [x] Mark Power Tower floor 200 as the unique FINAL_BOSS/SYSTEM SOVEREIGN trial, with a distinct large gold boss visual, stronger health profile, shockwave attack, special arena platform and completion reward.
- [x] Add Power Tower loot items: routine tokens, milestone fragments, boss cores, and the unique sovereign crown/core reward on floor 200.
- [x] Ensure floor 200's level requirement is 90, within the existing 100-level player cap.
- [x] Pass the latest CI run covering elevator cabin travel/return, final boss metadata/rewards, NPC staff, trading and ads (Godot workflow #1479).
- [ ] Inspect elevator camera clearance, cabin door alignment, player landing/collision and floor-room visibility on a physical Android device.
- [ ] Complete individual arena art, final boss attack telegraphs/animations, boss phase changes, reward balance, online leaderboard verification and spectator/matchmaking features.


### Equipment, elixir and Nen first-pass functionality — 22 November 2026

- [x] Add persistent weapon, shield, armour, helmet and outfit equipment slots.
- [x] Apply equipped weapon damage bonuses to the existing light/heavy combat hitscan.
- [x] Apply equipped shield/armour/helmet defense bonuses to incoming combat damage, with a bounded reduction so attacks cannot become zero-damage.
- [x] Add timed strength, speed, endurance, energy and rare/legendary elixir effects to damage, movement, defense and attack cadence.
- [x] Add healing elixir field recovery while preserving the existing persistent wounded state; a healing elixir cannot replace hospital treatment.
- [x] Add Nen acquisition unlock and control rank progression (rank 1–5) through the corresponding elixirs.
- [x] Add NPC employee service controls to equip owned gear, consume owned elixirs, unequip items and prevent sale of currently equipped gear.
- [x] Pass current Godot validation for progression save/load, combat integration and the extended tower/elevator transaction validator (Godot workflow #1479).
- [ ] Add visible 3D weapon/armour attachment models, weapon-specific attack animations, shield blocking integration, and real Nen abilities/aura techniques.
- [ ] Add elixir crafting, ingredient sourcing, recipes, cooldown/stacking rules, balance and anti-exploit validation.


### NPC vendor economy, crafting stations and final Power Tower challenge — 22 November 2026

- [x] Add persistent vendor stock by product, stock-sensitive buy/sell prices, restocking every five real-time minutes and stock persistence.
- [x] NPC vendors reduce stock on purchase and take player items back into stock on sale.
- [x] Add the Weapons Tower blacksmith and elixir laboratory benches, each linked to its assigned NPC employee service.
- [x] Add recipe-based crafting for swords, spears, axes, bows, shields, armour, helmets, outfits, healing/strength/speed/endurance/energy elixirs and Nen/rare elixirs.
- [x] Add raw material purchasing and Power Tower milestone/boss material drops to support crafting.
- [x] Add interactive service kiosks on public tower floors and interactive lift doors in all six lobbies.
- [x] Add a Power Tower lobby progress board showing cleared floors and the 200-floor target.
- [x] Add final-boss shockwave warning and three combat phases; floor 200 also grants a unique crown, sovereign core, rare core, Nen fragment and bonus SYSTEM credits.
- [x] Pass the newest CI run after the vendor stock, crafting-station and lobby-lift extensions (Godot workflow #1479).
- [ ] Add visual weapon/armour attachments, weapon-specific animations, real Nen abilities, crafting discovery/upgrade/repair systems and physical Android interaction/performance review.
- [ ] Add online/server-authoritative wallet, vendor stock, player leaderboard and multiplayer Power Tower matchmaking; current economy/progression/records are local.


### Power Tower challenge objective pass — 22 November 2026

- [x] Survival arena floors now run timed survival objectives with sequential enemy waves; surviving until the timer ends clears the floor.
- [x] Championship arena floors now require clearing all waves before their time limit; failure abandons the attempt and leaves the same floor available for retry.
- [x] Arena signage displays the active objective and live countdown; the timer begins only after the elevator reaches the floor.
- [x] Automated validator checks every floor from 1 to 200 for valid level gates, boss cadence, wave counts, rewards and timed objective profiles.
- [x] Latest Godot 4.3 validation workflow passed on the current tested source revision, including all tower, NPC commerce, crafting, equipment/elixir/Nen, elevator and Power Tower checks.
- [ ] Latest Android APK export workflow is still running; physical Android visual/touch/performance review remains outstanding.


- [x] Power Tower lobby board now shows the player's highest cleared floor, next floor, progression rank, completion percentage and personal best clear time. This is a local personal record, not a global online leaderboard.


### Equipment durability, upgrades and repair — 22 November 2026

- [x] Equipment durability decreases when weapons are used and armour/helmets absorb hits; shields wear while actively blocking.
- [x] Broken equipment stops contributing its damage/defense bonus until repaired.
- [x] NPC employees offer equipment upgrades through +10, with level and material costs; higher upgrades require rare cores and Nen control rank.
- [x] Repair kits can be purchased or crafted; the NPC repair service restores equipment durability.
- [x] Player inventory displays equipped item upgrade levels and durability.
- [x] Latest Godot 4.3 validation passed after durability/upgrade/repair integration.
- [x] Latest canonical Android debug APK export passed at HEAD \`3646251e0d9834e885d845656bb52e92a8fc1c12\`; artifact \`SYSTEM-WORLD-canonical-android-debug-apk\` expires 6 December 2026.
- [ ] Physical Android device gameplay/touch/performance review remains pending.


### Nen awakening elixir and Hunter Association strike demonstration — 22 November 2026

- [x] Rename the player-facing item and crafting recipe to **إكسير إيقاظ النِن**; it awakens Nen and is not an attack or combat skill.
- [x] Preserve existing saves by migrating the old `nen_acquisition_elixir` inventory key to `nen_awakening_elixir`; the old item ID remains accepted by the consume method for compatibility.
- [x] Keep the actual Nen strike as a separate combat ability. The Hunter Association Tower now exposes a dedicated training-demo entry, with a visual preview before awakening and the real strike after Nen reaches control rank 4.
- [x] Keep the Nen awakening elixir, equipment and crafting laboratory inside Shopping & Commerce Tower; the Nen strike demonstration belongs to the Hunter Association Tower.
- [x] Run the updated Godot validator and canonical Android APK export; physical-device touch/visual review remains pending.
- Note: the pre-awakening preview is a visual training effect only; it does not unlock Nen, consume an item, or deal damage. The real combat strike still uses the existing combat system and its normal rank/cooldown requirements.

### Baghdad tower interior identity pass — 22 November 2026

- [x] Add a dedicated reusable floor-theme builder for the five connected Baghdad towers.
- [x] Give Shopping & Commerce Tower a forge, equipment-display and elixir-laboratory department identity.
- [x] Give the Shopping Tower retail display, market and visitor-rest areas.
- [x] Give the Entertainment/Sports Tower event, fitness and audience-area visual identity.
- [x] Give the Technology/Innovation Tower robotics, test-platform and data-lab visual identity.
- [x] Give the Hunter Association Tower mission, training, registry and Hall-of-Honor visual identity.
- [x] Attach stable floor-theme metadata and department labels to generated rooms; preserve on-demand floor generation and single-active-room memory behavior.
- [x] Extend the Godot operations validator to require a distinct theme root and themed station props on each of the five connected tower floors.
- [ ] Run the latest Godot 4.3 validator and Android APK export on the new commit; inspect any failures before claiming the theme pass validated.
- [ ] Replace the current themed visual blockouts with finished art, fully interactive department activities, staff schedules, and physical-device visual/performance verification.
- Note: this pass adds tower-specific visual identity and department set dressing. It does not claim that every floor has unique hand-authored geometry or that the displayed stations are all independently playable.

### Godot validator correction — 22 November 2026

- [x] Investigate the first tower-theme validation run. The new validator incorrectly required the five connected Baghdad department themes on the separate Power Tower.
- [x] Keep the five-department theme assertion scoped to the five connected Baghdad towers.
- [x] Validate the independent Power Tower against its own arena challenge display and arena metadata instead.
- [x] Re-run Godot validation and Android export on this corrected commit; both passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Hunter Association rooftop helicopter landing pad — 22 November 2026

- [x] Add a dedicated rooftop helicopter landing pad physically attached to the Hunter Association Tower; it is not a sixth tower and is not part of the standalone Power Tower.
- [x] Add a circular landing deck, static deck collision, painted landing circle and H marking, eight perimeter lights, identity sign, and a collision-backed access bridge to the tower roof.
- [x] Tag the facility with its Hunter Association owner ID and an explicit landing-zone radius for future helicopter runtime integration.
- [x] Extend the Baghdad tower Godot validator to check pad ownership, deck/collision, markings, sign, bridge collision, and all eight perimeter lights.
- [x] Pass Godot 4.3 parsing, headless scene startup and the extended tower validator on the current PR head.
- [x] Attach a dedicated Hunter Association helicopter runtime controller to the pad; generate a parked helicopter model with animated main/tail rotors.
- [x] Add pilot enter/exit flow, keyboard flight inputs, on-screen mobile ascend/descend/directional controls, and camera follow while piloting.
- [x] Add approach-distance interaction, a defined 18 m landing radius, low-speed landing state, and exit restriction while airborne.
- [x] Require completion of all Hunter examination stages before allowing helicopter pilot access; unlicensed players receive a clear denial message.
- [x] Add a physics-space shape query before each flight movement step to block movement into collidable world geometry.
- [x] Pause the on-foot player movement loop while piloting so the character controller cannot fight the aircraft controller.
- [x] Expose pilot authorization in the runtime status for automated verification.
- [x] Track simultaneous touch-button presses independently so releasing one direction does not cancel another held direction.
- [x] Pass Godot 4.3 parsing, headless startup and the expanded helicopter runtime validator on PR head `8edf22ac6551c9668e1e5da17c2a466bf06b06b7`.
- [x] Pass canonical Android APK export on the same PR head; artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,802,382 bytes) uploaded successfully.
- [ ] Add robust aircraft body collision, terrain-aware flight physics, emergency landing, aircraft parking persistence and flight safety validation.
- [ ] Review rooftop approach clearance, touch layout, camera behavior, collision traversal, lighting and Android performance on a physical device.
- Note: this is a first playable flight prototype using scripted movement and a procedural helicopter blockout. It is not yet a production aircraft physics model, and membership permissions and obstacle collision are still pending.


### Hunter examination continuity — 22 November 2026

- [x] Fix the active-exam resume branch: a saved in-progress examination now returns its current stage instead of incorrectly rejecting the player as already registered.
- [x] Prevent a fully completed examination from reopening with `exam_active = true`; completed candidates receive the explicit `ALL_STAGES_COMPLETED` result.
- [x] Extend the Baghdad tower operations validator to test both active-exam resume and completed-exam closure.
- [x] Correct the helicopter pilot-authorization lookup and validator to use the actual runtime node name `SYSTEMHunterExamManager`, discovered by the first regression run.
- [x] Pass the updated Godot 4.3 validator and canonical Android APK export on the latest PR head (Godot #1479 / Android #1216).
- [ ] Test the full seven-stage examination, app restart/resume, license persistence, and pilot-permission unlock on an Android device.


### Power Tower entry safety and progression gates — 22 November 2026

- [x] Prepare the selected floor room and elevator cabin before reserving an active Power Tower challenge, preventing a failed room/cabin setup from leaving the progression manager locked on an active floor.
- [x] Add automated progression regression checks for sequential floor access, player-level requirements, duplicate active-floor requests, and rejection of clear reports for floors that were never activated.
- [x] Pass Godot 4.3 parser, complete Baghdad tower operations validator, and canonical Android APK export on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.
- [ ] Verify the full 200-floor progression, save/reload continuity, boss floors, rewards and failure/abandon recovery through extended automated gameplay tests and Android device testing.


### Baghdad tower interaction prompt alignment — 22 November 2026

- [x] Update the in-world tower interaction prompt: the floor selector and elevator travel are available, while unfinished tower services/interior details remain explicitly marked as in development.
- [x] Pass the latest Godot operations validation and canonical Android APK export after the Hunter exam, Power Tower and prompt updates on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Hunter examination regression fixture correction — 22 November 2026

- [x] Correct the automated test fixture to use a typed empty stage-ID array when switching from the completed-candidate test profile back to the unlicensed profile; this prevents stale completed-stage data from contaminating the helicopter authorization assertion.
- [x] Re-run the full Godot operations validator and Android export on the corrected head; both passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Hunter helicopter authorization test isolation — 22 November 2026

- [x] Explicitly mark the helicopter regression-test profile as unregistered after the completed-exam regression case, so the negative pilot-authorization test cannot inherit the prior candidate's completed-stage state.
- [x] Re-run Godot 4.3 operations validation and canonical Android export on the isolated test profile; both passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Helicopter flight-loop regression coverage — 22 November 2026

- [x] Extend the Godot operations validator to grant a test-only completed Hunter license, enter the aircraft, verify player-control handoff, command takeoff, command a controlled landing inside the pad radius, and verify safe exit restores on-foot controls.
- [x] Capture the player's prior physics-processing state when boarding and restore that exact state on exit instead of assuming it was always enabled.
- [x] Pass the Godot 4.3 flight-loop regression test on commit `999431189fa50161d09f6cd95e964b4596e510d4`.
- [x] Pass canonical Android APK export on the same tested source head; artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,805,824 bytes) uploaded successfully.
- [ ] Perform physical Android touch-control, rotor/clearance, flight feel, and performance testing; automated headless checks do not replace device inspection.


### Mobile-responsive Baghdad tower operations UI — 22 November 2026

- [x] Resize the tower operations panel to the current viewport, keeping it centered and bounded for phone portrait and landscape layouts.
- [x] Recalculate panel dimensions when the viewport changes orientation or size.
- [x] Add automated sizing assertions for 360×780 portrait and 780×360 landscape viewports.
- [x] Pass Godot 4.3 parsing, full Baghdad tower operations validation and responsive-size assertions on UI source commit `b5bcf4b04bdd45888874d0b4591c8f7668f7ec90`.
- [x] Pass canonical Android APK export on the same UI source head; artifact `SYSTEM-WORLD-canonical-android-debug-apk` (35,806,414 bytes) uploaded successfully.
- [ ] Inspect the actual panel on the HONOR 50 after installation, including portrait/landscape layout and scrolling.


### Responsive panel viewport API correction — 22 November 2026

- [x] Use Viewport.get_visible_rect().size from the Node-based operations manager; get_viewport_rect() belongs to Control/CanvasItem and is not available on this Node.
- [x] Re-run Godot parser, responsive-size assertions, full tower operations validator and Android APK export; all passed on PR head `d3b92ded6a95a444f23c5bb849529af4e586d467`.


### Latest verified PR-head CI — 22 November 2026

- [x] Godot 4.3 import/parse, headless main-scene startup, Baghdad tower landmark/lobby validation, and tower interior/NPC commerce/advertising/Power Tower boss-arena validation passed on `d3b92ded6a95a444f23c5bb849529af4e586d467` (workflow run `45047696991`).
- [x] Canonical Android debug APK export and upload passed on the exact same PR head (workflow run `45047696994`); artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,802,758 bytes, expires 6 December 2026.
- [ ] Physical Android device testing remains outstanding; automated CI does not verify touch feel, visual alignment, frame rate, or real-device stability.


### Hunter Association helicopter parking persistence — 22 November 2026

- [x] Save the helicopter's parked local position and orientation to the local Godot user profile when the pilot safely exits after landing.
- [x] Restore the saved parked transform when the Hunter Association helicopter controller is initialized after an app restart.
- [x] Keep boarding anchored to the aircraft's actual saved parking location and place the pilot on detected ground beside the aircraft after landing, including emergency landing away from the rooftop pad.
- [x] Pass the extended Godot regression for re-boarding at the saved location and safe nearby exit placement on tested source HEAD `a0ddf2497f4137eab3c5fc25d97afe55d34b38d8` (Godot run `45053166540`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,810,487 bytes, expires 6 December 2026 (Android run `45053166565`).
- [x] Reject malformed saved transform values and out-of-bounds parking coordinates, falling back to the designated rooftop spawn.
- [x] Extend the Baghdad tower operations validator to save a test parking transform, reload it, and assert that the parked position is restored.
- [x] Expand swept-position clearance checks to cover the fuselage/tail boom, the full main-rotor disc, and the tail rotor instead of checking only the center body.
- [x] Pass Godot 4.3 parsing, headless startup, full Baghdad tower operations validation, helicopter parking position/orientation persistence, controlled emergency landing, and main-rotor obstacle-clearance regression on tested source HEAD `5253e8a5becbfc5745a95b13f82f2c58111d11a7` (workflow run `45052867549`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,810,354 bytes, expires 6 December 2026 (workflow run `45052867541`).
- [ ] Verify parking persistence across a real Android app force-close/relaunch cycle; CI uses an isolated test profile and does not prove device persistence.
- Note: this is local-device parking persistence only. It does not synchronize the aircraft location between online players or across devices.


### Power Tower full progression and save/reload regression — 22 November 2026

- [x] Extend the Godot operations validator to simulate sequential requests and confirmed clears for all 200 floors using a level-100 test profile.
- [x] Verify that each floor can only be requested after the previous floor has been cleared and that every clear writes its personal clear-time record.
- [x] Instantiate a fresh progression manager after the 200-floor run and verify that floor 200, completion status, and all 200 clear-time records reload from the saved profile.
- [x] Pass the full 200-floor progression and save/reload regression on tested source HEAD `ad479c3704bd9f9955f908007dff07681c93a307`; the Godot validator completed successfully (workflow run `45053457072`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,812,958 bytes, expires 6 December 2026 (workflow run `45053457094`).
- [x] Add a final-boss regression that checks the sovereign boss transitions through all three health phases and registers defeat.
- [x] Exercise the operations manager's final-floor clear integration and verify that the sovereign crown/core, rare core, Nen fragment, SYSTEM credits, and floor-200 completion record are granted; restore the validator's original local profile afterward.
- [x] Pass the sovereign final-boss three-phase/defeat regression and final reward integration on tested source HEAD `8d37b28105c5f52a8a2b2b5f44de35e45012919f` (Godot run `45053818855`).
- [x] Pass canonical Android APK export on the same tested source HEAD; artifact `SYSTEM-WORLD-canonical-android-debug-apk`, 35,815,543 bytes, expires 6 December 2026 (Android run `45053818923`).
- [x] Add validator coverage for survival-timer completion, championship timeout abandonment without a clear, and wound-triggered active-floor abandonment/recovery.
- [ ] Pass the extended survival/championship/abandon regression on the latest PR head; physical Android gameplay review remains outstanding.


### Hunter rank ladder and helicopter high-rank authorization — 22 November 2026

- [x] Establish the official hunter grade order from F through E, D, C, B, A, S, SS and SSS, with SSS as the highest and exceptionally rare grade.
- [x] Permit A/S/SS/SSS hunters to use the Hunter Association helicopter without the separate level-50 threshold; F–B grades do not qualify by rank alone.
- [x] Extend the Godot validator to check denial for F–B and authorization for A/S/SS/SSS.
- [x] Investigate the latest Godot CI failure: the validator declared progression twice in the same function scope. Rename the later shopping-test reference to avoid the duplicate declaration.
- [ ] Re-run Godot validation and canonical Android APK export on the corrected rank-authorization commit.
- [ ] Implement and validate the full multi-stage rank-award board, including exceptional SSS evaluation; the ladder and helicopter gate alone do not constitute a completed promotion system.
- [ ] Connect association NPC pilot staffing/flight automation; current authorization is evaluated for the player character.


### Hunter Association rank progression board — 22 November 2026

- [x] Add an entry to the Hunter Association tower menu for the official F-to-SSS rank board.
- [x] Display the player's current rank, verified mission points/count, Nen awakening/control rank, Nen skill-use count, and distinct abilities.
- [x] Show the progression requirements for F, E, D, C, B, A, S, SS, and SSS; clearly state that SSS requires exceptional Hunter Association Board approval and cannot be self-awarded.
- [x] Extend the Baghdad operations validator to open the Hunter Association menu and assert that the rank-board entry and progression rows are generated.
- [x] Run Godot 4.3 import/parse, the full Baghdad tower operations validator, and canonical Android APK export on the latest branch head (Godot #1479 / Android #1216).
- [ ] Implement the separate multi-stage SSS examination/board decision workflow; the current board is a transparent progress display, not the final SSS approval workflow.


### SYSTEM Hotel housekeeping turnover — 22 November 2026

- [x] Preserve checked-out room records as occupied by housekeeping instead of releasing them immediately.
- [x] Add persisted room states: `needs_cleaning`, `cleaning`, and `ready`.
- [x] Add staff controls to start housekeeping, then complete cleaning and record the room inspection.
- [x] Keep rooms unavailable for new bookings until cleaning and inspection pass.
- [x] Extend the Godot operations validator to cover checkout, cleaning-state transition, inspection, and room re-availability.
- [x] Run Godot 4.3 validation and canonical Android APK export on the updated PR head; both results confirmed in #1479/#1216.
- Note: housekeeping workflow is a local-save prototype. Staff navigation/animation and online shared hotel occupancy remain future work.


## Arcade physical target detection correction — 22 November 2026

- [x] Investigate Godot validation run #1397 on PR source HEAD `e552608b342ad8257d2d410dfdb2704b7c57d86b`: the arcade projectile passed within 1.4101 m of the nearest target, but the 0.95 m proximity fallback and 0.7 m sensor radius did not register a hit.
- [x] Increase the physical target sensor radius to 1.25 m and the near-hit fallback to 1.6 m, retaining the rigid-body projectile and target-sensor scoring path.
- [x] Commit the correction as `ae8c7a633ce5636d4fa5edc87f50e4a97be3d988` on the Baghdad feature branch only.
- [x] Re-run the full Godot 4.3 validation on corrected HEAD `8e3cbfce9b8184239ed2481c1043d6c8ce9075ae`; workflow run #1400 (`45065179104`) passed, including the complete Baghdad operations validator and arcade physics assertion.
- [x] Confirm Android export on the same corrected HEAD; workflow run #1137 (`45065179082`) passed and uploaded APK artifact `14771151265` (35,892,247 bytes; APK SHA-256 `b99558deef44b5d1bb9991444a01013990df08d44efc7cb4fb7e9c4b91d0e01a`).
- [ ] Inspect the new APK on a physical Android device; automated CI does not replace touch, visuals, collision feel or performance testing.
- Note: the preceding Android export #1134 succeeded on `e552608b342ad8257d2d410dfdb2704b7c57d86b`, but the Godot operations run #1397 failed only at the arcade hit assertion. Neither result validates this correction.


## Latest Baghdad recreation physics verification — 22 November 2026

- [x] Validate the pool water-volume trigger, player swim state, buoyancy and swim-stroke input on the latest branch head.
- [x] Validate the bowling lane collision body, ten rigid-body pins, physical ball throws, pinfall detection and completed ten-attempt activity loop.
- [x] Validate basketball rigid-body throws, hoop scoring sensor and the five-shot activity loop.
- [x] Validate five arcade target sensors, projectile collision detection, target identity and the five-attempt activity loop after widening the target sensor to resolve the measured near-miss.
- [x] Run the full Godot 4.3 validation against exact branch commit `8e3cbfce9b8184239ed2481c1043d6c8ce9075ae`: workflow run ID `45065179104`; all import/parser, headless startup, Baghdad landmark, tower operations and activity regression steps passed.
- [x] Export the Android debug APK from the same exact commit: workflow run ID `45065179082`; export and artifact upload passed. APK artifact `14771151265`, 35,892,247 bytes, SHA-256 artifact digest `07749131fc4c959c367aa172b602a7a30055c0387a942b809e48dad71da07cae`, expires 6 December 2026.
- [ ] Physical Android playtest remains required; automated headless checks do not verify touch feel, visual quality, thermal load or device frame rate.
- [ ] Full ten-frame bowling bonus scoring, complete team sports matches, licensed/original cinema programming and playback, full arcade cabinet gameplay, animated robotics construction and immersive VR remain open.


## Latest Baghdad tower regression and Android export — 22 November 2026

- [x] Pass Godot 4.3 workflow #1405 (run ID `45065608679`) on tested source commit `976ffdf2a2b92dede330b617303ab847ae07c878`: resource import/parser, child-character safety checks, missing-mesh scan, headless main-scene launch, Baghdad tower landmark/lobby validation, and the full tower operations validator all succeeded.
- [x] Pass canonical Android export workflow #1142 (run ID `45065608699`) on the same tested source commit; APK artifact `14770903782`, size 35,891,965 bytes, uploaded successfully and expires 6 December 2026.
- [x] Confirm the only commit after the tested source (`06bb0ce4a3a7c7608f6ebd313274dd4e5c84992f`) changes this tracker documentation only; no gameplay source files changed after the tested code snapshot.
- [ ] Physical Android inspection remains outstanding; automated CI does not prove touch feel, visuals, thermal behavior or frame rate on the user's device.
- [ ] Remaining gameplay scope includes full ten-frame bowling bonus scoring, complete team sports matches, cinema programming/playback, full arcade cabinet gameplay, animated robotics construction, immersive VR and full NPC navigation.


### Ten-frame bowling scoring and rack-state implementation — 22 November 2026

- [x] Replace the simplified one-ball-per-frame counter with standard ten-frame play: two rolls per frame, strike completion, spare completion and tenth-frame bonus rolls.
- [x] Keep fallen pins down between rolls in the same frame; reset the full rack only when a frame ends or a tenth-frame bonus rack is earned.
- [x] Calculate official bowling score from the roll history, including strike and spare bonuses; cap the game at the legal 21-roll maximum.
- [x] Add deterministic scoring regressions for a perfect 300 game, a zero-pin game and ten consecutive spares (150 points).
- [x] Pass the full Godot 4.3 validator #1421 (run `45066697522`) and Android export #1158 (run `45066697476`) on exact PR head `02cf161b75e3bd51afb3d924c40060ba588a6244`; physical device feel remains outstanding.
- Note: physical Android lane feel, ball control and real-device collision response still require device playtesting.


### Bowling validator scope correction — 22 November 2026

- [x] Diagnose Godot #1410 parser failure: the bowling completion assertion referenced `final_activity_result` outside its activity-loop scope.
- [x] Move the bowling completion requirement into the per-activity validation scope and count physical results before breaking on the completed final throw.
- [x] Re-run Godot 4.3 full validation and canonical Android export on the corrected bowling implementation; both passed in #1421/#1158.


## Latest full Baghdad tower verification — 22 November 2026

- [x] Pass Godot 4.3 validation #1421 (run ID `45066697522`) on exact PR head `02cf161b75e3bd51afb3d924c40060ba588a6244`, including parser/import, headless launch, landmark/lobby checks and the complete Baghdad tower operations validator.
- [x] Pass canonical Android export #1158 (run ID `45066697476`) on the same exact PR head; APK artifact `14771543150`, 35,903,207 bytes, uploaded successfully and expires 6 December 2026.
- [x] Confirm the bowling 10-frame scoring engine, strike/spare bonus calculations, tenth-frame bonus rolls, physical pin rack persistence and all three deterministic score regressions are included in the validated source.
- [x] Confirm the Shopping Tower restaurant dine-in tables, paid multi-item orders, chef/waiter order lifecycle and local save/load regression are included in the validated source.
- [ ] Physical Android touch, collision feel, visuals, thermal load and frame-rate inspection remain outstanding.


### Basketball 1v1 match loop — 22 November 2026

- [x] Upgrade the five-shot basketball activity into a ten-possession 1v1 match with alternating player and AI-opponent shots.
- [x] Make both player and opponent shots use physical rigid-body balls and the same hoop scoring sensor; track player/opponent scores separately.
- [x] Add match result calculation (win/draw/loss) and small fair completion bonuses for wins/draws.
- [x] Extend the operations validator to complete a full ten-possession match and assert both scores plus a valid final result.
- [x] Pass Godot 4.3 full validation #1428 (run `45067209969`) and canonical Android export #1165 (run `45067210032`) on exact PR head `b6b8fabaacc89dc3a65ce8347a69832811f70c7d`.
- Note: this is a local single-player 1v1 prototype; online multiplayer, team roster rules, fouls and full tournament scheduling remain future work.


### Cinema original-scene programming — 22 November 2026

- [x] Add three original SYSTEM story scenes to the cinema screen with distinct titles, descriptions and lighting palettes.
- [x] Advance the visible scene as the cinema session progresses and validate each scene title/screen update.
- [ ] Actual video playback, licensed media pipeline, seat booking and scheduled showtimes remain open; the current feature is an original storyboard-style scene progression, not a movie player.

### Basketball 1v1 and cinema progression verification — 22 November 2026

- [x] Pass Godot 4.3 validation #1428 (run ID `45067209969`) on exact PR head `b6b8fabaacc89dc3a65ce8347a69832811f70c7d`; the full tower operations validator includes the ten-possession basketball match and cinema scene progression checks.
- [x] Pass Android export #1165 (run ID `45067210032`) on the same exact PR head; APK artifact `14771728504`, 35,906,678 bytes, uploaded successfully and expires 6 December 2026.
- [ ] Physical Android device testing remains outstanding.


### SYSTEM ARCADE score-and-lives game — 22 November 2026

- [x] Expand the physical target activity into a ten-shot arcade round with three lives; the game ends after ten shots or when lives are exhausted.
- [x] Score five targets by difficulty (outer targets 5, inner targets 8, center target 12) and award a capped combo bonus for consecutive hits.
- [x] Persist score, hits, best combo, remaining lives and distinct targets hit in the completed activity result and local activity statistics.
- [x] Add deterministic scoring tests for center hits, capped combo bonuses and invalid target IDs; extend the physical validator to run the ten-shot game.
- [x] Pass Godot 4.3 full validation #1432 (run `45067580400`) and canonical Android export #1169 (run `45067580289`) on exact PR head `40fcf61c87244fab825e96aab27c419c30d0ea95`.
- Note: this is a playable physical target mini-game; full cabinet-specific games, animated cabinet controls and online leaderboards remain open.


### SYSTEM ARCADE gameplay verification — 22 November 2026

- [x] Pass Godot 4.3 validation #1432 (run ID `45067580400`) on exact PR head `40fcf61c87244fab825e96aab27c419c30d0ea95`; full tower operations tests include ten physical projectile shots, five target sensors, lives, combo tracking and score helper regressions.
- [x] Pass canonical Android export #1169 (run ID `45067580289`) on the same exact PR head; APK artifact `14772500063`, 35,908,010 bytes, uploaded successfully and expires 6 December 2026.
- [x] Verify deterministic target score values (5/8/12/8/5), capped combo bonus, invalid target rejection and completion on ten shots or life exhaustion.
- [ ] Physical Android controls, cabinet-specific game variety and online leaderboards remain open.


### Animated robotics assembly prototype — 22 November 2026

- [x] Add a persistent three-part robot assembly display (base, torso and arm module) to the Technology Tower robotics lab.
- [x] Animate each part into its assembly position with eased position, scale and rotation tweens as the player completes each of the three build steps.
- [x] Restore the completed robot display on later lab visits using the locally saved completed-activity record.
- [x] Extend the tower operations validator to require all three parts to be visible and marked assembled after the robotics activity.
- [x] Run Godot 4.3 full validation and canonical Android export on this animated assembly change; both included in #1479/#1216.
- Note: this is a local procedural assembly prototype; interactive component wiring, robot behavior programming and autonomous robot tasks remain open.


## Five-tower elevator regression and swim impulse validation — 22 November 2026

- [x] Extend the Baghdad tower operations validator to travel to floor 2 in each of the five connected district towers (Hunter Association, Business & Investment, Shopping & Trade, Entertainment & Sports, Technology & Innovation).
- [x] For each tower, assert the active floor metadata, elevator cabin alignment with the destination floor, completion of the player's elevator lock, and cleanup/return to the lobby.
- [x] Record the actual upward swimming impulse at the moment the player requests a stroke, so collision resolution after move_and_slide() does not erase the evidence needed by the regression assertion.
- [x] Validate the swim impulse is registered at 2.6 m/s and that the swim state is cleared after leaving the pool.
- [x] Pass Godot 4.3 validation workflow #1479 (run ID 45075559321) on PR merge commit 814b30146cc5da89083b64bdbea102604a94db31, including import/parser, headless launch, all Baghdad landmarks/lobbies, five-tower floor travel and complete tower operations checks.
- [x] Pass canonical Android export workflow #1216 (run ID 45075559263) on source commit a5c44974a5175fcd208bebaa8a295b91310d4f0d; APK artifact 14774657998, 35,938,599 bytes, uploaded successfully and expires 6 December 2026.
- [ ] Physical Android device inspection remains outstanding; automated CI does not verify touch feel, visuals, collision feel, thermal load or frame rate.


## Latest full Baghdad towers validation and Android export — 22 November 2026

- [x] Confirm all five connected district towers load their landmarks and lobby systems.
- [x] Confirm floor-2 elevator travel, cabin/floor alignment, transition unlock and return cleanup across all five district towers.
- [x] Confirm the full operations validator passes, including tower interiors, staff/customer populations, NPC commerce, advertising, hotel/restaurant workflows, leisure activities and the independent 200-floor Power Tower boss arena.
- [x] Pass Godot 4.3 validation workflow #1479 (run ID 45075559321) on PR merge commit 814b30146cc5da89083b64bdbea102604a94db31.
- [x] Pass canonical Android export workflow #1216 (run ID 45075559263) on source commit a5c44974a5175fcd208bebaa8a295b91310d4f0d; APK artifact 14774657998, 35,938,599 bytes, expires 6 December 2026.
- [ ] Physical Android testing remains outstanding, including touch response, visuals, collision feel, frame rate and thermal behavior.


### Baghdad VR course physical collision regression — 23 November 2026

- [x] Give the VR simulation floor, exit sensor, three checkpoint sensors and four hologram obstacle colliders explicit stable node names.
- [x] Validate the VR floor, exit platform, arrival sensor, checkpoint sensors and obstacle bodies as real BoxShape3D collision shapes with expected dimensions.
- [x] Pass full Godot 4.3 validation #1519 (run ID 45082994135) on exact PR source HEAD 5d2f11b435baa5ba0fc983fe61d68b15d0767860; all Baghdad tower operations, VR course, NPC commerce, hotel/restaurant workflows, activities and Power Tower regressions passed.
- [x] Pass canonical Android APK export #1256 (run ID 45082994136) on the same exact source HEAD; APK artifact 14777863471, 35,966,995 bytes, SHA-256 7273f78c882e6b195f6368ad23d752e9e80fce71e2d82110d9abb59bf91d4ea0, expires 6 December 2026.
- [ ] Physical Android interaction and visual inspection remain outstanding.

### Companion orientation safety — 23 November 2026

- [x] Replace the companion's tree-dependent look_at() call with look_at_from_position() so Miyar and Adam can orient safely during setup/reparenting.
- [ ] Re-run Godot runtime validation to confirm the startup Node not inside tree warning is gone.


### Remaining startup orientation safety — 23 November 2026

- [x] Replace the vehicle follow camera and police pursuit tree-dependent look_at calls with look_at_from_position, matching the companion safety fix.
- [ ] Confirm Godot runtime startup and the full tower validator no longer emit Node not inside tree warnings on the latest branch head.

- [x] Fix the vehicle showroom SubViewport camera, which was calling look_at() before being attached to its viewport tree; use look_at_from_position() instead.


### Baghdad tower exterior glazing pass — 23 November 2026

- [x] Add a dedicated MultiMesh glass-window layer to every floor of the five district towers and the independent Power Tower.
- [x] Distribute 20 exterior glazing panels around each floor, following the tower shaft taper and accent lighting.
- [x] Extend the tower operations validator to assert the correct window count for all six towers, valid mesh resources and exterior transforms.
- [ ] Godot 4.3 full validation and Android export for the facade pass are pending.

### SceneTree orientation and full tower regression — 23 November 2026

- [x] Pass full Godot 4.3 validation #1522 (run ID 45083924507) on source HEAD d7d174cc21d2e0bb0c7adbb94ffc62ccf7268439; tower operations passed and runtime log contained zero Node not inside tree warnings.
- [x] Pass canonical Android export #1259 (run ID 45083924528) on the same source HEAD; APK artifact 14778229274, 35,967,083 bytes, SHA-256 f590967987150f59fc46fcae491f59793264b0ef864aa334810e3b7f14edcf71, expires 6 December 2026.

- [x] Make facade layout QA deterministic in Godot headless mode by asserting the generated window count, floor/segment metadata and panel dimensions instead of relying on dummy-renderer MultiMesh transform readback.
- [ ] Re-run Godot and Android workflows after the headless facade validator adjustment.


### Baghdad facade correction — verified on current PR head — 23 November 2026

- [x] Correct the headless facade-layout validation so it checks deterministic per-floor window count, segment/floor metadata and BoxMesh dimensions without reading renderer-only MultiMesh transforms.
- [x] Pass the complete Godot 4.3 workflow #1526 (run ID 45084505558) on exact PR head `5b1f8f84910263fda0c4e112c3def77c8779d48d`; resource import/parser, child-character restrictions, missing-mesh scan, headless main-scene startup, Baghdad landmarks/lobbies and the complete tower operations validator all passed.
- [x] Pass canonical Android export #1263 (run ID 45084505537) on the same exact PR head; APK artifact 14778453250, 35,969,051 bytes, SHA-256 `c3d960dfdbe720701dbde5c4d0daa21283bd4691903b056dca282061b5825f0c`, expires 6 December 2026.
- [x] Confirm the Godot runtime and full tower regression completed without the facade assertion failure on this exact head.
- [ ] Physical Android inspection remains outstanding; automated CI does not replace touch, visual, collision-feel, thermal or frame-rate testing.

### Baghdad five-tower public crowd expansion — 24 November 2026

- [x] Increase the persistent customer population from four to 100 visitors in each of the five connected Baghdad towers: 500 customers total. The independent Power Tower is excluded from this population.
- [x] Use a mixed-age public population in every tower: 20 children, 20 elderly visitors and 60 adults. Children use dedicated child character models, remain civilian-only, are linked to visible adult guardians in family groups, and cannot independently purchase goods.
- [x] Refresh already-persisted visitor models on startup when their saved age group differs, so existing installs also display children and elderly visitors correctly.
- [x] Keep the established two-customer elevator/floor visit lifecycle intact; the remaining 98 customers stay visible in the public lobby while two visitors use the active floor, preserving the restaurant and hotel flows.
- [x] Add mobile-oriented customer visual LOD: distant visitor meshes and labels use visibility ranges, and far-away customer model animation processing is suspended until the player approaches.
- [x] Extend regression checks for 500 total customers, 100 per tower, child guardian relationships, dedicated child/elderly character models and customer schedule state.
- [x] Route child visitor purchases through their adult guardian rather than allowing minors to transact independently.
- [ ] Await fresh canonical Godot validation and Android APK export on the latest PR head; no runtime or device-side success is claimed yet.
- [ ] Physically inspect crowd density, family grouping, age-model readability, elevator flow and Android frame rate on the target phone.

### Baghdad customer daily routines and movement redirection — 23 November 2026

- [x] Allow the customer schedule movement routine to accept an optional deterministic hour for validation while preserving the real system clock during normal gameplay.
- [x] Correct schedule changes so an active customer movement tween is cancelled and redirected when the daily phase changes; retain the existing tween only when the phase and destination remain unchanged.
- [x] Extend the full tower operations validator to verify all 500 persistent customers receive schedule phase/action/target state, all five towers contain exactly 100 visible visitors, and each tower has 20 child models with adult guardians plus 20 dedicated elderly models; then exercise the 08:00 cafe route and 11:00 browsing route transition.
- [x] Verify the previous breakfast tween stops, a new browsing tween starts, and the customer position physically changes toward the new destination.
- [x] Pass Godot 4.3 full project and Baghdad tower operations validation #1530 (run ID 45157041446) on exact gameplay/validator HEAD `7aff69fe38315c96ec3ad3514287cabc3f10ace5`.
- [x] Pass canonical Godot runtime validation #490 (run ID 45157036497) on the same HEAD.
- [x] Pass canonical Android APK build #1267 (run ID 45157041358); APK artifact `14808513067`, 35,973,093 bytes, SHA-256 `93f983c93382cd25bd507a083c09f7539cb589804477da53bbfeac1494b02629`, expires 7 December 2026.
- [x] Pass Android export #559 (run ID 45157036493); APK artifact `14808234799`, 35,878,499 bytes, SHA-256 `d62c69db1aceaaf30783d66b5469b468f715dc779053281fc01169538707bd8e`, expires 7 December 2026.
- [ ] Physical Android playtesting remains outstanding; automated Godot and APK export checks do not replace device touch, visual, frame-rate and thermal inspection.

### Baghdad pool guest services and safety interactions — 23 November 2026

- [x] Add dedicated player interaction zones for personal locker assignment in both pool changing suites.
- [x] Add dedicated shower service interaction zones so guests can record pool preparation before/after swimming.
- [x] Add an interactive lifeguard station for requesting pool assistance.
- [x] Route pool service interactions through the main interaction handler to the Baghdad tower operations manager.
- [x] Attach tower/floor routing metadata to each pool service target and expose clear Arabic interaction prompts.
- [x] Add service actions for locker reservation, shower preparation, and lifeguard assistance requests.
- [x] Extend `validate_baghdad_tower_operations.gd` to verify the three interaction areas, prompts, tower/floor routing, and each service action's player state.
- [x] Pass full Godot 4.3 validation #1534 (run ID 45158202151) on branch HEAD `4b59264a4e5d5aad5f52153a2f23be66c437e54d`.
- [x] Pass canonical Godot runtime validation #495 (run ID 45158192206) on the same HEAD.
- [x] Pass canonical Android APK build #1271 (run ID 45158202685); APK artifact `14809451838`, 35,975,852 bytes, expires 7 December 2026.
- [x] Pass Android export #564 (run ID 45158192235) on the same HEAD.
- [ ] Physical Android playtesting remains outstanding; automated validation/export does not verify device touch response, visual layout, frame rate, or thermal behavior.

### Baghdad pool supervisor, rescue equipment, and live assistance response — 23 November 2026

- [x] Assign the Entertainment Tower pool supervisor to the lifeguard station on pool floors 18 and 19 rather than a generic floor workstation.
- [x] Place the supervisor workstation, service counter, and information terminal beside the pool lifeguard platform.
- [x] Add visible first-aid kit, rescue-tube rack, and pool-safety equipment signage to the supervisor station.
- [x] Route the lifeguard role using its canonical NPC job identifier `pool_supervisor` (not the Arabic display label).
- [x] Make the lifeguard assistance action notify the active pool supervisor when the player is on pool duty floors; animate the supervisor's approach to the player and confirm arrival.
- [x] Clear the assistance request/arrival state when the supervisor finishes duty and returns to the public lobby patrol.
- [x] Extend the operations validator to test the supervisor's elevator trip, workstation placement, rescue equipment, assistance response, physical approach, and return-to-lobby cleanup.
- [x] Guard customer movement-tween metadata reads so newly created visitors do not emit missing-meta errors before their first scheduled movement.
- [x] Pass full Godot 4.3 validation #1541 (run ID 45159685939) on gameplay HEAD `ca807200588964bf388f617e106de1232a0ea5e0`; log confirms: `QA TRACE: pool supervisor duty, lifeguard workstation and lobby return passed.`
- [x] Pass canonical Godot runtime validation #507 (run ID 45159681081) on the same HEAD.
- [x] Pass canonical Android APK build #1278 (run ID 45159685656); APK artifact `14810196776`, 35,978,996 bytes, expires 7 December 2026.
- [x] Pass Android export #576 (run ID 45159681072) on the same HEAD.
- [ ] Physical Android playtesting remains outstanding; automated Godot validation and APK export do not verify touch response, visual layout, frame rate, thermal behavior, or collision feel on the device.


### Baghdad pool physical locker allocation and guest checkout — 23 November 2026

- [x] Replace the previous player-only locker flag with an actual allocation of the first available physical locker in the selected men's or women's changing suite.
- [x] Mark the selected locker occupied with the owning player instance, show its occupied state visually, and store the exact suite/floor/locker assignment on the player.
- [x] Prevent duplicate reservations by retaining the player's current locker when the service is requested again; report when a changing suite has no free lockers.
- [x] Release the locker and restore its original appearance when the player leaves the pool floor for another floor/tower or completes the return-to-lobby flow, including emergency evacuation.
- [x] Extend the full tower operations validator to assert real locker occupancy/ownership, duplicate-request protection, and release/re-availability on departure.
- [x] Pass Godot 4.3 full validation #1545 (run ID 45175817840) on exact gameplay/validator HEAD `7d9cb2d1c19f4783ddf7759821a7feb549b596f3`; full tower operations validation passed, including pool locker lifecycle, swimming physics, staff elevator duty, restaurant evacuation and the 200-floor Power Tower checks.
- [x] Pass canonical Android APK build #1282 (run ID 45175817938) on the same exact HEAD; APK artifact [14819581182](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45175817938/artifacts/14819581182), 35,981,754 bytes; APK SHA-256 `37a5a8b2aa09693b7a8a35de32919036f2ada3e401f3901d4e829226d337d56c`; expires 7 December 2026.
- [ ] Physical Android playtesting remains outstanding; automated Godot validation and APK export do not verify device touch response, visual layout, frame rate, thermal behavior, or collision feel.


### Baghdad Shopping Tower restaurant seating and waiting queue — 23 November 2026

- [x] Add four physical dining tables on restaurant floors, each with four explicit seat markers and per-seat customer ownership metadata.
- [x] Assign arriving customer NPCs to the first available physical seat; move their character nodes to the corresponding seat position and set their dining activity.
- [x] Add eight visible, ordered waiting positions and a queue sign beside the restaurant entrance; customers without a free seat enter the queue rather than being assigned an occupied seat.
- [x] Release a customer's seat/queue reservation before elevator boarding or emergency/lobby return; clear table ownership and queue marker state.
- [x] Promote the first waiting customer into a newly freed seat.
- [x] Extend the full tower operations validator to check two real seated customers, individual seat ownership, all eight queue positions, and release of reservations after restaurant evacuation.
- [x] Pass canonical Android APK export #1289 on gameplay/validator HEAD `93c8f4d0f5aed1a69f21a31ca2c7db1c1bd23122`; APK artifact [14823980114](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45184789462/artifacts/14823980114), 35,990,099 bytes, SHA-256 `f671ab0d2070508e75c414bf108847e968d5816c3e3323e86b12be7e465b58c3`, expires 7 December 2026.
- [ ] Godot 4.3 full tower validation #1552 (run ID 45184789456) is still in progress; do not mark the restaurant seat/queue runtime assertions fully verified until the job finishes successfully.
- [ ] Physical Android playtesting remains outstanding.


### SYSTEM Worldwide Food, Drink, and Gourmet Skill System — approved scope — 23 November 2026

- [ ] Treat food and drink as a shared SYSTEM WORLD gameplay/economy system, not a Baghdad restaurant-only feature. It must be usable across all four worlds and purchasable from markets, shops, street vendors, restaurants and other suitable food sellers wherever those facilities exist.
- [ ] Keep restaurant entry walk-in and low-friction: no mandatory advance booking. Dining tables/seats are optional interaction points; takeaway purchase must remain available without sitting down.
- [ ] Add portable food and water as stackable inventory consumables. The player can buy, carry, inspect and consume them from the inventory, including during combat subject to a short use animation/action window and interruption rules.
- [ ] Food effects must use the existing player combat-health/progression systems: restore bounded health, energy/stamina and/or grant temporary strength, speed, defence or endurance bonuses. Ordinary food must not clear persistent wound/injury states; serious injuries still require the established hospital/healer treatment.
- [ ] Add quality tiers (ordinary, good, rare, luxurious/legendary) with clear prices, effects, durations and balance limits. Avoid unlimited stacking; define refresh/replace rules for duplicate buffs.
- [ ] Luxurious/rare gourmet meals may roll one skill reward from an eligible pool when consumed. Use rarity-weighted deterministic-testable selection, record unlocked food skills persistently, prevent duplicate rewards from becoming meaningless, and clearly distinguish temporary meal buffs from permanent skill unlocks.
- [ ] Use one shared food catalogue/effect contract so all vendors and world-specific markets sell from the same system while retaining local stock, regional menu variety and prices.
- [ ] Extend automated QA for purchase/payment, inventory save/load, consumption, health caps, combat use, buff expiry/stacking, rare-skill roll boundaries, duplicate skill handling, and use across world contexts.
- [ ] Preserve existing customer, queue, restaurant seating, waiter, chef, hotel, tower and economy systems; extend them rather than replacing completed workflows.
- [ ] This is an approved implementation scope, not yet a verified gameplay feature. Do not mark complete until code and Godot/Android validation pass on the exact same HEAD.

**Priority after the current restaurant runtime verification:** implement the shared food/consumables foundation and market-facing purchase path with minimal UI, then resume the agreed Baghdad sequence: finish Power Tower work and the Hunter Tunnel beneath the Baghdad tower complex. Keep PR #38 draft and do not merge to main without explicit user approval.


### Power Tower sovereign boss readable attack telegraph — 23 November 2026

- [x] Add a visible ground shockwave ring and separate warning label to boss opponents; the ring pulses and its countdown text tells the player to evade before impact.
- [x] Scale the telegraph radius and boss emissive appearance across the sovereign boss's three health phases.
- [x] Hide the warning after the attack resolves and clear it safely when the boss is defeated.
- [x] Extend the Baghdad tower operations validator to assert the initial hidden state, visible countdown, post-attack cleanup, and phase-specific ring radii.
- [x] Pass full Godot 4.3 validation #1582 (run ID `45234631157`), canonical runtime validation #551 (`45234613746`), Android APK build #1319 (`45234631090`), and Android export #620 (`45234613941`) on the exact same gameplay/validator HEAD `440b62b78ef1d14f6893838b15133f552ce95770`.
- [x] Confirm canonical APK artifact `14848816671` (`SYSTEM-WORLD-canonical-android-debug-apk`), 36,012,628 bytes; available until 7 December 2026.
- [ ] Physical Android review of telegraph readability, touch evasion timing, boss collision and frame rate remains outstanding.
- [ ] Physical Android review of telegraph readability, touch evasion timing, boss collision and frame rate remains outstanding.
- [ ] The five connected Baghdad towers and independent Power Tower remain on PR #38 draft; no merge to main.


### Power Tower player-versus-player policy — approved 23 November 2026

- [x] All official Power Tower combat is exclusively between authenticated real human players. NPCs may guide, referee, sell, staff or spectate, but never replace a human combatant.
- [x] Every competition is individual 1v1 only: one human fighter against one human opponent. No team, party, squad, multi-opponent, enemy-wave or group combat formats are permitted on any floor, including elite and title-holder challenges.
- [x] Floor data declares `INDIVIDUAL_1V1`, `HUMAN_PLAYER`, `ONLINE_1V1` and `ai_fallback = false`. Floor entry displays a waiting/unavailable state instead of spawning bots when matchmaking is unavailable.
- [x] The tower has integration hooks for authenticated human match start, prediction locking and server-verified result settlement. Floor rewards require a unique verified result ID and a confirmed local-player win.
- [x] The champion/"floor boss" is a real player holding the title. Other eligible human players challenge that title-holder; the title changes only after a verified result. Floor 200 is the sovereign title duel, not an AI boss fight.
- [ ] Add fair online matchmaking by level, combat rating and recent performance; define disconnect, timeout, draw, surrender, rematch and anti-smurf rules before ranked launch.
- [ ] Require authenticated player identities and a signed authoritative online match/result service. Validate damage, cooldowns, movement, equipment and match outcomes server-side; never trust a client-reported win, local save file or local event-board entry as a global result.
- [ ] Add multiplayer QA for match pairing, rank boundaries, server-authoritative result verification, disconnect/forfeit handling, anti-cheat and anti-collusion before enabling ranked rewards.
- [ ] Keep the old AI sovereign-boss/telegraph actor isolated as a legacy test fixture only; it is not spawned in the Power Tower and is not the approved combat design.
- [ ] Keep PR #38 draft and do not merge to main without explicit user approval.

### Power Tower climb deadlines, player predictions, and achievement prizes — approved 23 November 2026

- [x] Confirm that official combat remains exclusively between authenticated real players; NPCs may train, guide, referee or host the arena but never replace a human opponent in ranked or championship combat.
- [x] Approve a per-floor challenge deadline: when a player reaches and claims a floor, a visible countdown begins and the player must enter/complete the required official duel before that floor's configured deadline.
- [x] Approve timeout consequence: if the player does not fight before the deadline, revoke their current-floor claim and return them to the previous earned checkpoint/floor; they must climb and qualify again. Preserve already-earned permanent rewards and do not erase unrelated character progression.
- [x] Approve player-versus-player match predictions as a spectator/social feature. Predictions use non-purchasable, non-cash in-game prediction points only; no player stakes real money or withdrawable value, and prediction points cannot be converted to cash.
- [x] Keep monetary prizes separate from predictions and wagers: eligible players may receive achievement-based prizes for verified competitive milestones/floor advancement under published eligibility, anti-cheat, age, regional-law and payout rules. Prize funding must never come from losing players' stakes.
- [ ] Define configurable floor deadlines, grace periods, notification cadence and fair pause rules for verified server outages or exceptional disconnects; do not punish a player solely for a platform-wide outage.
- [ ] Define the achievement prize ladder, eligibility, funding cap, identity/age verification, regional availability, tax/payment handling and dispute process before enabling any real-money payout. Keep payouts disabled until legal and payment-provider review is complete.
- [ ] Implement authoritative server timestamps and floor-claim records so clients cannot pause, reset or alter deadlines; resolve expiry once only and prevent duplicate demotion/reward processing.
- [ ] Implement prediction windows that close before match start, lock submitted predictions, settle only from a server-verified result, and prevent self-betting, collusion, duplicate accounts and manipulation.
- [ ] Extend multiplayer QA for deadline start/expiry, checkpoint rollback, offline/outage grace, prediction lock/settlement, verified milestone rewards, duplicate claims and cross-device persistence.
- [ ] This section records approved design scope only; it is not a claim that player-versus-player matchmaking, prediction settlement or real-money prize payouts are implemented.
- [ ] Keep PR #38 as draft and do not merge into main without explicit user approval.

### Power Tower economy clarification — virtual livelihood rewards, fan predictions, and free/paid progression — 23 November 2026

This clarification supersedes any earlier wording that could imply cash betting or cash payouts.

- [x] **Fighters' floor rewards are in-game virtual currency, not real-world cash.** Award the fighter a published virtual-currency reward for each officially verified floor victory/clear, with higher milestone rewards at selected floors/ranks. This currency is usable in SYSTEM WORLD for ordinary living and progression: food, drinks, accommodation/rent, transport, repairs, equipment, services and other world purchases.
- [x] **Fans are spectators and predictors, not cash bettors.** Fans may predict the winner of a human-versus-human match using free, non-purchasable, non-transferable virtual prediction points. Correct predictions earn additional prediction points and/or clearly defined in-game fan rewards. Prediction points never represent cash, cannot be withdrawn, and are not wagered against real money.
- [x] **Free players can earn the same core livelihood currency.** They can earn it through verified Power Tower victories, jobs, missions, trade, crafting, exploration and other gameplay. They can buy food, drinks, shelter, equipment and develop skills without paying real money.
- [x] **Players who top up may obtain premium in-game currency through the official store.** Keep premium currency separate and clearly labelled from gameplay-earned livelihood currency; disclose exchange rates and purchases. Paid currency may support cosmetics and optional convenience, but must not buy ranked wins, combat stats, floor qualification or competitive matchmaking advantage.
- [x] **No cash-out promise:** neither fighter rewards nor fan prediction points are redeemable for real-world money, and no real-money stakes or player-to-player cash betting are part of this design.
- [ ] Define the exact reward amount per floor/milestone, economy sinks, daily/seasonal earning balance, anti-farming rules and transparent player-facing reward schedule.
- [ ] Define whether premium currency can purchase ordinary goods directly or only selected optional goods; preserve a complete free path to essential food, shelter, repairs and competitive equipment.
- [ ] Implement server-authoritative reward grants exactly once per verified match/floor clear, persistent balances across devices, transaction history, anti-duplication protection and clear UI separation of earned and purchased balances.
- [ ] Implement fan prediction locking and settlement from verified match results only; enforce one prediction per account/match, no self-prediction by participants, and abuse/collusion controls.
- [ ] This is approved design scope; implementation and QA remain pending. Keep PR #38 draft and do not merge to main without explicit user approval.


## Power Tower economy and spectator predictions — 23 November 2026

- [x] Confirmed the existing player economy uses the same local SYSTEM credits wallet as shopping, food, hotel bookings, services and facility rewards; the player begins with a playable starter balance and can earn more without purchasing currency.
- [x] Centralized Power Tower floor virtual-credit reward values in the progression manager and included them in the verified floor-clear result. Rewards scale by floor; the final sovereign floor receives its configured completion bonus.
- [x] Updated tower operations to credit the wallet only from the successful verified floor-clear result. Abandoned, timed-out, wounded or otherwise unconfirmed attempts do not receive floor-clear credits.
- [x] Extended the Baghdad tower validator to require a positive virtual-credit reward on every floor and increasing rewards between the first two floors.
- [x] Spectator virtual ticket pools are restricted to authenticated human-versus-human individual 1v1 matches. Simulated NPCs may participate only as clearly labelled fans with a fixed virtual ticket budget; NPCs never act as fighters. The later "Power Tower fan virtual ticket pools" section supersedes the earlier point-only wording.
- [ ] Global fan participation, cross-device leaderboards and anti-cheat settlement require an authoritative online service. The existing public event board is a local-session display and must not be represented as live global multiplayer.
- [ ] Run canonical Godot validation and Android export on the resulting PR head; no new runtime/build success is claimed by this source update.
- Scope remains the existing Power Tower and shared SYSTEM wallet; no merge to main.


### Power Tower fan virtual ticket pools — approved clarification and local implementation — 23 November 2026

This section supersedes the earlier point-only fan prediction wording above. The user's intended mechanic is a virtual ticket-pool system similar to sports-prediction pools, with no real-money betting or cash-out.

- [x] Replace free-only prediction points with virtual SYSTEM-credit tickets. A spectator selects exactly one of the two fighters in an individual 1v1 match and commits 1–500 virtual credits from the existing SYSTEM wallet.
- [x] Deduct each accepted ticket stake from the local wallet and add it to the match's visible total pool. Reject invalid stakes, insufficient balances, duplicate entries, self-prediction, invalid fighter selection, locked matches and entries beyond the 20-ticket daily cap.
- [x] On a trusted local match result, distribute the complete pool proportionally to the winning side's total stake. Record each fan's gross payout and net virtual profit separately; losing tickets lose only their committed virtual stake.
- [x] If no fan selected the actual winner, refund every ticket stake rather than destroying credits. Ensure payout rounding remainder is included so the complete pool is accounted for.
- [x] Connect the Power Tower manager to the existing SYSTEM local wallet through explicit stake-debit and payout-credit methods.
- [x] Add regression coverage for a 120-credit pool split 80/40 between two winning fans, the losing fan's 60-credit loss, unchanged total wallet balance after full distribution, refund of a 25-credit pool with no correct prediction, persistence and daily limits.
- [x] Update the dedicated Power Tower economy and individual competition documents to describe virtual tickets and pool winnings; explicitly prohibit cash deposits, withdrawals, cash-out, real-money transfer and real-world prizes.
- [ ] Add clearly labelled NPC fan ticket budgets and NPC ticket participation. Do not represent simulated NPC entries as real players.
- [ ] Add an actual live match scheduler and connect prediction lock to match start and settlement to the authoritative match result. Do not invent live matches or show a prediction panel for the player's own match.
- [ ] Add a spectator-facing UI for fighter selection, stake entry, live pool totals, lock countdown, results, gross payout and net profit.
- [ ] Replace local wallet and local settlement with authenticated account-specific, server-authoritative wallet transactions before enabling global users; add anti-cheat, anti-collusion, idempotent settlement and cross-device persistence.
- [ ] Godot and canonical Android workflows for the resulting exact HEAD are queued; do not mark the new implementation verified until both pass on the same commit.
- [ ] Physical Android touch/visual testing remains outstanding.
- PR #38 remains draft and unmerged. Do not merge into main without explicit user approval.


### NPC fan ticket-pool participation — 23 November 2026

- [x] Add clearly labelled NPC spectator identities with a fixed 300-credit virtual ticket budget, separate from the human SYSTEM wallet.
- [x] Allow NPC spectators to enter the same 1v1 match pool as human fans through an explicit NPC-only ticket API; NPC stakes and balances are persisted.
- [x] Route NPC winnings/refunds back to NPC-only balances. When a human wins a pool containing NPC stakes, the human's proportional payout is credited to the SYSTEM wallet.
- [x] Extend regression coverage for NPC participation, the 300-credit budget, human winnings from a mixed pool, and NPC balance persistence.
- [ ] Automated NPC crowd selection, actual live match scheduling, spectator UI, online accounts, server-authoritative settlement and global anti-cheat remain pending. NPC entries must be labelled as simulated, never as real users.
- [ ] Validate the latest exact branch HEAD with Godot and canonical Android workflows before marking this change verified.
- PR #38 remains draft and unmerged.


### Power Tower battle displays — outside, lobby and all floor arenas — 23 November 2026

- [x] Add a physical 3D battle schedule display outside the Power Tower entrance.
- [x] Add a matching physical 3D battle schedule display inside the public lobby.
- [x] Generate the complete 200-floor schedule from the canonical floor profiles, grouped into ten 20-floor chapters and labelling standard 1v1, elite 1v1, boss 1v1 and the floor-200 sovereign duel.
- [x] Add a physical battle-screen panel to each generated arena floor, with the current floor number, arena type, environment and 1v1 rules shown on its in-world display.
- [x] Extend the Baghdad tower operations validator to check both public displays, all 200 scheduled floors, representative standard/elite/boss floor screens and the sovereign floor-200 screen.
- [ ] Run Godot 4.3 full validation and canonical Android export against the same resulting branch HEAD; no verification success is claimed until both workflows pass on that exact commit.
- [ ] Inspect the displays on a physical Android device for text readability, touch behavior, camera visibility and performance.
- Online live event streaming and the separate interactive spectator prediction interface remain future work; these schedule screens must not imply live global matchmaking.


### Hunter-style arena rules adapted for SYSTEM Power Tower — 23 November 2026

- [x] Add persistent fighter registration numbers.
- [x] Add a three-official referee panel to each generated arena: head referee, technical judge and safety judge.
- [x] Add referee-scored clean hits (1), critical hits (2), knockdowns (1), a 10-point TKO threshold, KO, judges' decision, forfeit and referee stoppage outcomes.
- [x] Reject duplicate score events and unauthorized judge IDs; require the configured local match-authority result before career settlement.
- [x] Add persistent career loss records: three consecutive defeats demote one ten-floor division; ten total defeats disqualify the fighter and reset unlocked tower progress to entry while preserving previously earned wallet/inventory rewards.
- [x] Add division metadata, floor-100 private-room eligibility and floor-200 weapon allowance to canonical floor profiles.
- [x] Add physical referee podiums, referee/rules text and a live score/result display to every generated Power Tower arena.
- [x] Connect duel score/completion signals from the Power Tower manager to the in-arena live score display.
- [x] Extend regression validation for fighter registration, duplicate judge events, 10-point TKO, three-loss demotion, ten-loss disqualification and floor-200 live score updates.
- [ ] Run Godot full validation, canonical runtime validation and Android export on the same latest branch HEAD; do not mark these changes verified until all pass.
- [ ] Confirm physical Android readability, camera visibility and performance for the arena screens and judge stations.
- [ ] Integrate server-authoritative human matchmaking, judge identity verification, anti-cheat and cross-device career/wallet persistence; current local manager hooks are prototypes, not a live online service.


### Power Tower virtual ticket terminal and judged match lifecycle — 23 November 2026

- [x] Place an interactive virtual-ticket terminal in the Power Tower public lobby and route player interaction to its in-game panel.
- [x] List open 1v1 matches with floor, both fighters and pool total; allow the spectator to choose one fighter and stake 1–500 virtual SYSTEM credits.
- [x] Automatically open a spectator ticket pool when a registered, referee-supervised duel is registered.
- [x] Automatically lock the pool when the referee settles the duel and distribute the pool to correct predictions through the local virtual wallet; wrong predictions receive no payout and no-correct-ticket pools are refunded.
- [x] Add regression coverage for automatic pool creation and settlement alongside judge scoring, loss penalties and live arena score display.
- [x] Correct the floor-200 challenge profile string to `FINAL_BOSS`, matching the existing sovereign-floor validator.
- [ ] Run the latest Godot and Android workflows on the exact current branch HEAD; latest results are pending.
- [ ] Complete physical Android usability and performance checks.
- [ ] Replace local match authority and local wallet with trusted server matchmaking, signed judge results and account-level persistence before public online competition.


### Power Tower combat-to-referee integration — 23 November 2026

- [x] Verified human 1v1 match start registers both fighters with persistent competitor numbers and creates/reuses the matching open spectator pool.
- [x] The live match setup creates the official judged-duel record before the arena begins and locks spectator tickets at match start.
- [x] Local combat `attack_performed` events feed the head referee score ledger: ordinary hits score 1 and heavy/critical hits score 2; explicit knockdown metadata can add the knockdown point.
- [x] Referee score signals update the live in-arena scoreboard; verified match results now pass through the referee settlement path so career loss penalties and spectator ticket payouts use the same winner.
- [x] Floor-clear rewards remain counted once by the verified progression flow; referee win recording only resets the loss streak.
- [ ] Remote opponent hit events and judge decisions still require trusted server delivery; local client combat events are not authoritative anti-cheat evidence.
- [ ] Re-run full Godot project validation and canonical Android export on exact current HEAD `0d945bc376b44d80b62ab430d4b979e6812e9468`; latest runtime and export workflows are in progress.


### Power Tower interactive audience and spectator seating — 24 November 2026
- [x] Generated 48 physical reservable seats per generated arena floor, with per-seat identity, availability status, interaction trigger and collision.
- [x] Added local player seat ownership, one-seat-at-a-time protection, rejection of occupied seats, seated movement lock, owner release, and automatic cleanup on floor/lobby transitions.
- [x] Added eight lightweight procedural audience actors behind the seats; tied live scores return them to watching, a leading fighter triggers cheering, and an officially completed duel triggers a winner celebration pose.
- [x] Added regression coverage for 48 seats, actor count/arm pivots, watching/cheering/celebration states, seat owner protection, manual release and transition cleanup.
- [ ] Remote spectator synchronization, persistent online seat reservations, voice/chat and server-authoritative online ticket settlement remain outside this local in-engine implementation.
- [ ] Full Godot validation and canonical Android export must pass on the exact final feature branch HEAD before merge consideration; physical Android touch/visual/performance inspection remains outstanding.


### Power Tower arena fan-prediction access and seat availability — 24 November 2026
- [x] Added a physical interactable fan-prediction board to every generated spectator gallery, routed to the existing official virtual-ticket terminal and 1v1 match pool.
- [x] Added a live 48-seat availability display that updates on reserve, owner release and automatic floor/lobby cleanup.
- [x] Added QA assertions for the arena prediction-board interaction and 48/48 ↔ 47/48 seat count refresh.
- [ ] Exact-HEAD Godot validation and canonical Android export remain pending; remote online spectators and server-authoritative economy remain out of scope for the local prototype.

- [x] Seat ownership stores the exact floor identity to prevent same-number seat collisions across different floors; QA opens the shared virtual-ticket panel through the physical arena prediction-board route.


## Baghdad tower regression and Hunter tunnel continuation — 24 November 2026

- [x] Diagnosed the latest full tower-operations failure: the Power Tower's NPC-managed external campaign was created as `NPCManagedExternalCampaign`, while the common tower regression correctly requires the canonical `TowerCampaignText` node. Standardized the external campaign node name across all six towers and retained compatibility with an existing legacy node.
- [x] Added `tools/validate_hunter_tunnel_entry.gd` as an end-to-end regression: verifies the hidden door starts locked, incorrect clue order resets progress, Eye → River → Crown reveals the stone passage and enables its collision, entry is rejected before Hunter Association registration, and a registered candidate is physically moved into the underground Baghdad stage.
- [x] Added the tunnel regression to the canonical Godot validation workflow.
- [x] Documented the original SYSTEM adaptation of broad Hunter-exam adventure themes: seven varied non-combat/combat-balanced stages, original examiners and candidate behavior, and an original energy discipline with control, costs, counters and non-combat applications. No anime characters, dialogue, scenes, named techniques or music are to be copied.
- [ ] Re-run the six-tower operations regression, all Baghdad tower regressions, Hunter tunnel entry regression and stage-one runtime regression on the exact updated branch HEAD.
- [ ] Re-run canonical Godot validation and Android APK export on that same exact HEAD; do not mark Baghdad complete until the relevant checks pass.
- [ ] Extend the physical examination environments beyond Baghdad stage one. Cairo, Alexandria, Paris, Babylon, Tokyo and Highland Frontier remain planned, not implemented.
- [ ] Add original examiner/candidate NPC behaviors, scoring for observation/rescue/restraint/resource management, and explicit retry/withdrawal rules; validate each before claiming production readiness.
- [ ] Keep PR #38 as draft and do not merge into `main` without explicit user approval.


## Baghdad towers and Hunter tunnel — verified checkpoint 24 November 2026

- [x] Fixed the Power Tower external advertising regression by assigning the canonical `TowerCampaignText` node name across all six towers; preserved existing legacy campaign nodes when present.
- [x] Canonical Godot runtime workflow passed on commit `39231d9c5a80f718ee9e20ab149db2bdfc28d6bb`, including Baghdad tower landmark/lobby validation, hidden Hunter tunnel entry, playable Baghdad examination stage one, full tower operations/elevators/staff/emergency evacuation, terrain streaming, child safety, WGS84 anchor integration, Star Gate/Greed Island boundary and headless main-scene launch.
- [x] Hunter tunnel regression passed: locked door, wrong-order reset, Eye → River → Crown sequence, physical passage visibility/collision, registration requirement, and actual player transfer to the underground stage.
- [x] Baghdad stage-one regression passed: physical chamber and collisions, seven spike obstacles, ordered inscription objectives, locked relic, original SYSTEM examiner Raed and briefing interaction, artifact recovery and sequential progression to Cairo.
- [x] Dedicated Android APK export and upload workflow passed on the same commit; see run 45323857216. This confirms export, not on-device visual/touch QA.
- [ ] The separate combined canonical APK workflow still fails its unrelated companion check: `validate_companion_runtime.gd` reports that Miyar did not load a rigged GLB model. The dedicated APK export succeeded; fix and rerun the companion-model validation separately before calling the combined workflow green.
- [ ] Complete physical Android inspection of tower interiors, campaign displays, tunnel traversal and stage-one interactions.
- [ ] Six remaining physical examination environments and original examiner/candidate behaviors remain future work.
- [ ] PR #38 remains draft on this feature branch; do not merge to `main` without explicit user approval.


### Exact-HEAD final verification — 24 November 2026

- [x] Canonical Godot runtime validation passed on `bd7e5c1ebbe91d2379ae8c13d54f91a8a6486ca8` — run [45324119302](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45324119302).
- [x] Canonical Android APK build, companion GLB checks, NPC population checks, export and artifact upload all passed on the same HEAD — run [45324126926](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45324126926).
- [x] Dedicated Android APK export and upload also passed on the same HEAD — run [45324119280](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45324119280).
- [x] The earlier Miyar companion validation failure did not reproduce on this exact HEAD; both Miyar/Adam companion checks passed.
- [ ] Human Android device inspection remains necessary for touch feel, camera framing, visual readability, and performance; headless checks do not replace device QA.


### Six additional physical Hunter examination environments — 24 November 2026

- [x] Extended the shared stage runtime beyond Baghdad so Cairo, Alexandria, Paris, Babylon, Tokyo and Highland Frontier each build a distinct named 3D examination site with physical ground/boundary/obstacle collisions, visible objective markers, interaction areas and an examiner NPC.
- [x] Added ordered, stage-specific objective chains: Cairo caravan/water/exit; Alexandria beacon/rescue/lighthouse; Paris echo/stealth route; Babylon sun/moon gears/seal; Tokyo trace/civilian assistance/interception; Highland supplies/shelter/summit.
- [x] Added objective-order rejection and progression feedback; the final objective records the corresponding stage through the existing examination manager. The original Baghdad riddle, traps, artifact and examiner remain unchanged.
- [x] Expanded `validate_hunter_exam_stage_runtime.gd` to run through all seven stages sequentially, check each additional stage's physical ground collision and examiner, reject out-of-order interaction, complete all three objectives and verify all seven stage records.
- [ ] Run the expanded Hunter examination validator and full canonical Godot workflow on the exact updated branch HEAD; parser/runtime success is not yet claimed.
- [ ] Run canonical Android APK export on that same exact HEAD and inspect the generated artifact.
- [ ] Physical Android inspection remains outstanding. These are first playable local geometry prototypes, not finished authored city-scale environments, online candidate simulations or server-authoritative examination scoring.
- PR #38 remains draft and unmerged. Do not merge into `main` without explicit user approval.

## Exact-HEAD Baghdad towers, Hunter examination and Android verification — 24 November 2026

This checkpoint supersedes earlier pending validation notes above. Exact tested source/validator HEAD: `01e4b02f5b29a982dbbaeaf275a9636f32850099`.

- [x] Godot 4.3 extended project validation #1997 passed on exact HEAD — run [45383735682](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45383735682). This includes resource/script import, child-character restrictions, missing-mesh diagnostic, main-scene launch, Baghdad tower landmarks/lobbies, complete tower interiors and NPC commerce, advertising, Power Tower boss arena, hidden Hunter tunnel entry, and all seven sequential Hunter examination stages.
- [x] The complete tower operations regression passed, including the 200-floor Power Tower individual-duel systems, Shopping Tower workshop/equipment and skill progression, hotel housekeeping, player restaurant seating and meal delivery, autonomous NPC waiter/chef service, customer seating/queue/elevator flow, emergency evacuation, and entertainment-facility staff duties.
- [x] Hunter tunnel regression passed: locked hidden door, wrong clue-order reset, Eye → River → Crown sequence, physical passage collision/visibility, registration gate, and actual transfer into the underground examination stage.
- [x] All seven Hunter examination stages passed sequentially: Baghdad, Cairo, Alexandria, Paris, Babylon, Tokyo and Highland Frontier. The six additional environments are playable local geometry prototypes with objective-order enforcement and examiner NPCs; they are not finished city-scale environments or server-authoritative examination simulations.
- [x] Canonical Godot runtime validation #858 passed on exact HEAD — run [45383730457](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45383730457), including tunnel, seven stages, tower operations/elevators/emergency evacuation, terrain streaming, child safety, WGS84 anchor integration, Star Gate/Greed Island boundary and headless main-scene launch.
- [x] Canonical Android APK workflow #1726 passed on exact HEAD — run [45383735511](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45383735511). APK artifact [14913838852](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45383735511/artifacts/14913838852), 36,146,797 bytes; available until 8 December 2026.
- [x] Dedicated Android export #924 passed on exact HEAD — run [45383730743](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45383730743). APK artifact [14913789890](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45383730743/artifacts/14913789890), 36,053,107 bytes; available until 8 December 2026.
- [x] Miyar and Adam are now validated as interface-only SYSTEM assistants. Their UI buttons switch the explanation panel; no follower models are created and neither character accompanies the player. Their in-world appearance remains reserved for their approved exceptional tower-leader roles.
- [x] The restaurant QA now accepts the valid case where a recovery tick advances the chef order to `ready` and the waiter reaches `served` within the same polling pass; the validator still requires final `served` state.
- [x] Hunter examination stage runtime now populates its typed objective array explicitly and names physical collision shapes explicitly, allowing the seven-stage collision regression to pass.
- [ ] Physical Android touch, visual readability, camera framing and performance inspection remain outstanding; automated headless success does not replace device QA.
- [ ] Remaining scope includes fully authored city-scale examination environments, richer original examiner/candidate behavior and server-authoritative online matchmaking/economy; do not label those as complete.
- [ ] Keep PR #38 as a draft and do not merge into `main` without explicit user approval.


## Restaurant lifecycle and complete Baghdad tower verification — 24 November 2026

Exact gameplay/validator HEAD: `f86bbaa933629acad51639bde949d76be705303f`.

- [x] The full Godot project validation #2014 passed on this exact HEAD (run ID `45389414794`): resource import and script parsing, headless main-scene launch, Baghdad landmarks/lobbies, tower interiors and NPC commerce, Power Tower boss arena, hidden Hunter tunnel, and all seven playable Hunter examination stages.
- [x] The complete Baghdad tower operations validator passed on this exact HEAD. Its restaurant trace confirms the player sits, movement locks, the waiter accepts the order, the chef prepares it, the waiter delivers it, the meal restores health and awards XP exactly once, and checkout releases the seat.
- [x] The same operations run also confirms autonomous NPC restaurant service: waiter acceptance, chef preparation and waiter delivery; restaurant emergency evacuation releases seating reservations and returns customers safely.
- [x] Canonical Android APK build #1743 passed on the same exact HEAD (run ID `45389414779`), including required character asset checks, canonical Godot import/parse, headless main-scene launch, Miyar and Adam GLB checks, civilian NPC checks, Android export and artifact upload.
- [x] APK artifact: `SYSTEM-WORLD-canonical-android-debug-apk`, artifact ID `14917768591`, 36,154,108 bytes; SHA-256 `c9d0c0450cb3c19b7dbe7cda9e60719ef5185530285067300606c4c2e4ea78b5`; expires 8 December 2026.
- [x] Tower operations validation log artifact: `SYSTEM-WORLD-baghdad-operations-validation-log`, artifact ID `14917428170`; expires 1 December 2026.
- [ ] Physical Android device inspection (touch response, visual readability, camera framing and performance) remains outstanding; automated/headless success does not replace device QA.
- PR #38 remains draft and unmerged. Do not merge into `main` without explicit user approval.


## User-confirmed Baghdad tower layout correction and runtime gap audit — 24 November 2026

- [x] Re-read the current branch's approved expansion, Hunter tower design, landmark builder, helicopter controller, tower operations manager, floor-theme builder, and latest exact-HEAD validation checkpoint before proposing changes.
- [x] Confirmed the five existing tower identities in the branch: Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation. The Power Tower remains a separate standalone destination.
- [x] Recorded the user's final placement: the connected five-tower district is an elevated urban layer across Karkh–Rusafa; the Hunter Association Tower is on the Tigris above Republic Bridge; advertising facades must face inward and outward; the helipad is above the Hunter tower; the hidden examination tunnel is below the district and its concealed entry is inside the Shopping Tower restaurant.
- [x] Confirmed existing commerce/gameplay foundations that must be preserved: Shopping Tower catalogues already include weapons, shields, armor, rank-based hunter outfits, Nen awakening/control/stabilization/recovery elixirs, skill-training permits, and restaurant goods; hotel room booking/housekeeping, restaurant seating/queue/waiter/chef/meal lifecycle, and Entertainment Tower pool facilities are already present and covered by current operations validation.
- [ ] Runtime layout still requires correction: `baghdad_tower_landmarks_manager.gd` currently places the Hunter tower at a generic `city_anchor + Vector3(0, 0, 365)` offset, attaches the helipad there, and builds the other four towers around it. It does not yet anchor the Hunter tower to Republic Bridge/Tigris or build the requested elevated city layer and two-sided Hunter advertising facades.
- [ ] Hidden-entry integration still requires correction: the current tunnel root and three surface clues are placed at the Baghdad city anchor; the restaurant currently has working seating and service but is not yet the concealed examination access point.
- [ ] Keep the existing seven-stage examination, three-inscription sequence, registration requirement, physical tunnel descent, completed tower interiors, and verified restaurant lifecycle. Extend these systems; do not replace or regress them.
- [ ] Before runtime placement changes, identify the exact Republic Bridge/Tigris anchor from approved geospatial source data. The current geography notes explicitly warn that the Baghdad map pack/bridge layers are not yet fully approved; do not invent real-world coordinates or claim map accuracy.
- [ ] Re-run Godot tower/runtime validation and Android export after the runtime layout and restaurant-entry integration are implemented. Existing exact-HEAD test success applies to the old placement, not to the corrected layout.


---

## Baghdad Republic Bridge five-tower district — runtime implementation and verification (2026-11-24)

**This section supersedes the open runtime-layout and restaurant-entry gaps recorded in the preceding Baghdad audit.** Work remains isolated to `feature/baghdad-five-plus-power-tower-20261122` and draft PR #38; nothing has been merged to `main`.

### Approved runtime layout now implemented

- [x] The five Baghdad towers are anchored to the verified Republic Bridge/Tigris reference rather than generic city-anchor offsets: Hunter Association, Business and Investment, Shopping and Commerce, Entertainment and Sports, and Technology and Innovation.
- [x] Republic Bridge is built from the verified OSM polygon outline (way 1077808833), with a triangulated deck mesh, physical concave collision, and guardrails. The deck is aligned at 18.0 m with the bank terrain.
- [x] Both OSM roadway centerlines (ways 4080878 and 754157537) are rendered at 18.08 m on the bridge deck; the Tigris surface uses verified OSM waterway way 24709603.
- [x] The bridge/tower reference uses the WGS84-derived local frame in `republic_bridge_reference.json`; the latest source workflow independently verified the same bridge polygon, both centerlines, and Tigris feature against the current OSM extract.
- [x] A blended, playable land approach connects the existing continent to the bridge district. The four non-Hunter towers are placed on the riverbanks; the Hunter Association Tower occupies the bridge platform.
- [x] The Hunter tower remains the tallest of the five (650 m; updated from the earlier 1000 m concept). Its public lobby aligns with the bridge deck; twelve outward-facing advertising facades and the internal lobby advertising panels are present.
- [x] The helicopter landing pad is positioned above the Hunter tower and its runtime controller creates the helicopter.
- [x] The upper sky city is positioned above the five-tower cluster at the approved upper level. Four walkable city blocks and connecting skyways link the four bank towers to the Hunter atrium ring.
- [x] The Power Tower was not modified or added to the Baghdad district. It remains a separate standalone destination; its existing boss-arena behavior was only included in regression validation.

### Hunter examination tunnel and restaurant integration

- [x] The three surface clues remain at their riverbank locations and retain the Eye → River → Crown sequence.
- [x] The concealed tunnel root is physically repositioned beneath Shopping Tower restaurant floor 29 when that floor is generated. The clue locations remain unchanged.
- [x] The restaurant entrance Area3D remains undetectable before the riddle is solved. If the riddle is solved before the restaurant floor loads, the entrance remains concealed until the restaurant placement is ready.
- [x] After the third clue is solved, the hidden door slab rises, its blocking collision is removed, the framed doorway remains physically supported, the descending passage becomes visible/collidable, and the restaurant entrance becomes interactable.
- [x] Hunter registration remains required before tunnel entry. The existing seven playable examination stages were preserved.

### Verified source and test results

- [x] **OSM source verification:** workflow run [45404681838](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45404681838) succeeded. Artifact 14925575635 contains the extended metric cell pack; the pack has 276 occupied cells, including bridge/Tigris cell `17_-6`. The bridge polygon, primary/secondary centerlines, and Tigris feature were verified from the current OSM extract.
- [x] **Canonical runtime validation:** workflow run [45404778901](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45404778901) succeeded, including Baghdad tower landmarks, tower operations/elevator staff/emergency evacuation, hidden Hunter tunnel entry, and all seven examination stages.
- [x] **Full Godot project validation:** workflow run [45405266091](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45405266091) succeeded on commit `d42cfbd6f2be8ea46d37802f4845588b500bda0c`. Import/parse, child-character safety, mesh-resource scan, main-scene launch, Baghdad landmarks/lobbies, tower interiors, NPC commerce, advertising, Power Tower boss-arena regression, restaurant/tunnel entry, and all seven Hunter stages passed.
- [x] **OSM runtime geometry validation:** passed inside the canonical Android workflow. The Godot test loaded the Baghdad core cell and bridge/Tigris cell `17_-6`, found both bridge centerlines and Tigris geometry, and verified the bridge-road height override.
- [x] **Canonical Android APK:** workflow run [45405266189](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45405266189) succeeded on the same commit. The extended OSM pack was installed before export, and the APK was exported and uploaded.
  - Artifact: `SYSTEM-WORLD-canonical-android-debug-apk`, ID `14925196373`.
  - APK size: 36,629,288 bytes.
  - APK SHA-256: `cd7b97965b0b3166e5dfcfd04d001f8cb09794118a238e287ce86793518ffe81`.
  - Artifact expiry: 2026-12-08.
- [ ] Physical Android-device installation/play testing remains outstanding; successful headless Godot validation and APK export do not claim device QA.

### Merge and scope guard

- [x] PR #38 remains **open and draft**, with base `main`; no merge was performed.
- [x] No Power Tower gameplay/system files were changed as part of this Baghdad implementation.
- [ ] Merge remains blocked until the user explicitly approves it.


### Baghdad exact-HEAD revalidation after runtime alignment fixes — 24 November 2026

Validated source snapshot: `9a87f1a90a24d30693c92749a7da5ac1230edbdf` on `feature/baghdad-five-plus-power-tower-20261122`.

- [x] Full Godot 4.3 project validation passed: [workflow 45406162782](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45406162782). The run imported/parsed resources, launched the main scene, validated the Baghdad landmarks/lobbies, five-tower interiors and operations, NPC commerce, advertising, and Power Tower regression.
- [x] Baghdad tower operations validator passed on this exact HEAD: five connected Baghdad towers, independent Power Tower, NPC commerce, hotel workflows, eleven playable leisure/technology loops, equipment, Nen progression, and the existing sovereign-boss regression.
- [x] Concealed Hunter tunnel validator passed: locked door before the riddle, wrong-order reset, Eye → River → Crown unlock, physical ramp reveal/collision, registration gate, and actual player transfer into stage one.
- [x] Hunter examination validator passed: all seven sequential stages, with objective-order enforcement.
- [x] Canonical Android build passed on this exact HEAD: [workflow 45406162469](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45406162469).
- [x] The Android workflow installed the branch-matched 276-cell Baghdad OSM pack and verified the Republic Bridge polygon/centerlines and Tigris source IDs before export.
- [x] OSM runtime geometry test passed: Baghdad center cell generated roads/buildings/landuse/collisions; cell `17_-6` rendered both Republic Bridge roadway centerlines and the Tigris geometry; both roadway meshes carried the 18.08 m deck-height override.
- [x] Canonical main-scene headless runtime validation passed: [workflow 45406145561](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45406145561).
- [x] Android APK artifact: [14926790278](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45406162469/artifacts/14926790278), 36,629,121 bytes (about 36 MB), SHA-256 `9ca1b7f6cf2c5c90cbc491cb1516a9c14f4cbeece22fe2130f14d1fe6a49a006`; expires 8 December 2026.
- [ ] Physical Android-device installation, touch/visual inspection, and performance testing remain outstanding; headless checks and APK export do not replace device QA.
- [x] PR #38 remains open, draft, and unmerged. No changes were merged into `main`.
- [x] Scope guard maintained: no Power Tower gameplay/system files were modified in the Baghdad runtime correction pass.


## User-approved Baghdad skyline identity and central Hunter Tower relocation — 24 November 2026

- Reassigned the former decorative central S-spire position to the real, functional Hunter Association Tower. The decorative S-spire and its S insignia are removed rather than left as a competing landmark.
- The five-tower Baghdad district remains geographically centered on the verified Republic Bridge/Tigris reference. The Hunter Tower keeps the bridge's surveyed X/Z anchor, while its physical base now sits on the uppermost circular sky-city platform surface at Y=419.2 m (the platform center is Y=418.0 m and is 2.4 m thick).
- The Hunter Association Tower remains 650 m tall and is now visibly the tallest central structure above the four surrounding upper-city district towers and the three circular sky platforms.
- Added four outward-facing illuminated XSX guild emblem plaques to the Hunter Tower facade, one on each cardinal side, with the Arabic identity “نقابة الصيادين العالمية”. The tower metadata identifies XSX as its guild insignia.
- Updated SYSTEM-WORLD/tools/validate_baghdad_towers.gd to require the 419.2 m upper-city crown placement, the functional Hunter Tower identity, four XSX facades, and the absence of the obsolete decorative S-spire.
- Updated SYSTEM-WORLD/tools/validate_baghdad_tower_operations.gd to replace the former S-spire assertion with checks for the central functional Hunter Tower and its XSX emblem.
- Updated BAGHDAD_TOWERS_APPROVED_EXPANSION.md so the approved vertical layout matches the user's direction while preserving the real Republic Bridge/Tigris geographic reference below.
- Source changes are on feature/baghdad-five-plus-power-tower-20261122 and PR #38 only. No merge to main was performed.
- Verification status: Godot 4.3 full validation and Android export for this exact architectural change are pending. Do not mark this relocation or the new XSX facade as verified until both workflows complete successfully. Physical Android visual/touch inspection remains outstanding.


## Hunter Tower proportion correction and approved exterior reference — 24 November 2026

- User approved reducing the central Hunter Association Tower from 1000 m to 650 m so it is more proportionate to the Baghdad upper-city architecture while remaining the tallest of the five connected district towers. The separate Power Tower remains an independent challenge destination and is not part of the five-tower skyline ranking.
- Updated HUNTER_TOWER_HEIGHT to 650.0 m; retained 200 floors, the 419.2 m upper-city crown platform base, the Republic Bridge geographic X/Z anchor, and the rooftop helicopter pad attached above the tower.
- Repositioned the Hunter Tower's three exterior advertising-screen tiers to 150 m, 340 m, and 530 m so none extends beyond the reduced tower height. XSX guild emblems remain on all four exterior sides.
- Updated tower validation to require a minimum 650 m Hunter Tower and to reject any other connected Baghdad district tower at or above 650 m. Updated the operations test's central tower height wording.
- Approved exterior concept image saved in the SYSTEM WORLD project Library at /SYSTEM WORLD/References/Baghdad_Towers_Hunter_Association_XSX_Approved_Exterior.jpg. This is a visual reference; it is not yet committed as a binary asset inside the GitHub repository.
- Latest code commit for the facade-height adjustment: 51b3dc54f7a06b363f5a63b9976e89782bfec216. Latest validator/operations commits: ad83c9c98d200fabb90d5c5905ec9c76d4c6e803 and d0387b702b8047e90908bcb3f33dd357bd525a94.
- Verification remains pending on this exact final height: rerun Godot 4.3 full validation and Android APK export before marking the reduced-height tower verified. No merge to main.

## Baghdad upper-city bridge and platform architectural detailing — 24 November 2026

- Confirmed the previous complete Godot validation and Android APK export both passed on commit `a3632d6773fbbe3b5c3aecba15e41b513074a496` (Godot run `45423988370`; Android run `45423988372`). Those results validate that exact earlier commit only.
- Added continuous dark-metal safety rails, evenly spaced balusters, and low-profile guide lights to pedestrian sky promenades, upper-city skyways, and Hunter atrium skyways. Vehicle decks remain separate and unchanged.
- Added illuminated perimeter guardrails and 32 evenly spaced balusters to each of the three circular sky platforms while preserving their approved radii, heights, locations, and luminous outer rims.
- Extended `validate_baghdad_towers.gd` to assert the upper platform guardrail metadata and the presence of safety rails on both upper-city and Hunter atrium skyways.
- The Hunter Tower remains unchanged at 650 m / 200 floors, base Y=419.2 m, rooftop helipad, four XSX facade identities, and exterior advertising tiers at 150/340/530 m. The saved exterior reference and five-tower district arrangement remain unchanged.
- New architecture and validator changes are on `feature/baghdad-five-plus-power-tower-20261122` / draft PR #38. The new commit requires fresh Godot validation and Android APK export; do not treat the earlier successful workflows as verification of these latest edits. No merge to `main`.

- Follow-up Hunter roof detailing: removed the generic solid crown from the Hunter Tower because it overlapped the approved rooftop helipad footprint; moved the rooftop beacon/core outside the landing circle and added illuminated architectural halo rings aligned to the 150/340/530 m advertising tiers.
- Extended the tower validator to require reserved helipad clearance, an offset rooftop beacon, all three advertising-tier halos, skyway edge rails, and the upper circular platform guardrail. These checks and all latest architectural edits are pending exact-HEAD workflow results.

- Rooftop clearance refinement: removed the central Hunter Association crown spire as well as the generic solid crown; replaced it with four diagonal perimeter beacon masts outside the helipad's 22 m landing circle. The validator now rejects either central crown/spire and requires all four perimeter masts.

- Godot runtime validation caught two issues in the first bridge/halo detailing pass: the skyway builder referenced a material local to a different function, and the advertising-tier loop needed an explicit float type. Both were corrected in the source; the next exact-HEAD Godot and Android runs must confirm the correction.

## Exact-HEAD Baghdad upper-city architecture verification — 24 November 2026

- [x] Godot 4.3 canonical runtime validation passed on exact commit `945784c8ac450f494d5282bcd263d132ca0d1d02`: run `45425531315`. All steps passed, including resource import/script parsing, main-scene launch, Baghdad landmark/lobby validation, the new skyway and upper-platform safety-detail assertions, Hunter tunnel riddle and physical entry, all seven Hunter examination stages, complete tower operations/elevator staff/emergency evacuation, terrain streaming, child-character safety, WGS84 anchor integration, and Star Gate/Greed Island checks.
- [x] Canonical Android APK export passed on the same exact commit: run `45425531332`. Artifact `14935739434` (`SYSTEM-WORLD-canonical-android-debug-apk`), 36,643,795 bytes, expires 8 December 2026.
- APK SHA-256: `dc87c68560d4fb17f34454663892db787bc3f3b9d5e8af02ad6ca714774fab26`.
- The final verified source includes 650 m / 200-floor Hunter Tower, clear rooftop helipad with four perimeter beacon masts, XSX identity on all four facades, advertising tiers and illuminated halos at 150/340/530 m, circular platform perimeter guardrails, pedestrian skyway safety rails and guide lighting.
- Physical Android-device visual/touch/performance inspection remains outstanding. An additional full-project workflow is still running; it is not being represented as passed.
- PR #38 remains open as a draft and unmerged. No changes were merged into `main`.

## User checkpoint — Baghdad towers through Hunter examination tunnel direction — 24 November 2026

- [x] Preserve the complete Baghdad five-tower district and independent Power Tower work already committed on this feature branch, including the verified Republic Bridge/Tigris geographic anchor, elevated sky-city platforms and skyways, Hunter Association Tower at 650 m / 200 floors, rooftop helipad clearance, four XSX guild facades, advertising tiers/halo rings, guardrails, balusters, guide lighting, tower interiors, commerce, staff, elevators, restaurants, hotel, and leisure/technology facilities.
- [x] Preserve the existing restaurant dine-in and kitchen/waiter/chef lifecycle; future tunnel access must extend this workflow and must not replace the restaurant system.
- [x] Preserve the latest exact-HEAD automated verification already recorded above: Godot 4.3 validation run 45425531315 and Android APK export run 45425531332 on source commit 945784c8ac450f494d5282bcd263d132ca0d1d02. These results apply only to that source snapshot; the later tracker-only checkpoint does not constitute new code verification.
- [x] Record the user's corrected Hunter examination access design: player orders a meal in the restaurant; the order/meal is routed to a dedicated room; that room contains an elevator that descends to one independent Hunter examination tunnel; a Hunter Association guide receives the player, explains the competition, assists and directs the participant, and issues a unique serial competitor number that persists across exits and re-entry.
- [x] Future additional access locations may be added as separate routes to the same tunnel under Hunter Association guide supervision.
- [x] Keep the Marshland area independent and unconnected to the examination tunnel for now; any connection is deferred to a future explicit design step.
- [ ] Implementation of the corrected room/elevator/guide/serial-number flow is pending. The currently committed secret three-inscription entrance and seven-stage exam flow are legacy code and conflict with this newly recorded direction; do not treat them as the approved design or claim the replacement is implemented.
- [ ] Next implementation pass must remove/disable only the conflicting secret-inscription/hidden-door and obsolete seven-stage dependencies while preserving the restaurant, tower, and all other verified systems. Add persistence and regression coverage for unique competitor numbering and re-entry.
- [ ] Run fresh Godot validation and Android APK export against the exact new implementation commit before marking the revised tunnel flow verified.
- PR #38 remains open, draft, and unmerged. Do not merge into `main` without the user's explicit approval.


### Hunter Examination tunnel access redesign — 24 November 2026
- Replaced the former three-clue secret doorway and concealed ramp concept with one permanent Hunter Examination tunnel.
- The Shopping Tower restaurant floor 29 now creates a dedicated competitor room. Access to that room is gated by the waiter's delivered meal; the existing restaurant order, waiter, chef and table workflow is retained. The served meal presentation is transferred from the dining table into the private room.
- The dedicated room contains a physical elevator platform and shaft leading to the tunnel. A return interaction is provided at the tunnel end.
- Added a visible Hunter Guild guide at the tunnel arrival point. The guide explains the competition and registers the player if needed.
- Candidate serial numbers remain stable after registration, including after a failed attempt or a later re-entry; the existing local ConfigFile persistence is retained.
- The new tunnel entry path does not connect to the marshland area. The former seven-stage exam definition was replaced by one continuous tunnel competition; the new elevator/guide flow does not activate a legacy stage runtime.
- Power Tower gameplay files were not modified. PR #38 remains a draft; no merge to main.
- **Verification status:** code changes committed; Godot validation and Android export must run on the exact resulting commit before this implementation is marked verified. Physical Android testing remains outstanding.

## Hunter Association Tower recruitment and guild-guide escort — 24 November 2026
- [x] Supersede the restaurant-meal/private-room/elevator access concept with the user's latest direction: the Hunter Association Tower is the discovery and recruitment point.
- [x] Added a player-arrival trigger in the Hunter Tower public lobby. Entering the lobby displays an Arabic invitation asking whether the player wants to become a Hunter and register for the Hunter Examination, with explicit accept/decline buttons.
- [x] Acceptance registers the candidate through the persistent Hunter Examination manager. Declining leaves registration untouched and allows the player to choose again on a later visit.
- [x] Added a visible Hunter Guild guide inside the tower lobby. After acceptance, the player is instructed to follow and interact with the guide.
- [x] The guide escorts the player from the Hunter Tower to the single permanent underground examination tunnel. Only at tunnel arrival does the manager complete candidate registration, allocate the serial, save it and reveal it to the player.
- [x] Re-entry reuses the saved candidate number; no second serial is allocated for an already registered player.
- [x] Removed the superseded Shopping Tower restaurant room, meal gate and elevator access implementation. Restaurant seating, orders, waiter and chef lifecycle remain independent and unchanged.
- [x] Marshland remains separate and unconnected. The former clue/secret-door route and seven-stage exam definition are not part of this tunnel access flow.
- [ ] Run the revised Hunter Tower recruitment regression and full Godot validation on the exact resulting HEAD.
- [ ] Run the Android APK export on the same exact HEAD; no fresh APK verification is claimed yet.
- [ ] PR #38 remains draft and must not be merged into `main` without explicit user approval.

### Hunter Tower recruitment regression and APK gate — 24 November 2026
- [x] The recruitment regression now tests automatic arrival invitation, explicit accept/decline controls, decline followed by re-entry, pending application persistence, no serial allocation before tunnel arrival, guide escort, serial allocation at the tunnel, manager recreation, and serial reuse on repeat registration.
- [x] The continuous-competition regression verifies the single tunnel competition definition and persistent serial behavior.
- [x] Both Hunter regressions passed inside the canonical Android workflow before APK export on branch commit `debb52cde928015e408b86ccb57c5e1b35fc1ad2`, run [45435296789](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45435296789).
- [x] Android APK export and artifact upload passed on that run. Artifact [14939624391](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/45435296789/artifacts/14939624391), size 36,638,608 bytes, SHA-256 `68d74d57fed9198ed568325f76af585363dce14391fc82a5cba8f03b1696f878`.
- [x] Local save persistence survives leaving/re-entering and manager recreation on the same installation. Global uniqueness across separate accounts/devices remains pending account/backend integration; it is not claimed by the local ConfigFile counter.
- [ ] Physical Android-device play inspection of the invitation layout, guide escort presentation and tunnel arrival remains outstanding.


## Hunter Examination rival competition — 24 November 2026
- [x] Added five distinct local AI rivals to the single continuous Hunter tunnel competition: deceiver, objective thief, individual fighter, ambusher and honorable competitor.
- [x] Connected rival interactions to the real exam runtime and routed rival events into the in-game interaction HUD.
- [x] Objective theft blocks further objective progression until the player recovers the stolen objective.
- [x] Added damageable rival combatants compatible with the existing modern-world hitscan damage interface; rivals retaliate through the player's existing combat-health component when a duel or ambush is active.
- [x] Fighter interaction starts an individual duel; ambusher can reveal itself and pursue the player. Team combat remains excluded.
- [x] Defeating the thief leaves a recovery interaction available so the stolen objective cannot become permanently inaccessible.
- [x] Added regression coverage for five rival spawns, objective theft and recovery, recovery after thief defeat, deception, individual duel activation, rival damage/defeat and rejection of unknown rival IDs.
- [x] Fixed the Hunter Tower recruitment validator's missing global-class resolution by explicitly preloading the manager script.
- [ ] Final rival-combat regression and full Godot validation are queued/running for code commit `0fc856cd1596da1c162baf98ec3d5ea285afcb88`; the subsequent `0ad3123af6efcb6482c879a66681fe8f9e15efd3` changes only this tracker. Do not mark the rival system fully verified until the matching code validation completes.
- [ ] Android APK export and upload for code commit `0fc856cd1596da1c162baf98ec3d5ea285afcb88` remain in progress; previous successful APKs do not verify these newer rival changes.
- [ ] Online multiplayer remains out of scope for this local AI implementation and is not claimed.
- PR #38 remains draft and unmerged. Do not merge to `main` without explicit user approval.


## Hunter rival competition — verified results — 24 November 2026

- [x] Canonical rival-specific regression passed on exact code commit `2b6eedf1d902dbc276ff22b2f8380c2a89fef5c3` in Godot workflow run `45439323604`.
- [x] The regression confirmed five AI rivals spawn in the canonical continuous Hunter tunnel; Ren steals a recorded objective and blocks progression; recovery restores progression; Kai's deception interaction and Daigo's individual duel/damage/defeat work; online multiplayer remains explicitly unclaimed.
- [x] The same comprehensive Godot run passed Baghdad tower operations, Hunter recruitment/escort/tunnel serial checks, the continuous competition regression, and the seven-stage Hunter examination checks.
- [x] Canonical Android APK export passed on the same exact commit in run `45439323724`; artifact `14941683919`, 36,648,875 bytes, expires 8 December 2026.
- [ ] Physical Android device inspection of rival movement, combat, ambush, and objective recovery remains outstanding.
- PR #38 remains a draft on `feature/baghdad-five-plus-power-tower-20261122`; do not merge to `main` without explicit user approval.


## Shopping Tower specialist floor-by-floor merchandise and display pass — 24 November 2026
- [x] Split the existing Shopping Tower department catalogs into floor-specific product selections while retaining the same purchase flow, wallet, rank/level/Nen requirements, vendor stock, inventory and sell controls.
- [x] Floors 5–7 now separate training/steel swords and knives, spears/axes/war hammers, and dual/long/great swords.
- [x] Floors 8–10 now separate bows/crossbows/arrows, hunter pistols/rifles/shotguns, and advanced precision firearms.
- [x] Floors 11–13 now separate shields/helmets/protective gear, field armour, and elite armour plus high-rank hunter outfits.
- [x] Floors 15–16 now separate common crafting supplies from rare cores, energy crystals and repair kits. Floor 14's forge and elixir laboratory are unchanged.
- [x] Floors 17–19 now separate basic healing/antidote, performance elixirs, and advanced wound/regeneration preparations.
- [x] Floors 20–22 now separate Nen awakening, control/focus/stabilization, and Nen recovery. Floors 23–26 separate advanced treatment, Nen laboratory stock, elite preparations and the protected rare-elixir vault.
- [x] Added floor-specific 3D showcase names and display geometry so each floor's weapon family, ranged equipment, armour tier, materials or elixir department is visually identifiable rather than repeating a generic display.
- [x] Added a comprehensive regression loop to open each specialist floor and assert its expected products are present and products belonging to other floors are absent; the existing floor-14 forge, hotel floors 27–28, and restaurant floors 29–32 remain outside these catalog overrides.
- [ ] Exact-HEAD Godot operations validation and Android APK export are pending. Physical Android touch/visual review remains outstanding.
- PR #38 remains draft and unmerged. No changes merged to main.

- Regression follow-up: the floor-by-floor UI test now waits one process frame after each department switch so queued UI nodes from the previous floor are released before asserting the new floor's exclusive stock list. This is test synchronization only; live floor changes already occur across separate player interactions.

- Added an end-to-end Shopping Tower weapon transaction regression: floor 5 purchase button, wallet/stock transaction, inventory receipt, equipment-slot assignment, equip and unequip. The test restores its temporary inventory/equipment/wallet/stock changes before later tower tests.

- Validator synchronization correction: the tower operations test is a `SceneTree` script, so its deferred UI cleanup waits use the native `process_frame` signal directly rather than a Node-only `get_tree()` call.


## Shopping Tower product-to-display mapping and elite outfit presentation — 24 November 2026
- [x] Every floor-specific display pedestal now carries the matching canonical catalog product ID as metadata, alongside its Arabic product label.
- [x] Added a dedicated elite Hunter outfit rack, coat silhouette, sleeves and rail to floor 13 beside its high-rank armour mannequins.
- [x] Expanded the tower regression to inspect signature 3D model components for each weapon, ranged, armour, crafting and elixir floor, and to require product-linked display metadata.
- [ ] Exact-HEAD Godot and Android verification for this visual/detail pass is pending.

- Floor 25 retains the elite legendary preparation in its advanced laboratory; floor 26 is now a stricter rare-elixir vault containing only the rare/legendary vault product, with the validator explicitly rejecting the elite preparation from leaking into that vault.


## Shopping Tower product display direct interaction and focused purchase preview — 24 November 2026
- [x] Each physical product display has a dedicated product-specific interaction target carrying the tower, floor, department and exact catalog product ID.
- [x] Routed product-display interactions ahead of generic department interactions in the main world interaction handler.
- [x] Added a focused preview service: interacting with a display opens its floor's normal purchase controls, hides unrelated product buttons, and shows the selected item's current price, required rank and stock.
- [x] Extended the end-to-end regression to interact with the physical floor-5 sword display, require the selected sword preview, hide unrelated products, purchase the sword, verify inventory receipt, equip it and unequip it.
- [ ] Exact-HEAD comprehensive Godot operations validation and Android export for this direct interaction path are pending.


## Shopping Tower interaction-target isolation and live purchase-control verification — 24 November 2026
- [x] Shopping department-wide interaction targets are positioned at the service counter, outside all product display interaction spheres; individual product displays remain directly selectable.
- [x] Focused product previews ignore queued-for-deletion controls when choosing the selected purchase button, preventing an earlier floor's same-ID product from intercepting the current selection.
- [x] Preview labels carry the exact selected catalog product ID. The dedicated showcase validator now checks the live visible selected purchase button, matching live preview, and hides unrelated purchase controls for every displayed product, including floor-4 skill permits.
- [ ] Exact-HEAD full Godot suite and APK verification for this interaction-isolation pass are pending.

- Floor-4 repair: if the Shopping Tower's skill-store floor was pre-created as a generic interior before the specialized facility existed, the floor resolver now adds the missing skill-store facility in place without replacing the existing room, floor deck, kiosks, elevator or evacuation route.

- Floor-4 collider repair: the in-place recovery now verifies the skill-store service Area3D and creates or repairs its named SphereShape3D collision child, metadata, collision layer and counter-side position when an older pre-created room is missing them.

- Collision-shape lookup is type-based rather than dependent on Godot's auto-generated child name; the floor-4 repair normalizes any recovered shape name and collision layers so older nodes are reliably repaired.

- Selected display controls are explicitly shown after resolving the current floor's live button, so a previously hidden skill-manual or product control cannot remain invisible when a different physical display is selected.

- Godot validation workflow concurrency now separates push and pull-request runs for the same feature branch, preventing the PR-triggered suite from cancelling the push-triggered full showcase regression before it executes.


### Baghdad towers — leisure pool zones and physical advertising panels — 25 November 2026
- Clarified the Entertainment Tower aquatic facilities as leisure/recreation, not sports competitions. The Olympic pool, family splash pool, spa hot tub and thermal pool water volumes carry `system_activity_category = leisure`; the pool signage now describes free swimming and water recreation rather than training.
- Added distinct monitored water-volume Areas for the family splash pool, spa hot tub and thermal pool, each routed through the existing swimming-state/surface-height callbacks. The original main pool volume and the existing pool movement system are preserved.
- Added physical emissive MeshInstance screen panels and metal frames behind the existing NPC-managed internal lobby campaign labels and external tower campaign labels. The existing rotating campaign text and staff attribution remain the content source.
- Extended the tower validator to require leisure metadata, active collision volumes and physical screen/frame nodes; added runtime enter/exit checks for the family, hot-tub and thermal leisure water volumes.
- Source commits: `acb3a2e9ca399c2c4663145cdb7774d8bc5e5b7e`, `719891959fcfad8b476c94c0dda2dd183f466a27`; validator commits: `1ca1652044c48f98aa38e37e6326a30d4c26ff70`, `2e2ebcf8c2858977b77a9d97f28a796d085f7c7b`.
- Restored the unrelated OSM streamer file to its pre-excursion baseline in commit `f1dc60fbac96e13e46611a91dd72c5bf91c9c5c5`; no OSM feature expansion is part of this tower task.
- Verification status: implementation and QA assertions are committed on the PR branch, but no CI status or workflow run is currently attached to exact HEAD `719891959fcfad8b476c94c0dda2dd183f466a27`. Do not mark these changes tested or APK-built until Godot validation and Android export complete.


### Baghdad tower advertising — campaign lifecycle and expiry tracking — 25 November 2026
- [x] Replaced anonymous rotating campaign strings with six stable campaign IDs and Arabic display copy for hunter equipment, healing elixirs, Baghdad shopping, leisure activities, SYSTEM laboratories and Power Tower challenges.
- [x] Added a 38-second campaign lifetime with elapsed-time catch-up, rotation counter and explicit start/expiry timestamps.
- [x] Every available internal and external tower campaign label now records its active campaign ID, responsible NPC manager, start time, expiry time and rotation number; each tower also records the synchronized campaign ID, expiry and rotation.
- [x] Exposed active campaign ID, rotation count and expiry through the tower operations status for QA and diagnostics.
- [x] Extended the Baghdad tower operations validator to check campaign identity, NPC manager attribution, expiry metadata on internal/external displays across all six towers, and synchronized rotation after a simulated 38-second expiry.
- [x] Exact-HEAD Godot tower operations validation, canonical runtime validation and Android APK export passed on code commit `503970ecf0f445d89fea75887d361076d0ae456c`; the tower validator also passed the 15 physical sky-garden bridge traversals and five elevator trips/returns. The subsequent documentation-only checkpoint does not alter runtime code.
- [ ] These remain locally managed in-world SYSTEM campaigns, not a live third-party ad network or monetized advertising integration.
- PR #38 remains draft and unmerged; no changes merged to `main`.

### Verified checkpoint — Baghdad advertising, hotel lifecycle and embedded Android Godot — 25 November 2026
- [x] Baghdad tower advertising uses six stable local campaigns, 38-second rotation, NPC manager attribution, start/expiry timestamps, scheduled campaign controls, revocation and safe fallback; tower operations QA passed.
- [x] Hotel checkout consumes at least the first night after check-in, refunds unused nights only, and keeps the room unavailable until housekeeping and inspection. Cancelling before check-in refunds the full stay without dirtying the room.
- [x] Added standalone hotel lifecycle validation for reservation, check-in, duplicate check-in prevention, room service, delivery state history, early checkout refund, housekeeping, inspection and pre-check-in cancellation.
- [x] Embedded canonical Godot 4.3 into the Android app through `SystemGodotActivity`, `SystemGodotFragment` and `SystemAndroidHostPlugin`; the plugin registers `SYSTEMAndroidHost` and forwards Firebase-authenticated marketplace calls with correlated request IDs.
- [x] Latest verified feature-branch commit: `503970ecf0f445d89fea75887d361076d0ae456c`.
- [x] CI passed: full Baghdad tower operations validator (including 15 physical sky-garden bridge traversals and elevator returns), standalone hotel lifecycle validator, shopping product routing, Hunter rival/escort/continuous tunnel tests, canonical Godot runtime, canonical Godot Android APK, native embedded Android APK, Firebase Functions TypeScript build and Firestore marketplace rules emulator tests.
- [ ] Still required: physical Android device test of Godot host and live Firebase marketplace round trip; deploy callable functions/rules/indexes only after explicit user approval; wire trusted game-server reward issuance and production wallet funding.
- PR #38 remains draft and unmerged; do not merge to `main` without the user's separate explicit approval.

---

## Canonical Baghdad five-tower correction and release audit — 25 November 2026

This entry supersedes earlier tower lists in this historical tracker where the fourth tower is named Entertainment, Sports or Leisure.

### Approved five-tower district
1. Hunter Association Tower.
2. Business and Investment Tower.
3. Shopping and Commerce Tower.
4. Antiques and Heritage Tower.
5. Technology and Innovation Tower.

The Antiques and Heritage Tower replaces the former Entertainment/Sports Tower as the fourth connected Baghdad tower. Pools, gardens and leisure activities are independent district amenities, not a sixth tower and not a reason to restore an Entertainment/Sports tower. The Power Tower remains a separate 200-floor challenge landmark outside the five-tower district.

### Verified source-level state
- The runtime registry/customer population uses the five approved tower IDs; the fourth ID is `antiques_heritage_tower_baghdad`.
- The Antiques and Heritage Tower is a 34-floor foundation/blockout with museum departments and player-marketplace/auction zones in its floor directory. Its metadata still says `antiques_heritage_tower_foundation_blockout`; do not call the complete museum experience finished.
- Three walkable sky gardens are generated for each approved tower (15 total), with physical deck/collision/railing/planting/seating and elevator-destination interaction metadata. Prior tracker entries report QA traversal; current-head regression must be rerun before release.
- Advertising panels and local campaign rotation/expiry/manager attribution exist. They are in-world SYSTEM campaigns, not a deployed external advertising network.
- Hotel booking, housekeeping, inspection and room-service flows are local-save prototypes. They are not shared online reservations.
- Firebase callable marketplace functions, server-side transaction logic, restrictive Firestore rules, security emulator tests and the Android/Godot request-ID bridge exist. Production deployment and a live two-account/two-device trading round trip remain release gates.
- Hunter candidate serial persistence is local to the installation, not globally unique across accounts/devices.
- NPC customers and lobby staff routines exist, but full autonomous cross-floor navigation and server-synchronized populations are not claimed.

### Exact-head CI snapshot at audit time
Feature HEAD: `cd3e3d1769af01e611e744c9ec46a2a8ab227475`.
- Firebase Marketplace Functions: success.
- Android App Shell: success.
- Canonical Android APK build: success.
- Full Godot project validation: in progress; no pass is claimed for this exact HEAD until completion.

### Release gate
Keep PR #38 draft and unmerged until the exact latest head passes Godot validation and Android build, the Antiques tower and all Baghdad systems are covered by current regression checks, the online marketplace deployment/round-trip decision is resolved, and physical Android QA is completed. No merge into `main` without the user's explicit approval.


## Public recreation audit — independent leisure venues remain an implementation gap — 25 November 2026

This audit supersedes any older tracker wording that could be read as proof that the pools are fully playable after the former Entertainment/Sports tower was removed from the canonical five-tower registry.

- The five-tower runtime registry correctly contains Hunter Association, Business and Investment, Shopping and Commerce, Antiques and Heritage, and Technology and Innovation. There is no `entertainment_tower_baghdad` entry in `TOWER_CONFIG`.
- The legacy pool builder still contains geometry and water-zone code for `swimming_pool`, but the current five-tower floor resolver does not assign that facility to any approved tower. The operations validator explicitly says recreation/sports are independent venues and excludes them from its tower acceptance pass.
- Three remaining service paths still look up the removed `entertainment_tower_baghdad` ID: pool staff positioning, pool locker release, and lifeguard dispatch. These paths cannot be considered reliable under the current canonical registry.
- `ConnectedCityPublicAmenities_Blockout` currently creates amenity deck meshes and a `planned_facilities` metadata list. That metadata is a plan, not proof of live swimming pools, working water volumes, public-service interactions, staffing or navigation.
- No standalone public recreation/pool runtime manager or dedicated public-leisure acceptance validator was found in the current repository tree during this audit.
- Required next implementation: create the public recreation venues as independent district facilities (not a sixth tower and not attached to Antiques Tower), wire the pool water volumes, player swimming state, locker reservation/release, lifeguard response, entry/exit and public navigation, then add a dedicated end-to-end Godot validator. Do not simply rename the old tower ID or count the old blockout deck as completion.
- Current status: **not complete; implementation and dedicated validation required**.

### Current CI for canonical documentation/source checkpoint
Feature HEAD at audit update: `f2522b6a3cf603e3aa13ee1bd17ee0ee9e7fba99`.
- Firebase marketplace rules compilation and TypeScript build: success.
- Android App Shell: success.
- Canonical Android APK export: success.
- Godot comprehensive validation: queued behind an earlier comprehensive run; no exact-HEAD Godot pass is claimed.
- PR #38 remains draft and unmerged. No changes merged to `main`.


### Public event/champion display routing correction — 25 November 2026
- [x] Found that `system_public_event_board.gd` still mapped the retired `entertainment_tower_baghdad` ID to the old `EntertainmentTower` node. Since the tower positions now expose `antiques_heritage_tower_baghdad`, the Antiques and Heritage Tower was skipped by this event-board display loop.
- [x] Replaced that stale mapping with `antiques_heritage_tower_baghdad` → `AntiquesHeritageTower`, so its advertising/champion display surfaces are addressed using the canonical fourth tower identity.
- [x] Added an authoritative correction section to `HUNTER_TOWERS_AND_EXAMINATION_DESIGN.md`: Business and Investment remains; weapons/elixirs remain Shopping Tower departments; Antiques and Heritage is tower four; recreation stays independent; Power Tower stays standalone.
- [ ] Exact-HEAD Godot validation of the public event-board tower display routing is pending.

## Independent Baghdad public leisure district — runtime implementation checkpoint — 25 November 2026

- [x] Added `system_baghdad_public_leisure_manager.gd` and instantiate it as `BaghdadPublicLeisureDistrict` under the connected-city public amenities root. It is a separate public district facility, not a sixth tower and not part of Antiques and Heritage Tower.
- [x] Added physical public plaza/pool deck geometry for an Olympic lap pool, family leisure pool and thermal pool, with three monitored Area3D water volumes and collision shapes.
- [x] Water-volume entry/exit records and clears the canonical `system_player` swimming-state metadata and the selected pool type/depth. This is water-zone state detection; full swimming locomotion/animation and aquatic gameplay remain a separate implementation task.
- [x] Added two public changing suites with 16 individually reservable lockers, shower service interactions, and suite-specific locker release so duplicate locker names in separate suites cannot release the wrong locker.
- [x] Added a lifeguard station/NPC and a response tween for player assistance requests. Pool service interactions use the existing `system_pool_service_type` routing in the main interaction handler.
- [x] Added an eight-segment collidable access ramp and a collidable ground-arrival plaza so the elevated leisure deck has a physical approach from ground level.
- [x] Replaced stale locker-release and lifeguard dispatch lookups for the deleted `entertainment_tower_baghdad` with calls to the independent public leisure manager, and removed the final retired pool-supervisor tower-floor placement branch.
- [x] Added `tools/validate_baghdad_public_leisure.gd` to instantiate the actual main scene and check district integration, pool volumes, swim-state entry/exit, the access ramp and collision, locker release, shower/locker interaction surfaces and lifeguard dispatch; added its parser and runtime invocation to the Godot validation workflow.
- [ ] Exact-HEAD Godot CI has not yet completed for this implementation. Do not claim the new validator passed until its workflow step finishes successfully.
- [ ] Remaining gameplay work: connect the swim-state to player movement/animation and stamina, add actual pathfinding to the public district and staffed service schedules, and complete in-device collision/interaction testing.
- PR #38 remains draft and unmerged; no changes merged to `main`.

### Dedicated Antiques Tower advertising manager — 25 November 2026
- [x] Added a ninth Antiques and Heritage Tower employee with the explicit `advertising_manager` job while retaining the museum guest-services role.
- [x] Campaign display attribution now records both the responsible NPC name and the manager's job ID. The tower operations validator requires `advertising_manager` on every internal/external campaign display, including Antiques Tower.
- [x] Updated the full expected staff total from 45 to 46 and the Antiques Tower lobby expectation from eight to nine employees.
- [ ] Exact-HEAD Godot validation of the expanded employee roster and campaign-role assertion is pending.

## Follow-up runtime verification — pool physics, Hunter helipad and CI import — 25 November 2026

- [x] Replaced the public-leisure overlap regression's direct callback invocation with real overlapping Area3D volumes, collision masks derived from the canonical player layer, physics-frame waits, and actual player repositioning. The test verifies both zones enter, the smaller zone exits while the larger remains active, and the final exit clears all swim metadata.
- [x] Exact feature-branch Godot workflow run 45569038832 reached and passed the dedicated step “Validate independent Baghdad public pools, lockers and lifeguard services” on commit 633d87646a995b801fade10cc36906026a26f331. The overall workflow was still running other independent validations at the time of this note.
- [x] Hardened remaining-zone selection in system_baghdad_public_leisure_manager.gd by selecting through an explicit key array rather than indexing Dictionary.values() by size.
- [x] Extended validate_baghdad_towers.gd to require the Hunter rooftop helipad's circular deck collision, collidable access bridge, landing ring, H markings, eight perimeter lights, controller status and aircraft assemblies.
- [x] Made the deck and bridge collision-shape node names and collision layers explicit in baghdad_tower_landmarks_manager.gd. The canonical runtime validation passed the Baghdad tower/helipad validator on the feature branch.
- [x] Corrected premature Godot editor shutdown in canonical-godot-validation.yml and system-world-android-export.yml: use --import instead of --quit so the editor completes resource import. The subsequent canonical runtime run reported no aborted import scan and no missing character-GLB loader messages.
- [x] Canonical Godot runtime validation completed successfully on commit fdee73e01cf26228fc0b788e799d12631301ddba; canonical Android APK export, SYSTEM WORLD Android game export, Android app-shell build, Firebase Functions TypeScript build and Firestore rules emulator workflow also completed successfully on the later feature checkpoint 633d87646a995b801fade10cc36906026a26f331.
- [x] Separate runtime mesh diagnostic step completed successfully on workflow run 45569038832, including the initial scene and all four world switches; it found no MeshInstance3D with a null mesh and no MultiMesh with a null resource (otherwise the diagnostic exits non-zero).\n- [ ] The canonical headless runtime still logged 46,574 dummy-renderer messages, “Parameter m is null” at mesh_get_surface_count, after the import correction. These were not accompanied by missing GLB-loader messages or an aborted import scan. The renderer messages remain unexplained; do not conflate them with missing MeshInstance3D resources or call the renderer clean.
- [ ] The dedicated godot-system-world-validation workflow was still executing the remaining tower-operations, hotel, shopping showcase and Hunter validations; no overall workflow pass is claimed here.
- [ ] Marketplace activation remains gated by callable-function emulator tests, trusted reward-event integration, production deployment/scheduler activation and a real two-account Android device round trip. A TypeScript build and Firestore rules tests do not prove live player-to-player settlement.
- PR #38 remains draft and unmerged. No changes merged to main.

## Exact feature checkpoint verification — 25 November 2026

- [x] Commit `b59d746bedc45a90621cab803b4ca408de54e36a`: canonical Godot runtime workflow `45570191591` completed successfully. Its steps passed project import/parse, Android marketplace bridge request correlation, Baghdad tower landmarks/lobby, Hunter recruitment and guide escort, continuous Hunter Examination competition, tower operations/elevator staff/emergency evacuation, terrain streaming seam/lifecycle, child-character safety, Baghdad WGS84 anchor integration, Baghdad-only Star Gate/Greed Island exit, marketplace Android bridge protocol, and headless main-scene launch.
- [x] Commit `b59d746bedc45a90621cab803b4ca408de54e36a`: BBBike Iraq PBF and Baghdad boundary candidate workflow `45570191583` completed successfully. It produced artifact `SYSTEM-WORLD-Baghdad-OSM-boundary-candidate` (artifact ID `15002255160`; SHA-256 `bb0c1fd6ab2fcd00be459e1416d0055e3f4b303e0027ab59ebda01cd1947da2f`). This verifies the source/boundary candidate workflow; it is not a claim that every city building has final production geometry.
- [x] Commit `b59d746bedc45a90621cab803b4ca408de54e36a`: Firebase marketplace Firestore rules emulator and Cloud Functions TypeScript build both completed successfully (workflow `45570202696`).
- [x] Commit `b59d746bedc45a90621cab803b4ca408de54e36a`: explicit `Vector3` typing correction committed in `validate_baghdad_towers.gd` to resolve the prior inferred-type parser failure. The exact-commit comprehensive Godot workflow `45570202688` passed the dedicated “Validate Baghdad tower landmarks and lobby systems” step, which executes the helicopter parked-clearance, S-rank/A-rank pilot authorization, actual takeoff movement, and exit/player-restoration assertions.
- [ ] Exact-commit comprehensive tower operations validation on `b59d746` is still running through advertising/NPC commerce/Power Tower, hotel, shopping showcase, and Hunter competition checks.
- [x] Exact-commit canonical Android APK build/export completed successfully (workflow `45570202710`); artifact `SYSTEM-WORLD-canonical-android-debug-apk` ID `15000764848`, SHA-256 `07880fef95b9d99e0c47acf90cdb31bbd82a6846db9b2c82f251885d30816a79`.
- [x] Exact-commit native Android App Shell build and APK upload completed successfully (workflow `45570202819`); artifact `SYSTEM-native-android-debug-apk` ID `15001409347`, SHA-256 `ff0e6256f64e498ed3a124d026982d1f69944e0d63857455d70960628b1a8b71`.
- [ ] Renderer `mesh_get_surface_count` / `Parameter "m" is null` warnings remain an open issue: the canonical runtime log for `b59d746` (job `139054661380`) contains 46,622 occurrences. The null-MeshInstance/MultiMesh diagnostic passing does not prove renderer warnings are fixed.
- [ ] Player-to-player marketplace remains unproven in a real two-account Android round trip; successful TypeScript and Firestore rules tests are not live transaction settlement.
- PR #38 remains draft and unmerged; no changes merged to `main`.


### Antiques Tower museum exhibits and marketplace emulator verification — 25 November 2026
- [x] Replaced the Antiques Tower's museum-only floor metadata with 34 generated gallery-floor nodes and 102 named physical 3D exhibit stands. Every exhibit has a stable artifact ID, visible title, tower/floor/department metadata, and a collidable `Area3D` interaction tagged `inspect_artifact`.
- [x] Added a runtime regression audit that checks all 34 floors, all 102 unique exhibit IDs, 3D meshes/pedestals/titles, interaction areas/collisions and matching ownership/floor metadata. The current Godot validation run `45604503822` reached and passed the Baghdad tower validator on the new code.
- [x] Marketplace Firestore rules emulator tests passed: 7/7. Callable marketplace transaction/emulator tests passed: 8/8 on workflow `45604503727`; includes fixed-price escrow/purchase, atomic buyer debit and seller credit, ownership transfer, self-purchase and insufficient-balance rejection, concurrent double-purchase race, cancellation/expiry, auctions, two-player exchanges, trusted reward replay protection and scheduled expiry workers.
- [x] The TypeScript Cloud Functions build and Firestore rules compilation passed on the same workflow.
- [ ] Still required before calling online trading live: trusted game-server claim and quest-reward source integration, production deployment/monitoring of functions and scheduled workers, and a real two-account Android device round trip. Do not deploy or merge without the user's separate approval.


## Godot 4.3 headless dummy-renderer root-cause investigation — 27 November 2026

- [x] Exact PR #49 head `77cddc9d7cecab73131d7f59469eb6d5390dbbbd`: the canonical Godot 4.3 diagnostic log contains 55,991 occurrences of `ERROR: Parameter "m" is null` at `mesh_get_surface_count`, across OSM runtime, child-character QA, main-scene launch, world-switch diagnostics, companion/NPC validation and Hunter tunnel tests.
- [x] The scene diagnostic inspected 19,572 MeshInstance3D nodes and 130 MultiMeshInstance3D nodes. It found zero null mesh references, zero invalid mesh RIDs, zero zero-surface meshes and zero invalid MultiMesh resources in the initial scene and after each of the four world switches.
- [x] Matched the exact error to upstream Godot issue #86806. Godot maintainers identified the cause as a Mesh resource being freed before its MeshInstance, then fixed Dummy RenderingServer dependency tracking in merged PR #102261. The issue is reproducible in Godot 4.3; the canonical project remains pinned to 4.3 for now.
- [ ] Run the same complete scene/world-switch diagnostic with Godot 4.4.1, which contains the upstream fix, and record the exact remaining error count. This is a compatibility comparison only; do not change the canonical Android/export engine version until import, runtime, gameplay QA and Android export have all passed on the candidate version.
- [ ] Keep the 4.3 dummy-renderer error visible in CI logs. A zero-null-mesh scan is not evidence that the headless renderer is clean.
- [ ] Physical Android visual inspection and real-device frame-time/memory profiling remain separate acceptance requirements.
