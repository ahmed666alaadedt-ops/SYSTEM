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
- Seat reservation/standing interactions, autonomous audience NPCs, live match spectator cameras and prediction terminals are separate follow-up work; the current 48-seat gallery is a physical visual seating prototype.

## 5. Progression and rewards

- Floors unlock sequentially and retain the player's saved highest-cleared floor and per-floor clear-time records.
- Level requirements remain reachable within the existing level-100 progression cap.
- XP, rank, loot and SYSTEM virtual credits scale with floor difficulty.
- A floor reward is granted only after the match authority verifies a completed human-versus-human 1v1 result and confirms that the local player won. An unverified/local/AI result never grants floor XP, loot, rank or credits.
- Verified rewards are added to the player's in-world wallet and can be used in supported SYSTEM WORLD commerce such as food, drink, lodging and equipment.
- The final floor retains its sovereign crown, sovereign core, rare core and Nen fragment rewards.
- A failed or abandoned attempt does not grant the floor-clear reward and does not erase previously earned wallet balance.

## 6. Spectators and virtual ticket pools

Approved design:
- Spectators watch individual 1v1 duels and may select which of the two fighters they expect to win.
- Each fan commits a ticket stake of 1–500 virtual SYSTEM credits from the shared in-world wallet. The stake is deducted when the ticket is accepted and contributes to the match pool.
- A fan may enter one ticket per match, with a daily cap of 20. Fighters cannot enter tickets on their own match.
- Before combat starts, the match authority locks the ticket pool. No edits or late tickets are accepted.
- After a trusted result, the full pool is distributed proportionally among correct tickets. Winners receive a gross virtual payout and a separately displayed net profit. Incorrect tickets lose only their virtual stake.
- If no fan selected the actual winner, every stake is refunded. Payout rounding is resolved so the total paid equals the pool.
- All tickets, stakes and winnings are virtual SYSTEM credits only. They cannot be bought as tickets, gifted, transferred to another player, withdrawn or converted to real money. No real-money betting or cash prizes.
- NPC fans may enter as clearly labelled simulated identities with a fixed, persisted 300-credit virtual ticket budget. Their winnings remain in NPC-only balances; never present them as real users or live global participants.

Implementation status: a local prototype now records individual 1v1 matches, deducts virtual ticket stakes through the shared local SYSTEM wallet, locks one ticket per fan, settles the complete pool proportionally from the local match-authority path, refunds the pool when no ticket selected the winner, and persists the gross payout/net-profit ledger. Clearly labelled NPC spectators can also stake from a separate fixed virtual budget and receive winnings only into NPC-only balances. It rejects fighter self-prediction, duplicate tickets, invalid selections, late submissions, insufficient balances and submissions beyond the daily cap. This remains a local prototype: account-level wallet isolation, automated NPC crowd selection, a playable spectator interface, live matchmaking, server-authoritative combat results, anti-cheat/anti-collusion, global rankings and cross-device persistence are not yet implemented.

## 7. Fair access

- Free and paying players can enter, progress, earn floor rewards and reach the highest ranks through gameplay.
- Payments may offer cosmetics or convenience only; they cannot purchase wins, opponent outcomes, rank skips or exclusive combat power.
- No real-money betting or player-to-player wagering is permitted.

## 8. Technical boundaries and verification

- Current tower wallet, floor rewards, commerce and activity systems are local-save prototypes; they are not yet a server-authoritative shared online economy.
- The human-only matchmaking and match-result hooks are prepared, but the online matchmaking service is not active yet. Until it is connected, the tower must show a waiting/unavailable state and never spawn AI combat opponents. Authoritative result signatures, anti-cheat, anti-collusion and cross-device economy remain future integration work.
- Godot full validation and Android export must be checked against the exact same branch commit before marking a gameplay milestone verified.
- Physical Android touch, visual and performance inspection remains a separate required check.
- Keep PR #38 as draft. Never merge into `main` without explicit user approval.
