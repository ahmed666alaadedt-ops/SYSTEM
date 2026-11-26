# X-S-X Power Tower — Approved Design & Gameplay Contract

Status: partial implementation / Godot 4.3 headless validated / in-engine visual review pending
Branch: feature/power-tower-xsx-expansion-20261126
Base: main at dc3d9ba942251173ef0a9a5aa57d83b097937986

## 1. Identity and scope
- Independent landmark: X-S-X POWER TOWER. It is not one of Baghdad's five connected towers and must not be parented to the Baghdad five-tower district.
- 200 floors. Preserve the existing SYSTEMPowerTowerManager, progression, ranked 1v1, judge, spectator-prediction, and reward systems; extend them instead of creating duplicate systems.
- Architecture is an original design created for SYSTEM WORLD, using the approved concept image as the visual direction: ultra-tall tapered glass/metal silhouette, distinctive illuminated structural tiers, large X-S-X identity, premium entrance, upper observatory/helipad facilities, cinematic city/river context.
- All visible public signage and floor/arena labels use English for the global audience.
- This is a visual/gameplay direction, not a claim that the tower mesh or cinematic sequences are already implemented.

## 2. Tower experience
- Cinematic exterior approach, entrance reveal, lobby, elevator ascent, floor arrival, arena introduction, victory/defeat, and high-floor/helipad reveals.
- Detailed 3D construction: layered facade geometry, structural ribs, glass/metal PBR materials, emissive X-S-X signage, interior lighting, physically grounded collision, high-detail lobby and arena props, distant silhouette and LOD tiers.
- Dynamic quality settings must preserve the highest available visual quality on capable devices while scaling rendering cost on weaker devices.
- Tower remains a single distinct destination with its own landmark identity and navigation entry.

## 3. Existing Hunter-inspired tower systems to preserve and extend
- 200-floor progression and themed arenas.
- Official competitive matches remain individual 1v1; do not replace with AI opponents. NPCs may serve as guides, staff, referees, spectators, trainers, and practice-only characters.
- Preserve rank progression, floor challenges, timed/official match flow, win/loss records, demotion/disqualification rules, judges, and boss/title-holder milestones already present in code.
- Spectator predictions/tickets use SYSTEM virtual credits only. No real-money betting, cash value, or cash-out.
- Preserve the current server-verification/idempotency protections for official results and rewards.

## 4. Equipment and skill shop — new approved addition
A dedicated in-tower equipment and ability marketplace is required.

### Allowed stock
- Melee / traditional weapons only: swords (old and modern designs), daggers, knives, spears, polearms, axes, clubs, bows and arrows, and other non-firearm melee/ranged fantasy equipment.
- Armor and defensive gear: helmets, body armor, gloves, boots, shields, and complete armor sets.
- Potions/elixirs: health, energy, strength, recovery, Nen-related awakening/advancement, resistance, and other in-world consumables.
- Skills and techniques: skill scrolls, ability unlocks, Nen-related training/techniques, and rare skill offers.
- Crafting and upgrade materials appropriate to the tower economy.

### Explicit exclusion
- No modern firearms or modern projectile weapons are sold or displayed in this tower shop. Keep those outside this location and do not silently add them to its inventory.

### Equipment quality and rarity
- Standard quality progression: Bronze -> Silver -> Gold -> Diamond.
- Rarity is a separate axis from quality: Rare / Unique / World-Rare (globally scarce).
- Time-limited stock or temporary-use equipment is explicitly marked TEMPORARY with a visible remaining duration / expiry. It must never be confused with permanent rare or world-rare equipment.
- Item records need stable IDs, category, tier, rarity, permanence/duration, stats, level/floor requirements, price in SYSTEM virtual currency, and a grounded 3D display representation.
- No item should be labelled world-rare merely as marketing; uniqueness/limited supply must be enforced by authoritative inventory rules.

## 5. Shop presentation and interaction
- Premium 3D display pedestals and wall racks, weapon stands, armor mannequins, glass cabinets for rare items, elixir shelves, and skill-scroll displays.
- Inspectable items show name, category, quality, rarity, duration if temporary, stats, requirements, and price.
- NPC staff can explain, buy, and sell through the existing commerce/economy integration; do not create a duplicate wallet or inventory.
- Purchases must validate balance, requirements, stock, and item ownership atomically. Temporary items must expire correctly. Rare/world-rare stock must prevent duplicate issuance where configured.
- Store inventory and ownership must persist safely; client-side display is not authoritative for currency or item grants.

## 6. Implementation constraints
- First inspect and reuse existing manager, inventory, wallet, shop, Nen, skill, and item definitions. Do not duplicate an existing service.
- Do not modify Baghdad tower exterior silhouettes or interiors as part of this work.
- Do not change the Hunter Marshland PR or its branch.
- Keep all work on this feature branch. Do not merge or push changes into main without explicit approval.
- A successful headless validator or Android APK build does not establish visual completion. Record separately: code present, automated tests passed, in-engine visual review passed, and physical-device performance reviewed.


