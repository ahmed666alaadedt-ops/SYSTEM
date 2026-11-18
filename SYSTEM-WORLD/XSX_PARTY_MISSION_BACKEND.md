# SYSTEM WORLD — XSX Party Mission Registration Backend

Status: Source implementation added; Firebase deployment and runtime verification pending.

## Architecture boundary

- `SYSTEM-WORLD/` is the canonical Godot runtime.
- Android/Firebase remains the current account and trusted-data boundary.
- `SYSTEM-WORLD-3D/` remains a separate prototype and is not treated as the live mission runtime.
- This milestone registers real player parties against published XSX mission records. It does not claim that Godot gameplay dispatch or multiplayer mission execution is connected.

## Mission publication

Trusted staff with the Firebase custom claim `moderator: true` can call `publishHunterGuildMission`.

The callable validates:
- title, description, world and category;
- player count bounds from 1 to 6;
- maximum team count from 1 to 100;
- optional future closing timestamp.

It creates a server-owned `hunterGuildMissions/{missionId}` document with status `open`. Regular players cannot publish or edit mission documents.

## Player-facing callables

- `listAvailableHunterGuildMissions` — returns open, unexpired missions with remaining team capacity.
- `registerPartyForHunterGuildMission` — only the party leader can register the existing party.
- `listMyHunterGuildMissionAssignments` — returns assignments whose roster snapshot contains the signed-in player.

## Registration validation

The server verifies:
1. Firebase Authentication is present.
2. The mission exists, is open, has not expired, and has remaining team capacity.
3. The party exists and the caller is its current leader.
4. The roster is non-empty, unique, and within the six-player limit.
5. The roster count satisfies the mission's min/max participant limits.
6. Every roster ID has an existing `players/{uid}` profile.

The transaction creates a deterministic one-party/one-mission assignment and increments the mission's active team count atomically. A second registration of the same party for the same mission is rejected.

## Immutable roster snapshot

Each assignment stores:
- party and mission IDs/names;
- leader UID;
- roster snapshot of real player UIDs and display names;
- registration timestamp and status.

The snapshot is the mission's registration-time roster. Later party membership changes do not rewrite that snapshot.

## NPC exclusion

NPCs are not party members, squad members, mission participants, or substitutes. The server reads only the real player party's Firebase UIDs and matching player profile documents. No NPC fallback exists.

## Trust and reward boundary

- Firestore client rules remain deny-by-default for mission and assignment collections.
- Mission creation and registration writes occur through Firebase Admin callable functions.
- The client cannot submit or edit roster snapshots, team counts, contribution scores, completion state, XP, currency, or rewards.
- Contribution tracking, gameplay-event validation, mission dispatch into Godot, mission completion, and individual reward settlement are deliberately not implemented in this milestone. They require trusted gameplay evidence and anti-cheat validation; client-reported damage or reward values must never be accepted as authoritative.

## Deployment and verification still required

- Run `npm install` and `npm run build` inside `functions/`.
- Deploy Cloud Functions to the configured Firebase project.
- Publish an open test mission through a trusted moderator account.
- Test registration using two or more real player accounts, including rejection of a non-leader, duplicate registration, full mission capacity, invalid roster size, and expired/closed missions.
- Connect the resulting assignment ID to the canonical Godot mission runtime only after Android/Godot identity bridging is implemented.
