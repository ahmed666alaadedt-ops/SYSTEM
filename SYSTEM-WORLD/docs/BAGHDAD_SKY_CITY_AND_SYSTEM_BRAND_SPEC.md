# SYSTEM WORLD — Baghdad Sky City Design Contract

Status: approved design; implementation is incremental and must be validated in Godot before merge.

## Permanent brand identity
- Use the user's supplied complete SYSTEM crest/icon as the canonical brand asset.
- Preserve its original gold frame, crown, floating island/castle, metallic lettering and red S.
- Do not replace it with the older cyan geometric SVG mark.
- Use the same canonical asset for launcher, splash, in-game interfaces, city signage, cards, rewards, shops and SYSTEM currency.
- The exact supplied PNG currently exists at `SYSTEM-WORLD-3D/assets/1000220666-1.png`. The main Godot project currently points to `res://assets/system_world_icon.svg`; copying/importing the exact binary asset into the main project's own `assets` directory and updating all brand placements remains a required integration task. Do not use a relative path outside the project root.

## Baghdad landmark district
- Five landmark towers remain the approved tower group.
- Each tower must carry a broad rooftop district physically supported by its tower, not a floating island.
- Each rooftop district contains distinct residential, market/services, garden/leisure and civic/cultural quarters.
- All tower districts must ultimately be connected as one navigable city using accessible bridges, lifts and/or transit links. Current podium-level sky promenades and vehicle decks are only an initial connection; top-city-to-top-city accessible circulation remains incomplete.
- Baghdad placement must be validated against the actual river and Republic Bridge geometry before final positioning is approved. Do not claim exact placement until the map data confirms it.
- Preserve the user's rule that inter-world star gates are in Baghdad only; monster gates may appear in other cities.

## Public facilities
- Advertising displays are currently prototype surfaces. Real ad inventory, moderation, campaign delivery and revenue accounting are not implemented.
- Champion boards currently publish local gameplay events; global verified rankings and anti-cheat validation remain required.
- Football stadium must progress from a visual blockout to a playable venue with match flow, teams, rules and results.
- Motorsport venue must progress from a physical blockout to a playable circuit with drivable route navigation, grid/start sequence, lap timing, race UI and AI opponents.

## Quality gates before merge
1. Godot headless import and GDScript parse.
2. Scene startup with no runtime errors.
3. Validate tower count, rooftop platform/collision alignment and all four rooftop quarters per tower.
4. Validate player access and traversal; no floating or unreachable platforms.
5. Confirm Baghdad towers, Republic Bridge and Tigris River placement against the canonical geography dataset.
6. Validate stadium and motorsport interactions in runtime.
7. Android build and on-device visual/performance check.