## 7. User-approved arena ladder, crowd, Nen, and betting expansion — 2026-11-26

### Arena count by floor band
The number of simultaneous arena spaces progressively decreases as the player climbs. The schedule is data-driven and must remain easy to tune:
- Floors 1–20: 8 arenas.
- Floors 21–40: 6 arenas.
- Floors 41–60: 4 arenas.
- Floors 61–80: 3 arenas.
- Floors 81–100: 2 arenas.
- Floors 101–200: 1 main arena on every floor.
Official competitive matches remain 1v1. The floor band controls arena count, not team size or opponent type.

### Spectators
- Target population: 500 visible spectator NPCs in the Power Tower audience.
- They are crowd/fan NPCs, not extra combatants. They watch official 1v1 matches, react to match events, cheer, and celebrate winners.
- Use scalable crowd representation/LOD on Android; preserve the 500-person population target without requiring 500 heavyweight full rigs simultaneously.

### SYSTEM virtual-credit betting and three-way rewards
- Spectator NPCs and player users can place predictions/stakes using SYSTEM virtual credits only. No real-money stake, cash value, cash-out, or external payment.
- The official result is the only settlement trigger; reject late bets, duplicate settlement, invalid sides, and unverified match results.
- Each completed betting round records a transparent ledger showing: Power Tower/house earnings, winning bettor payouts, and the fighter's match reward.
- Reuse the existing SYSTEM wallet/virtual-ticket and server-verification/idempotency services. Do not add a second wallet or let client UI mint or settle credits.
- The percentage split is a configurable game-economy policy and must be explicitly surfaced in the UI before a bet is confirmed.

### Combat styles and Nen learning curve
- Early floors allow unarmed hand-to-hand combat, kung fu and other martial-arts styles, traditional melee weapons, and bows/arrows.
- The player enters a gradual Nen learning/training path inside the Power Tower: discovery, aura awareness, basic control, sustained control, advanced techniques, and personal ability development.
- Opponent difficulty and Nen use increase with floor progression. Upper-floor official fights are Nen-focused; equipment remains available where the floor rules allow it, but Nen becomes the decisive combat system.
- NPC Nen trainers and referees explain and supervise training; practice NPCs may be used for training only. Official matches remain player-versus-player 1v1 as already specified.

### Interior amenities
- Add proper restaurants and cafeterias inside the independent Power Tower, plus dedicated recreation/entertainment and rest areas for fighters and visitors.
- Keep these facilities inside the Power Tower boundary; do not move them into, or count them as, Baghdad's five connected towers.

### Implementation and verification boundary
- The existing architecture/shop checkpoint is partial. These new requirements must be implemented and tested; documenting them does not certify runtime completion.
- Keep work on `feature/power-tower-xsx-expansion-20261126` / draft PR #42. Never merge to `main` without the user's explicit approval.


## 8. Implementation checkpoint — 2026-11-26

### Code present
- `system_power_tower_xsx_architecture.gd` is attached to the existing independent `PowerTower` landmark by the landmark manager. It adds tapered glass/metal sections, three illuminated structural tiers, 12 X-S-X facade identity marks, upper sky observatory, rooftop helipad, and circular arrival podium.
- The existing public lobby now receives 3D presentation groups for traditional weapons, armor, elixirs/Nen, skill scrolls, hunter accessories, and a cafeteria with four tables and sixteen visible seats. The existing operations/economy manager remains the single wallet, inventory and shop service.
- The Power Tower shop currently has 28 products: 9 traditional weapon options, 3 skill manuals, 3 cafeteria items, 4 equippable accessories, armor and elixirs. Accessories use two new equipment slots and contribute their configured combat bonuses.
- Modern firearm item IDs are excluded from the Power Tower catalog and official Power Tower combat actions are blocked while one is equipped.
- The Nen trainer flow requires level 15, Hunter rank D and an owned Nen Awakening Elixir; consuming the elixir uses the existing progression/Nen service.
- Local match appointment UI supports the next three calendar days, four daily slots (10:00, 13:00, 16:00, 19:00), requested floor, one active booking per local player, persistence on device and cancellation. This is a local prototype, not an online reservation/matchmaking service.
- Arena availability is data-driven by floor band: 1–20: 8; 21–40: 6; 41–60: 4; 61–80: 3; 81–100: 2; 101–200: 1.
- Each active arena audience targets 500 visible spectators using 8 detailed reacting rigs plus 492 lightweight MultiMesh crowd impostors; 48 reserved interactive seats remain available.

### Automated verification
- Godot 4.3 canonical import, project launch, Power Tower architecture validator, restricted shop validator, 500-crowd/arena-ladder validator, Baghdad tower validators, Hunter tunnel validator, terrain streaming validator and canonical main-scene headless launch passed on commit `6e9e0c48ea55f165e3e1008f532bac742a2d4a7e`.
- Canonical Android debug APK export completed successfully on the same commit; artifact size reported by GitHub Actions: approximately 36.3 MB.
- The branch remains `feature/power-tower-xsx-expansion-20261126` and draft PR #42 remains unmerged.

