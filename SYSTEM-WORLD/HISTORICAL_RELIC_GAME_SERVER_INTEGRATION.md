# Historical Relic Quest — Trusted Game Server Integration

This contract is part of PR #48. It deliberately separates player intent from authoritative gameplay proof.

## Trust boundary

- The Godot client may request a quest start or a relic return. Those requests are queued by authenticated player callables.
- The Godot client must never call the server-only objective, return-proof, or reward callables.
- Only a Firebase identity carrying the custom claim `gameServer: true` may poll queued work, open sessions, record objective events, record return proofs, or issue the final reward.
- A client-side objective marker, animation, local save, RPC payload, or claimed player coordinate is not proof.
- The trusted game server must derive objective completion and historical-site presence from its own authoritative world simulation and player state.

## Callable sequence

1. Player calls `requestHistoricalRelicQuestStart({ questId, artifactId })`.
   - Backend verifies that the player owns the artifact and it is not escrowed/listed/auctioned/exchanged.
   - Backend creates one pending request per player/quest.
2. Trusted game server calls `listPendingHistoricalRelicQuestRequests()`.
   - Server reads pending `starts` and `returns` only.
3. Server validates that the player is in the allowed world/session and calls
   `startHistoricalRelicQuestSession({ playerId, questId, artifactId, requestId })`.
   - The callable accepts only the matching pending player request and consumes it atomically.
4. For each objective, the game server's authoritative simulation checks the actual objective condition and calls
   `recordHistoricalRelicQuestObjective({ sessionId, eventId, objectiveId })`.
   - The backend checks server identity, session ownership, objective allowlist, and event uniqueness.
5. For return-required relics, the player may call
   `requestHistoricalRelicReturn({ questId, artifactId })`.
   - Backend only queues the request if the server session already proves every required objective and the artifact is still owned and unreserved.
   - The game server must independently confirm the player is physically at the exact historical site in its own authoritative world state, then call
   `recordHistoricalRelicReturn({ sessionId, eventId, siteId })`.
6. After all required objective events and (when required) the exact-site return proof exist, the trusted server calls
   `completeHistoricalRelicQuest({ playerId, questId, artifactId, sessionId, eventId })`.
   - Artifact custody, skill unlock, reward ledger and session completion are committed atomically and replay-safely.
7. The client refreshes owned artifacts, market listings and server-issued skill receipts. Only those receipts unlock relic skills in the skill tree and combat HUD.

## Required server implementation before production

The current repository contains the secure Firebase request queues and server-only verification endpoints, but it does **not** yet contain a deployed authoritative multiplayer game-server process or a verified Godot-to-server session transport. The worker that consumes the queue and the authoritative world-state adapter must be implemented against the actual multiplayer runtime before calling this integration complete.

The game-server adapter must provide:
- authenticated player-to-session binding;
- server-owned world and map instance identity;
- authoritative player transforms and historical-site bounds;
- objective-specific validation (not a client-supplied boolean);
- server-side combat/interaction outcome validation for guardian objectives;
- unique event IDs and replay protection;
- service identity with the `gameServer: true` claim, stored only in server infrastructure.

## Verification status

- Firebase emulator tests exercise player request creation, rejection of client polling, server-only session creation, objective event recording, exact-site return validation, atomic reward issuance and replay protection.
- Godot CI tests the local quest presentation and the three combat skill effects; these are not a substitute for authoritative server gameplay.
- No production deployment, custom claim provisioning, or physical Android round-trip is performed by CI.
