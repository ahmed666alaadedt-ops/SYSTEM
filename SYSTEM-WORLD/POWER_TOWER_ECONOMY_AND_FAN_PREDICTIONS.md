# SYSTEM WORLD — Power Tower Economy and Fan Ticket Pools

## Approved economy rules

The Power Tower uses the shared SYSTEM virtual-credit wallet already used for shopping, food, hotel stays, services and activity rewards.

- A verified floor clear awards XP, loot and virtual SYSTEM credits to the fighter.
- Credits are earned through gameplay. Free players can earn enough for ordinary food, drink, shelter, repairs, equipment and progression; charging is optional.
- Paid options, if introduced, cannot buy combat wins, rank skips, floor qualification or competitive power.
- SYSTEM credits and all fan ticket-pool payouts are fictional in-world value only: no cash deposits, withdrawals, cash-out, real-money transfer or real-world monetary prize.

## Fan ticket pools — approved rules

Fans participate in a match by selecting one of its two fighters and committing a stake of virtual SYSTEM credits as a Power Tower ticket.

1. Every event is an individual 1v1 duel. No team, squad or group combat formats.
2. A fan chooses exactly one of the two registered fighters and stakes 1–500 virtual SYSTEM credits per match.
3. The stake is deducted from the fan's SYSTEM wallet immediately and added to that match's visible pool.
4. A fan may submit only one ticket per match; a fighter cannot enter a ticket on their own match. The daily cap is 20 match tickets per fan.
5. Tickets lock before combat begins. Late changes and submissions are rejected.
6. When a trusted match result is confirmed, the complete pool is shared proportionally among fans who selected the winner. Each winning fan receives their original stake back plus their share of the losing side's stakes; the UI shows gross payout and net virtual profit separately.
7. Integer rounding remainder is assigned to the final winning ticket in the settlement order, so the recorded payouts equal the pool exactly.
8. If nobody selected the actual winner, all stakes are refunded. A cancelled or invalid match must also be voided/refunded before production launch.
9. Incorrect tickets lose only their committed virtual SYSTEM credits. Correct tickets do not create new credits beyond the existing pool.
10. No purchase, transfer, gifting, withdrawal or cash conversion of tickets or winnings. Paid currency cannot be used to gain a competitive prediction advantage; the current prototype uses the same earned/spendable SYSTEM wallet balance.
11. NPC spectators may be added only as clearly labelled simulated participants with a documented virtual ticket budget. They must never be presented as real users or as live global activity.
12. Global user participation, cross-device balances, account ownership, anti-collusion checks, match pairing and result settlement require an authenticated server-authoritative service.

## Current implementation

- The shared SYSTEM wallet exposes local prototype operations to debit a virtual ticket stake and grant a virtual pool payout.
- Power Tower match records store the 1v1 fighters, per-fan selection, stake, total pool, result, gross payouts and net profit.
- The local settlement distributes the whole pool proportionally to correct fans; if there are no correct fans, all tickets are refunded.
- Match lock, duplicate prevention, self-prediction prevention, the 20-per-day cap and local persistence remain enforced.
- Regression coverage checks stake debits, proportional payout, losing-stake accounting, no cash value, persistence and daily limits.

## Remaining limitations

- This is a local single-player prototype using the current local SYSTEM wallet. It is not a shared online wallet and does not yet authenticate individual spectator accounts.
- Live match scheduling, spectator interface, NPC fan ticket budgets, online matchmaking, server-authoritative result settlement, anti-cheat/anti-collusion, global rankings and cross-device persistence remain pending.
- Do not display invented live matches, simulated NPCs as real users, or global pools until those systems exist.
- The prototype is not production-ready for real-money gambling or cash payouts; no such features are part of the approved design.
