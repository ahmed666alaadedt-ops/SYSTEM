# SYSTEM WORLD — Android / Godot Integration Boundary

## Purpose

This document defines the safe connection boundary between the existing Android
application and the canonical Godot runtime. It is intentionally additive:
Android Compose/Firebase remains the owner of authentication, account data and
app-level services; Godot remains the owner of 3D scenes and gameplay.

## Verified project layout

- Canonical Godot project: `SYSTEM-WORLD/`.
- Godot entry scene: `SYSTEM-WORLD/MainScene.tscn`.
- Godot entry script: `SYSTEM-WORLD/scripts/main.gd`.
- Android entry point: `app/src/main/java/com/system/irtqaa/MainActivity.kt`.
- Android currently launches Jetpack Compose.
- Android Gradle currently has Firebase and Compose dependencies, but no Godot
  Android AAR dependency or Godot host Activity/Fragment.
- `SYSTEM-WORLD-3D/` is a separate prototype and is not the production runtime.

## Engine-side bridge added

`SYSTEM-WORLD/scripts/system_android_bridge.gd` is registered as the
`SYSTEMAndroidBridge` autoload.

Its stable engine-side API is:

- `receive_android_world_request(world_id)`: validates and queues a world
  request received from a future native Android host plugin.
- `has_pending_world_request()` and `consume_pending_world_request()`:
  safely handle requests arriving before the main scene finishes initializing.
- `publish_world_state(world_id, world_name)`: emits an outbound state message.
- `publish_request_result(world_id, accepted, reason)`: emits a result message.
- `message_to_android(message_type, payload)`: outbound signal for the native
  host adapter.
- `get_bridge_status()`: reports readiness and explicitly reports that the
  native transport is not connected yet.

The bridge also accepts a development startup argument:
`--system-world=modern`.

## World-entry safety

The Android host is not allowed to bypass in-world travel rules. External
startup requests may enter the modern world only. Requests for historical,
fantasy, or Greed Island are rejected by the game entry handler and must use
the approved in-world Star Gate travel flow. This preserves the project rule
that world-transition Star Gates are located in Baghdad.

No Firebase UID, account role, moderator claim, game-server claim, mission
completion, damage, reward, or other trusted gameplay result is accepted from
this bridge. Those values must continue to be verified by Firebase/server-side
systems, never by an Android client message.

## Android-side contract prepared

- `app/src/main/java/com/system/irtqaa/SystemGodotRuntimeContract.kt`
  defines the stable Intent action and world identifiers for a future host Activity.
- `app/libs/godot-runtime/` is the documented AAR/JAR drop location.
- `app/build.gradle.kts` discovers optional AAR/JAR files there and configures
  the hidden-asset ignore pattern. The directory is empty, so no guessed binary
  or unverified Maven engine version has been added.

The contract allows external Android entry into the modern world only.
Historical, fantasy and Greed Island remain behind Baghdad Star Gate travel.

## Versioned message protocol prepared

`app/src/main/java/com/system/irtqaa/SystemGodotMessageContract.kt`
defines a version-1 JSON envelope for the future native adapter:

- `open_world`: Android requests entry into the modern starting world.
- `player_context`: optional minimal account display context; it is not proof
  of identity and must never authorize rewards, missions, moderation or combat.
- `bridge_ready`, `world_state`, `world_entry_result`: Godot-to-Android
  status and navigation responses.
- The parser rejects unknown protocol versions, unknown message types,
  malformed JSON and messages larger than 16 KiB.
- Message direction allowlists are explicit. Payload fields still require
  validation by the receiving adapter.

This is a protocol definition only. The native Godot host plugin and live
message transport have not been implemented or tested yet.

## Native Android work still required

The following is **not implemented yet**:

1. Verify and pin one Godot editor/export-template version compatible with the
   project.
2. Export the canonical Godot project as an Android AAR using Godot's Gradle
   export workflow.
3. Add the generated AAR/JAR dependencies to the Android app Gradle build.
4. Add a Godot host Activity/Fragment or a dedicated Android runtime plugin.
5. Implement the native adapter that forwards host events to
   `SYSTEMAndroidBridge.receive_android_world_request()` and subscribes to
   `message_to_android`.
6. Preserve the Compose/Firebase account flow and pass only non-authoritative
   display/session context into Godot.
7. Handle Android pause/resume/back/orientation and the single-engine-instance
   lifecycle.
8. Build, install and test on a physical Android device.

Do not add a guessed Maven Godot version or a fake AAR path. The current project
does not record a verified Godot editor/export-template version, and no AAR has
been generated yet.

## Current status

- [x] Canonical Godot project and entry points identified.
- [x] Existing Godot manager preloads and main-scene attachments inspected.
- [x] Engine-side bridge API added and registered.
- [x] Main scene reports active-world changes through the bridge boundary.
- [x] External direct entry is restricted to the modern starting world.
- [x] Android-side world request Intent contract prepared.
- [x] Optional AAR/JAR import location and Gradle discovery configured.
- [ ] Native Android/Godot transport.
- [ ] Godot AAR export and Gradle embedding.
- [ ] Firebase account context adapter.
- [ ] Godot import/parse test.
- [ ] Android build and physical-device test.

## Official technical reference

Godot's Android embedding documentation explains the AAR dependency, host
Activity/Fragment lifecycle and bidirectional host-plugin communication:
https://docs.godotengine.org/en/stable/tutorials/platform/android/embedding_in_android_projects.html