### Not yet certified / remaining
- No physical Android-device visual/performance review has been completed; headless success is not visual completion.
- The new appointment prototype is local-only. Online reservations, real opponent matchmaking and server-authoritative synchronization still need backend integration.
- Unique / World-Rare stock issuance and TEMPORARY expiry rules are specified but not yet implemented as authoritative scarcity/expiry mechanics.
- The 500-person crowd is a lightweight visual representation; only eight audience members are full reacting rigs. The 48 reserved seats are interactive.
- Final high-detail floor interiors, full cinematic ascent/arrival sequences, and on-device LOD/performance tuning remain open.
- Existing final-floor weapon gate remains unchanged; do not infer that all shop weapons are permitted in every official floor match.


## 8. Implemented gameplay details — 2026-11-26

### Physical arena layout
- The approved arena ladder is represented by 560 arena floor platforms across the 200-floor tower: 8 arenas on floors 1–20, 6 on 21–40, 4 on 41–60, 3 on 61–80, 2 on 81–100, then 1 on every floor from 101–200.
- Each arena platform has a visible boundary rail and collision surface. The layout is centered within each floor band and generated through MultiMesh for mobile rendering efficiency.

### Crowd and fan predictions
- Crowd rendering target is 500: 492 shared MultiMesh LOD crowd proxies plus 8 detailed audience actors in the spectator gallery.
- The independent tower-wide audience now instantiates eight detailed `CharacterBody3D` spectator actors with torso, head, both arms and both legs; the remaining 492 stay as lightweight MultiMesh body/head proxies. Automated tests verify all eight actor nodes and their five visible body parts.
- The 500 stable fan NPC identities can submit virtual SYSTEM predictions for registered human 1v1 matches before the betting pool locks.

### Betting distribution
- The winning bettors receive their original stakes back plus a proportional share of 80% of the losing-stake pool.
- The Power Tower records 10% of the losing-stake pool as house revenue.
- The winning fighter receives 10% of the losing-stake pool as a fighter reward.
- If nobody predicts the winner, every stake is refunded and no house/fighter share is taken.
- Betting disclosure appears before user confirmation. SYSTEM credits have no real-money value, cash-out, or external payment.
- Current client prototype records the house and fighter ledgers and can credit the local winning fighter. Remote fighter reward entries remain pending until account synchronization/claim. Production multiplayer requires authoritative server-side wallet settlement and idempotency.

### Nen training progression
- Nen training is available at the dedicated Power Tower Nen Training Hall and uses the persistent SYSTEM player progression record.
- Floor bands gate the techniques: discovery/aura awareness (1–20), Ten (21–40), Ren (41–60), Zetsu (61–80), Hatsu (81–100), advanced Nen (101–150), and mastery (151–200).
- Three completed training sessions are required per mastery stage. Training IDs are persisted and duplicate session submissions are rejected.
- The hall's Area3D interaction routes through the main world interaction handler and tower operations manager to the player's progression component.

### Interior placement
- Weapon, armor, elixir, skill, accessory, cafeteria, restaurant, recreation, entertainment and Nen training facilities are positioned within the circular entrance podium footprint.


### Equipment tier expansion
- Added dedicated footwear equipment slot with bronze, silver, gold and diamond boots. Equipped boots add movement and defense bonuses, and use the same persisted durability/upgrade path as other equipment.
- Expanded the shop catalog with additional traditional melee weapons, crossbows, shields, bronze-to-diamond armor tiers, five footwear tiers, rare Nen elixirs and advanced Nen skill manuals.
- Modern firearms and modern projectile weapons remain prohibited from the Power Tower.


### Floor-based combat rules
- Floors 1–80 allow unarmed hand-to-hand, kung fu, martial arts, traditional melee weapons, and bows/arrows; Nen techniques become available as the player learns them.
- Floors 81–200 are Nen-only: players must have unlocked Nen and reached control rank 5 before entering, must unequip weapons, and fight using Nen-enhanced unarmed combat and Nen techniques. The Hatsu foundation training needed for rank 5 is available in the training hall at floor 80, before the upper-floor entry gate.


### Interactive combat-style selection
- Added a combat-style selection board in the Power Tower lobby. It lists only styles permitted on the player's next floor.
- The selected style is checked against the player's equipped weapon and Nen progression before each official Power Tower attack.
- Kung fu uses a rapid three-strike combo; martial arts and traditional melee use heavy attacks; bows/crossbows use a longer-range shot; Nen techniques route through the existing Nen abilities.


### Bow ammunition
- Added bronze reinforced arrows, silver steel arrows and rare diamond arrows to the Power Tower shop.
- Bow/crossbow attacks consume one arrow per shot and automatically use the highest available arrow tier, with matching damage scaling.
