# SYSTEM WORLD — Tower Leaders and Reward Presentation

Status: approved design decision, 2026-11-24
Branch: `feature/baghdad-five-plus-power-tower-20261122`

## Canonical roles

- **Mayar (ميار): President of the Hunter Association Tower.** Mayar is the authority who formally presents hunter-association awards and honors when a player earns them through the tower's verified examinations, ranks, and qualifying achievements.
- **Adam (آدم): President of the Power Tower.** Adam is the authority who formally presents Power Tower awards, especially elite/sovereign honors and rewards earned by completing the final high-level duels and boss-title challenges.

## Boundaries

- Mayar and Adam are not player companions, quest followers, combat helpers, tutorial pop-ups, or in-world assistants.
- Their informational/storytelling presence belongs to the SYSTEM interface: they can explain world lore, inspirations, histories, systems, and answer player questions there.
- Their in-world presence is exceptional and restricted to their respective leadership/reward ceremonies. Players do not casually access or summon them.
- Mayar is not assigned to the Power Tower. Adam is not assigned to the Hunter Association Tower.
- Reward eligibility and amounts remain controlled by the existing verified progression/reward systems. The tower president presents the earned reward; the president does not bypass verification or grant unearned rewards.
- This decision does not change the four-world structure, tower layouts, individual-only competition rule, or existing player progression.

## Implementation note

This file records the approved canonical design. Runtime ceremony/character presentation must be wired to the existing verified reward events without duplicating or bypassing reward grants. The current Power Tower result path already verifies the human 1v1 result and settles floor rewards; the presentation layer should listen to that successful settlement. Hunter Association presentation should likewise listen to its verified rank/examination reward event.
