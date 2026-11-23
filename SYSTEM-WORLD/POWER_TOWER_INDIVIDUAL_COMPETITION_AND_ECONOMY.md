# SYSTEM WORLD — Power Tower individual competition and economy

Status: approved design and active implementation checkpoint
Date: 23 November 2026
Canonical branch: `feature/baghdad-five-plus-power-tower-20261122`
Pull request: #38 (draft; do not merge without explicit user approval)

## 1. Canonical tower identity

- Power Tower is a standalone optional challenge landmark in Baghdad, outside the five connected civic towers.
- It contains exactly 200 sequentially unlocked floors.
- The player must clear the previous floor before entering the next one.
- The 200th floor is the unique final sovereign boss encounter.
- Preserve existing progress records, clear times, ranks, loot, XP and virtual-credit rewards.

## 2. Individual-only combat rule

Every Power Tower combat competition is individual:

- One participating fighter versus exactly one opponent (1v1).
- Exactly one opponent and one round per floor.
- No team battles, party battles, squad competitions, multi-opponent rounds, enemy waves or group combat competitions.
- Elite floors and boss floors remain individual duels; difficulty changes through opponent attributes and boss mechanics, not opponent count.
- The final sovereign encounter is one player against one final boss.
- Spectators, supporter clubs, social groups and public viewing remain non-combat activities and do not form fighting teams.

Runtime acceptance criteria:
- Each floor record declares `competition_format = INDIVIDUAL_1V1`.
- `opponent_count = 1`, `wave_count = 1`, and `time_limit_seconds = 0`.
- Allowed arena types are `DUEL`, `ELITE_DUEL`, and `BOSS_TRIAL`.
- The runtime spawns one opponent and completes the floor when that opponent is defeated.
- Floor 200 retains its unique final-boss profile and rewards.

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
- The gallery is for viewing individual duels only; it does not create combat teams or alter the 1v1 rules.
- The tower career record persists total individual duel wins, elite-duel wins, boss-duel wins, lifetime XP earned and lifetime virtual credits earned.
- The Power Tower lobby progress board displays the 1v1 format, floor progression, duel wins, elite/boss wins, lifetime credits and best clear time.
- Seat reservation/standing interactions, autonomous audience NPCs, live match spectator cameras and prediction terminals are separate follow-up work; the current 48-seat gallery is a physical visual seating prototype.

## 5. Progression and rewards

- Floors unlock sequentially and retain the player's saved highest-cleared floor and per-floor clear-time records.
- Level requirements remain reachable within the existing level-100 progression cap.
- XP, rank, loot and SYSTEM virtual credits scale with floor difficulty.
- Every successful floor clear grants its configured credits to the player's in-world wallet; the wallet can be used in supported SYSTEM WORLD commerce such as food, drink, lodging and equipment.
- The final floor retains its sovereign crown, sovereign core, rare core and Nen fragment rewards.
- A failed or abandoned attempt does not grant the floor-clear reward and does not erase previously earned wallet balance.

## 6. Spectators and match predictions

Approved design:
- Spectators may watch an individual duel in person or through supported public displays.
- Before a duel starts, a spectator may select which of the two fighters they expect to win.
- Predictions close before the match begins and cannot be edited after lock.
- Correct predictions grant non-transferable in-world spectator points or cosmetic/community progression.
- A fighter cannot predict their own match; account abuse and duplicate-account manipulation must be mitigated.
- Predictions never use real money, never transfer money between players and never affect combat results.
- Spectator rewards are separate from the fighter's floor-clear reward budget and wallet.

Implementation note: the spectator prediction feature is approved design, not yet claimed as a completed live online service. Match identity, prediction locking, reward settlement and anti-abuse enforcement must become server-authoritative before public online release.

## 7. Fair access

- Free and paying players can enter, progress, earn floor rewards and reach the highest ranks through gameplay.
- Payments may offer cosmetics or convenience only; they cannot purchase wins, opponent outcomes, rank skips or exclusive combat power.
- No real-money betting or player-to-player wagering is permitted.

## 8. Technical boundaries and verification

- Current tower wallet, floor rewards, commerce and activity systems are local-save prototypes; they are not yet a server-authoritative shared online economy.
- Online matchmaking, authoritative match settlement, anti-cheat and spectator prediction service remain separate future integration work.
- Godot full validation and Android export must be checked against the exact same branch commit before marking a gameplay milestone verified.
- Physical Android touch, visual and performance inspection remains a separate required check.
- Keep PR #38 as draft. Never merge into `main` without explicit user approval.
