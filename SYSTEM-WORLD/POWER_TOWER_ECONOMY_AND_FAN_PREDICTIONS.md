# SYSTEM WORLD — Power Tower Economy and Fan Predictions

## Approved economy rules

The Power Tower is part of the shared SYSTEM world economy. Its floor-clear rewards use the same virtual SYSTEM credits wallet already used by the player's shopping, food, hotel, service and activity systems.

- A successful floor clear awards XP, floor loot and virtual SYSTEM credits.
- Credit rewards scale with floor number and include a special completion bonus for floor 200.
- Credits are earned through gameplay. Charging is optional and must never be required to enter, clear or progress through the tower.
- The wallet is virtual and local in the current prototype. It is not cash, has no cash-out value and cannot be transferred to another player's real-money account.
- A failed, abandoned, timed-out or wounded attempt earns no floor-clear credit reward.
- Paid options, if added later, may offer cosmetics or convenience only; they must not buy guaranteed combat wins or exclusive competitive power.

## Spectator predictions

The intended audience feature is prediction of match outcomes, not real-money gambling.

Eligible events may include:
- NPC fighter versus NPC fighter.
- Player fighter versus NPC fighter.
- Player fighter versus player fighter after authoritative multiplayer is available.

Fans may forecast the winner or a supported match outcome before the match locks. A correct forecast can earn non-purchasable prediction points and a published fan achievement. A wrong forecast does not deduct wallet credits or other purchased value.

Prediction rules:
1. No real-money stakes, deposits, withdrawals, cash prizes, or player-to-player money transfers.
2. Prediction points are earned through free participation and cannot be purchased, gifted, traded or converted to cash.
3. A prediction locks when the match begins; it cannot be edited after the result is known.
4. The match result must come from the trusted combat/match authority, not a client-submitted claim.
5. Reward rates and daily limits must be transparent and identical for paying and non-paying users.
6. NPC fan predictions are simulated audience activity and must be labelled as NPC activity, never presented as real users.
7. Any later virtual-credit reward for correct predictions must be capped, non-exploitable and validated server-side.

## Implementation status

### Implemented in the current source branch
- The shared SYSTEM credits wallet already funds shopping and other world services.
- Power Tower progression already awards floor XP and loot after its floor-clear confirmation.
- This update defines the floor's virtual-credit reward in system_power_tower_manager.gd and returns it only with a successful clear result.
- system_baghdad_tower_operations_manager.gd credits the shared wallet using that successful result.
- The public event board can publish local Power Tower clear records.

### Not yet implemented
- A playable spectator prediction interface and prediction lock/settlement lifecycle.
- Distinct NPC and player fighter matchmaking.
- Global fan pools, cross-device results, global fan rankings and trusted anti-cheat settlement.
- Production account-backed wallet synchronization.

The public event board is currently a local-session prototype. Do not claim that its entries represent global users or live cross-device competition. Global predictions must wait for an authoritative online service; do not simulate real users locally.