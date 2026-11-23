# SYSTEM WORLD — Power Tower individual competition and economy

Status: approved design and active implementation checkpoint
Date: 23 November 2026
Canonical branch: `feature/baghdad-five-plus-power-tower-20261122`
Pull request: #38 (draft; do not merge without explicit user approval)

## 1. Canonical tower identity

- Power Tower is a standalone optional challenge landmark in Baghdad, outside the five connected civic towers.
- It contains exactly 200 sequentially unlocked floors.
- The player must clear the previous floor before entering the next one.
- The 200th floor is the unique final sovereign title duel against a human title-holder.
- Preserve existing progress records, clear times, ranks, loot, XP and virtual-credit rewards.

## 2. Individual-only combat rule

Every Power Tower combat competition is an individual human-versus-human duel:

- One authenticated human player versus exactly one other authenticated human player (1v1).
- Exactly one human opponent and one round per floor.
- No team battles, party battles, squad competitions, multi-opponent rounds, enemy waves or group combat competitions.
- AI combat opponents, AI bosses and bot fallback are prohibited, including when online matchmaking is unavailable.
- Elite floors are individual ranked duels; every tenth-floor title-holder challenge and the floor-200 sovereign title duel are also human 1v1 matches.
- Spectators, supporter clubs, social groups and public viewing remain non-combat activities and do not form fighting teams.

Runtime acceptance criteria:
- Each floor record declares `competition_format = INDIVIDUAL_1V1`, `opponent_kind = HUMAN_PLAYER`, `matchmaking_mode = ONLINE_1V1` and `ai_fallback = false`.
- `opponent_count = 1`, `wave_count = 1`, and `time_limit_seconds = 0`.
- Allowed arena types remain `DUEL`, `ELITE_DUEL`, and `BOSS_TRIAL`; boss arena means a human title-holder duel, not an AI boss.
- Floor entry may display the arena while waiting, but combat begins only after an authenticated human match is supplied by the online match authority.
- If matchmaking is unavailable, show a clear waiting/unavailable state. Never spawn a bot or simulate a result.
- Floor 200 retains its unique sovereign title-duel profile and rewards, which are granted only after a trusted human-versus-human result is verified.

### 2.1 Registration, referees, scoring and career discipline

The tower adapts the recognizable tournament structure of an anime-style martial-arts arena while keeping SYSTEM's own 200-floor identity, Baghdad setting, combat engine and economy. It does not reproduce anime dialogue, character identities, scenes or visual assets.

- Every entrant registers at the official desk, receives a persistent fighter number and a division record, then is called to a named arena and waiting room.
- The 200 floors are grouped into twenty ten-floor divisions. Floor profiles expose their division number and division range; floor 100 grants eligibility for a private fighter room; weapons are enabled only for the final floor-200 challenge.
- A three-official panel supervises each duel: a head referee, a technical judge and a safety judge. The head referee controls the start, pauses, stoppages and final declaration; judges record valid scoring events and the safety official may stop an unsafe fight.
- A clean hit awards 1 point, a critical hit awards 2 points, and forcing the opponent down awards 1 additional point. Reaching 10 points ends the match by technical knockout (TKO). A knockout (KO), judges' decision, forfeit or referee stoppage are also supported endings. The arena has no ordinary round timer; a safety stoppage overrides the no-timer rule.
- Every score event requires an authorized official, a valid fighter identity and a unique event ID; duplicate score events are rejected. The result must come from the configured match authority before career penalties or rewards are applied.
- A normal verified win advances the fighter through the floor ladder. Three consecutive verified losses demote the fighter by one ten-floor division. Ten cumulative verified losses disqualify the fighter from the tower circuit and reset unlocked tower progress to the entry floor. Earned XP, inventory and wallet credits are not confiscated. A verified win breaks the consecutive-loss streak.
- The loss record and disqualification state persist between sessions. A disqualified fighter cannot request another floor until an authorized tower reinstatement process is added.
- The public boards and each arena display show the division, judge panel, point values, TKO threshold and loss penalties so competitors and spectators know the rules before a match.
- Spectator predictions remain a separate virtual-credit pool. They do not affect the judges, score, opponent selection, fighter rank or match result.

