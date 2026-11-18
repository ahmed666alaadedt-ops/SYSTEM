# SYSTEM WORLD — XSX Verified Mission Contributions

Status: Backend and Android source added. No Firebase deployment or trusted game-server integration has been performed.

## Session lifecycle

1. A real-player party is registered against a published XSX mission.
2. Only the recorded party leader can call `startHunterGuildMission`.
3. The server revalidates the frozen roster against existing `players/{uid}` profiles and creates one session for the assignment.
4. The trusted game server reports gameplay events through `recordHunterGuildGameplayEvent`.
5. Only the trusted game server can call `finishHunterGuildMissionSession`; this closes the session and releases the mission's concurrent-team slot.

## Trusted event boundary

The event callable requires a Firebase Authentication custom claim `gameServer: true`. Normal player accounts and the Android client cannot submit authoritative damage, healing, objectives, revives, discoveries, survival events, or score values.

The server validates:
- session exists and is active;
- player UID belongs to the frozen registration-time roster;
- event ID is unique within the session;
- event type is on the server-defined allowlist;
- units are integer and within the per-event-type maximum;
- no more than 120 events per player per rolling one-minute window.

The server calculates points using fixed weights. Clients cannot choose the score, edit contribution totals, or mark an event verified. Events are written once to the session's `events` subcollection and aggregated into that player's `contributions` document in the same Firestore transaction.

## Event weights currently configured

| Event | Points per unit | Maximum units per event |
|---|---:|---:|
| Damage | 0.1 | 10,000 |
| Healing | 0.12 | 10,000 |
| Objective | 100 | 1 |
| Revive | 60 | 1 |
| Discovery | 25 | 1 |
| Survival | 1 | 1 |

These are initial balancing values, not final economy or reward values. They should be play-tested and tuned only after verified game telemetry exists.

## Android display

The player-party screen now:
- lets the recorded leader start a registered mission;
- lists mission sessions visible to the signed-in roster members;
- shows each real player's verified contribution points and event counts;
- labels empty sessions as waiting for the first trusted server event.

The Android app does not expose a callable for submitting gameplay events.

## Rewards and anti-cheat

This milestone records verified contribution only. It does not grant XP, currency, loot, rank progress, or cash rewards. Mission completion only changes session/assignment status and releases the concurrent mission slot. Reward settlement must be a separate server-side process after the game server provides validated completion evidence and anti-cheat checks.

## Required infrastructure before live scoring

- Deploy the Cloud Functions.
- Provision a dedicated trusted game-server identity and issue `gameServer: true` only to that service identity.
- Integrate the canonical Godot runtime with an authenticated server-side event bridge. Never embed a privileged game-server credential in the Android APK or Godot client.
- Verify that the game server, not the client, calculates actual damage/healing/objective outcomes.
- Test duplicate event IDs, non-roster player IDs, inactive sessions, invalid event types, unit caps, event-rate limits, and unauthorized player calls.
- Run TypeScript build, Android build, and end-to-end tests before release.

## Current limitation

No dedicated multiplayer/game server or authenticated Godot-to-server bridge is currently verified in the repository. Until that infrastructure exists, sessions can be opened and displayed, but no gameplay contribution events can legitimately enter the verified ledger.
