# SYSTEM WORLD — Authenticated Player Party Foundation

Status: Implemented in source; deployment and runtime verification pending.

## Identity and trust boundary

- The Android application remains the authority for Firebase Authentication.
- A party action requires a signed-in Firebase user and an existing `players/{uid}` profile.
- The local guest profile is not an online identity and cannot create, invite, accept, or join parties.
- Party and invitation documents are written only by Firebase Admin code in callable Cloud Functions. Client Firestore writes remain denied by the existing security rules.
- NPC identifiers are never accepted as party members; membership is derived from authenticated Firebase UIDs.

## Party rules

- Maximum party size: six real player accounts, including the leader.
- The creator becomes leader.
- Only the leader can invite another registered player by their Firebase player ID.
- Invitations must be accepted by the invited account.
- Players can decline invitations or leave a party.
- If the leader leaves, the first remaining member becomes leader.
- When the final member leaves, the party is deleted.
- Server transactions check membership, party capacity, invite ownership and invitation status.

## Callable functions

- `createPlayerParty`
- `invitePlayerToParty`
- `respondToPlayerPartyInvite`
- `leavePlayerParty`
- `listMyPlayerParties`
- `listMyPlayerPartyInvites`

## Android integration

- `FirebasePlayerPartyRepository.kt` calls the authenticated Cloud Functions.
- `SystemPlayerPartyScreen.kt` exposes party creation, player-ID invitations, incoming invitation acceptance/decline, refresh and leave actions.
- `MainActivity.kt` adds the “فرق اللاعبين” section.
- Guest mode displays a clear sign-in requirement and cannot use the online party features.

## Not yet implemented

- Cloud Functions deployment to the Firebase project.
- End-to-end test with two distinct registered player accounts.
- Real-time party presence, member online status, voice/text party chat and shared 3D movement.
- Binding the Android party identity into the Godot runtime.
- Passing a verified party roster into XSX mission dispatch and validating mission contribution/rewards server-side.

Do not treat the party UI alone as proof of live multiplayer. The callable backend and Android client source are present, but they must be built, deployed and tested before live service is claimed.