## 3. Floor environment progression

The 200 floors are arranged into ten visual environment chapters, with twenty floors per theme:

1. Iron Hall
2. Desert Arena
3. Frost Field
4. Volcanic Ring
5. Warrior Forest
6. Royal Ruins
7. Storm Arena
8. Shadow Field
9. Celestial Arena
10. Sovereign Throne (final chapter; floor 200 has the unique sovereign boss arena)

Each chapter changes its floor-deck material, arena ring, four environmental pylons, obstacle palette and Arabic/English arena title. Environment variety never changes the individual 1v1 rule or introduces extra opponents.

## 4. Arena spectators and career record

- Each generated duel arena includes a physical spectator gallery with 48 fixed seats, collision, stable seat IDs, floor metadata and an initially unreserved state.
- The gallery is for viewing individual human-versus-human duels only; it does not create combat teams or permit AI combat substitutes.
- The tower career record persists total individual duel wins, elite-duel wins, boss-duel wins, lifetime XP earned and lifetime virtual credits earned.
- The Power Tower lobby progress board displays the 1v1 format, floor progression, duel wins, elite/boss wins, lifetime credits and best clear time.
- Seat reservation/standing interactions, autonomous audience NPCs and live match spectator cameras remain follow-up work; the 48-seat gallery is a physical seating prototype, and a working local virtual-ticket terminal is now installed in the public lobby.

## 5. Battle displays — outside, lobby and every active arena floor

- A physical battle-results/schedule display is installed outside the Power Tower entrance and another inside its public lobby.
- Both boards publish the full 200-floor schedule in ten chapters of twenty floors, identifying every standard duel, elite duel, boss duel and the unique sovereign final duel on floor 200.
- The display makes the shared rule explicit: every competition remains individual 1v1; there are no team or group fights.
- Every generated arena floor also receives its own physical battle-screen panel and floor-specific title/rules, so the current floor's duel type is visible inside the arena.
- The schedule is generated from `get_floor_data()` rather than a separately hard-coded list, keeping display categories aligned with runtime floor definitions.
- These are in-world 3D display boards; they do not imply that online matchmaking, a live global event feed, or server-authoritative match broadcasting is already available.

## 6. Progression and rewards

- Floors unlock sequentially and retain the player's saved highest-cleared floor and per-floor clear-time records.
- Level requirements remain reachable within the existing level-100 progression cap.
- XP, rank, loot and SYSTEM virtual credits scale with floor difficulty.
- A floor reward is granted only after the match authority verifies a completed human-versus-human 1v1 result and confirms that the local player won. An unverified/local/AI result never grants floor XP, loot, rank or credits.
- Verified rewards are added to the player's in-world wallet and can be used in supported SYSTEM WORLD commerce such as food, drink, lodging and equipment.
- The final floor retains its sovereign crown, sovereign core, rare core and Nen fragment rewards.
- A failed or abandoned attempt does not grant the floor-clear reward and does not erase previously earned wallet balance.

## 7. Spectators and virtual ticket pools

Approved design:
- Spectators watch individual 1v1 duels and may select which of the two fighters they expect to win.
- Each fan commits a ticket stake of 1–500 virtual SYSTEM credits from the shared in-world wallet. The stake is deducted when the ticket is accepted and contributes to the match pool.
- A fan may enter one ticket per match, with a daily cap of 20. Fighters cannot enter tickets on their own match.
- Before combat starts, the match authority locks the ticket pool. No edits or late tickets are accepted.
- After a trusted result, the full pool is distributed proportionally among correct tickets. Winners receive a gross virtual payout and a separately displayed net profit. Incorrect tickets lose only their virtual stake.
- If no fan selected the actual winner, every stake is refunded. Payout rounding is resolved so the total paid equals the pool.
- All tickets, stakes and winnings are virtual SYSTEM credits only. They cannot be bought as tickets, gifted, transferred to another player, withdrawn or converted to real money. No real-money betting or cash prizes.
- NPC fans may enter as clearly labelled simulated identities with a fixed, persisted 300-credit virtual ticket budget. Their winnings remain in NPC-only balances; never present them as real users or live global participants.

