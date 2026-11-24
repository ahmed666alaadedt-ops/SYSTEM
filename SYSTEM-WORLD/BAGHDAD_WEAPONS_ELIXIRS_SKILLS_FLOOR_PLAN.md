# Baghdad Towers — weapons, elixirs and skill floors

Status: implementation requirements / next runtime work; NOT yet runtime-complete.
Canonical branch: `feature/baghdad-five-plus-power-tower-20261122`
PR: #38 (draft; do not merge without explicit user approval).

This checkpoint supplements the existing six-tower implementation. It does not replace completed interiors, NPC staffing, elevators, hotel/restaurant workflows, tower operations, Power Tower arenas, or existing progression/crafting systems.

## Non-negotiable layout

- Keep exactly five connected civic towers and the independent 200-floor Power Tower.
- Keep weapons, armor and elixir commerce inside the Shopping & Commerce Tower. Do not recreate the obsolete standalone Weapons/Equipment/Elixirs Tower.
- Keep all combat competitions in the Power Tower individual-only: authenticated human 1v1, no teams, no AI combat fallback.
- Training floors in the Hunter Association Tower are practice/learning spaces, not team-combat arenas.
- All purchases, crafting, equipment changes, elixir consumption and skill unlocks must use the existing persistent player progression/inventory/economy APIs. No free item grants from display-only interactions.

## Shopping & Commerce Tower — 32-floor zoning

The following is the required explicit floor directory. Existing hotel floors 27–28 and restaurant floors 29–32 remain in place.

| Floors | Department | Required player-facing activity |
|---|---|---|
| 1–4 | General market and supplies | Food, water, travel supplies, clothing and basic services |
| 5–7 | Melee weapon galleries | Training/steel swords, spears, axes; inspect, compare, buy and equip |
| 8–10 | Ranged and modern equipment | Bows/arrows and rank-gated modern equipment; world-appropriate restrictions |
| 11–13 | Armor and protection | Shields, armor, helmets, outfits; compare defense, durability and rank |
| 14 | Forge and master workshop | Existing WeaponsForge station; craft, upgrade and repair equipment using ingredients and materials |
| 15–16 | Advanced crafting and materials | Weapon components, rare materials, recipes and crafting support; no duplicate free stock |
| 17–19 | Healing and basic elixirs | Healing, strength, speed, endurance and energy elixirs; purchase, craft, consume and view active duration |
| 20–22 | Nen awakening and control | Nen acquisition/awakening, control elixirs, supervised practice and rank progression |
| 23–25 | Advanced elixir laboratory | Higher-tier formulas, ingredient checks, required level and Nen-control rank |
| 26 | Rare and legendary elixir vault | Restricted access, limited stock, high requirements and explicit confirmation before purchase |
| 27–28 | Existing SYSTEM hotel | Preserve reception, guest rooms, bookings and room service |
| 29–32 | Existing restaurants and dining | Preserve seating, ordering, kitchen, serving and payment lifecycle |

The existing floor-14 forge/laboratory prototype and current catalog remain the baseline. The runtime must be extended to distribute the services across their assigned floors; do not claim the zoning table is implemented until the floor builder, interaction routing and regression tests all prove it.

## Hunter Association Tower — skill and mastery floors

Add dedicated, physically explorable training spaces while preserving the current floors 4–6 training halls and all existing association offices:

- Floors 4–6: foundational conditioning, movement, defense and safe combat drills.
- Floors 7–9: weapon mastery — sword, spear, axe, bow and shield practice; each drill tracks its own mastery and never grants a weapon for free.
- Floors 10–12: energy/Nen fundamentals, control, focus, defensive use and safe activation practice; retain the existing guild lounge on floor 12 as a separate area within its floor.
- Floors 13–15: advanced ability control, timing, stamina management and counter-practice.
- Floors 16–18: skill specialization rooms and supervised trials.
- Floors 19–20: assessment halls; unlocks require demonstrated prerequisites and recorded completion, not simply entering the floor.

Skills must be original SYSTEM abilities, not copied named techniques, characters, dialogue or scenes from existing franchises.

## Skill progression requirements

- Separate learned skills, skill mastery and Nen-control rank. They are related but not interchangeable.
- Each skill has a stable ID, category, level/rank requirement, prerequisite IDs, resource cost, cooldown, effect description and mastery record.
- A skill can be learned only once; repeated practice increases mastery within a capped progression.
- Unlocks are earned through training objectives and verified progression, not direct arbitrary purchase.
- Weapon mastery is tracked per weapon family and does not bypass hunter-rank or equipment requirements.
- Skills must persist across saves and be represented in the player's progression UI.
- Combat integration must validate costs/cooldowns and reject unavailable skills; UI buttons alone are not proof of implementation.
- Nen abilities remain unavailable until Nen awakening; higher-control actions require the appropriate Nen rank.
- Skill effects must be balanced and must not turn elixirs into permanent stat upgrades.

## Elixir rules

- Preserve the existing timed effects and consumption path in `system_player_progression.gd`.
- Healing elixirs cannot heal a player who does not need healing and cannot replace the world's hospital/healer recovery for serious persistent injuries.
- Strength, speed, endurance and energy effects remain temporary and show remaining duration.
- Nen awakening is a one-time unlock; Nen control advances only to the defined cap.
- Rare/legendary elixirs require their recipe ingredients, level, Nen rank and restricted stock.
- Prevent duplicate consumption, negative inventory, repeated reward grants and purchase/crafting race conditions.
- Show recipe ingredients, missing quantities, rank/level requirements, stock and final price before confirmation.

## Required runtime and QA acceptance

1. Every assigned floor opens through the existing real elevator/floor travel path and has a distinct Arabic/English department sign.
2. Required stations have visible 3D equipment/lab/training props, collision where appropriate, a player interaction Area3D, and correct tower/floor/facility metadata.
3. Interactions route to the actual existing purchase, crafting, equipment, elixir or skill API; no generic kiosk may falsely claim to complete an action.
4. Buying, crafting, equipping, upgrading, repairing, using elixirs and learning/practising skills update the persistent inventory/progression state exactly once.
5. Rank, level, prerequisites, ingredient shortages, stock limits, cooldowns, injury state and insufficient currency are rejected with clear Arabic feedback.
6. Regression tests cover every assigned floor range, floor 14 legacy forge compatibility, elixir timeouts, Nen unlock/control caps, weapon mastery, skill prerequisites, save/load and duplicate-action protection.
7. Run the complete Baghdad tower operations regression, all six-tower regressions, Hunter stage regressions, full Godot 4.3 validation and canonical Android export on the exact same final branch HEAD.
8. Physical Android testing remains required for touch interaction, readability, camera framing, loading and performance.

## Current verified baseline and honest status

- The existing runtime already has a Shopping Tower product catalog containing weapons, armor, basic/advanced elixirs and crafting materials.
- The existing runtime already creates the floor-14 WeaponsForge and ElixirLaboratory workstations.
- The existing progression script already supports equipment slots, durability, upgrades, crafting recipes, timed elixir effects, Nen awakening and Nen control.
- The existing Hunter Association Tower already has foundational training facilities on floors 4–6.
- The expanded 5–7 weapon/skill floor zoning, 8–26 distributed weapon/elixir facilities, persistent original skill tree, complete interaction routing and dedicated regression coverage are NOT yet verified as implemented.
- Do not mark the towers complete until the runtime and exact-HEAD QA criteria above pass.
- Keep PR #38 draft and unmerged unless the user explicitly approves merging.