Implementation status: a local prototype now records individual 1v1 matches, deducts virtual ticket stakes through the shared local SYSTEM wallet, locks one ticket per fan, settles the complete pool proportionally from the local match-authority path, refunds the pool when no ticket selected the winner, and persists the gross payout/net-profit ledger. Clearly labelled NPC spectators can also stake from a separate fixed virtual budget and receive winnings only into NPC-only balances. It rejects fighter self-prediction, duplicate tickets, invalid selections, late submissions, insufficient balances and submissions beyond the daily cap. This remains a local prototype: account-level wallet isolation, automated NPC crowd selection, live online matchmaking, server-authoritative combat results, anti-cheat/anti-collusion, global rankings and cross-device persistence are not yet implemented. A lobby terminal now lets a local player select an open match, choose one of its two fighters and stake 1–500 virtual credits; each registered judged duel automatically opens its corresponding spectator pool and locks/settles accepted tickets when the official result is recorded.

## 8. Fair access

- Free and paying players can enter, progress, earn floor rewards and reach the highest ranks through gameplay.
- Payments may offer cosmetics or convenience only; they cannot purchase wins, opponent outcomes, rank skips or exclusive combat power.
- No real-money betting or player-to-player wagering is permitted.

## 9. Technical boundaries and verification

- Current tower wallet, floor rewards, commerce and activity systems are local-save prototypes; they are not yet a server-authoritative shared online economy.
- The human-only matchmaking and match-result hooks are prepared, but the online matchmaking service is not active yet. Until it is connected, the tower must show a waiting/unavailable state and never spawn AI combat opponents. Authoritative result signatures, anti-cheat, anti-collusion and cross-device economy remain future integration work.
- Godot full validation and Android export must be checked against the exact same branch commit before marking a gameplay milestone verified.
- Physical Android touch, visual and performance inspection remains a separate required check.
- Keep PR #38 as draft. Never merge into `main` without explicit user approval.


## 10. Live referee and arena display integration

- Each generated arena now contains three physical official podiums with role labels (head referee, technical judge, safety judge), a match-rules screen and a live score/result label.
- The Power Tower manager publishes score-update and duel-completion signals. The main game connects these signals to the Baghdad tower operations manager, which updates the matching floor's live arena display with both fighter IDs, current points, match state and verified winner.
- The outside entrance board and public lobby board list all ten-floor divisions and the published scoring/loss rules. Each arena screen identifies its own floor and division.
- The referee scoring and career discipline are local prototype logic. The `LOCAL_COMBAT_AUTHORITY` gate is not a substitute for a remote trusted server; online human matchmaking, signed judge events and server-side career persistence remain future integration work.


## 11. Spectator ticket terminal and match lifecycle

- A physical interactive virtual-ticket terminal is placed in the public lobby. Interacting with it opens the in-game betting panel.
- The panel lists open 1v1 matches, shows each floor, both fighters and the current pool, lets the spectator choose one fighter and stake 1–500 SYSTEM credits, and confirms or rejects the ticket with a clear reason.
- Registering a judged duel automatically registers its spectator pool. Once the referee settles the duel, the manager locks the pool and distributes the virtual pool proportionally to correct tickets; losing tickets receive no payout and no-correct-ticket pools are refunded.
- This terminal is local gameplay UI. It does not connect to a global online betting exchange or real-money payment service.


## 12. Public live match display updates — 23 November 2026

- The outside entrance display and public-lobby display retain the complete floor schedule and now also have a dedicated live-match broadcast panel.
- When the arena reports a duel score or verified completion, the same match ID, floor, two fighter IDs, current score and live/completed state are pushed to both public panels as well as the active arena's score display.
- The public panels explicitly label the content as a live individual 1v1 match and show the verified winner only after completion.
- Regression validation checks that a floor-200 result reaches both the outside and lobby panels with the correct floor and winner.
- Scope: this update is a live score/result broadcast, not a camera-video stream. Live spectator camera/video routing and remote/global match feeds remain unimplemented and must not be represented as available.
