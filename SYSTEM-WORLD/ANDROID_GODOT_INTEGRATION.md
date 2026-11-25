# SYSTEM WORLD — Android / Godot Integration

## Current implementation

The native SYSTEM Android app embeds the canonical Godot 4.3 runtime as a second screen while keeping Jetpack Compose and Firebase as the account/startup layer.

- Android dependency: `org.godotengine:godot:4.3.0.stable` from Maven Central, plus AndroidX Fragment 1.7.1.
- `SystemGodotActivity` hosts `SystemGodotFragment` in landscape orientation.
- The fragment starts the canonical `SYSTEM-WORLD` project from `app/src/main/assets/main.pck` using the documented `--main-pack` command-line argument.
- `system-android-app.yml` imports the canonical Godot project and exports the PCK before the Android Gradle build. It also runs when `SYSTEM-WORLD/**` changes, so the embedded game pack follows the same source branch.
- The Godot export preset includes JSON data files required by runtime geography and map systems.
- The SYSTEM app navigation opens the embedded 3D world through the approved modern-world entry contract only. Historical, fantasy and Greed Island remain accessible through Baghdad Star Gate travel inside the game.

## Native marketplace transport

`SystemGodotFragment` registers `SystemAndroidHostPlugin` as a runtime Godot host plugin.

The plugin exposes the exact singleton name and API expected by `SYSTEM-WORLD/scripts/system_android_bridge.gd`:

- Singleton: `SYSTEMAndroidHost`
- Signal: `message_from_android(raw_json: String)`
- Godot-callable method: `send_to_android(raw_json: String)`

The plugin routes version-1 envelopes through `SystemGodotMessageRouter` and `SystemMarketplaceGodotBridgeHandler`. Marketplace requests use the existing authenticated `FirebaseArtifactMarketplaceRepository`; the UID is obtained from the current Firebase Authentication session, never from a Godot payload. Replies preserve request IDs and return to GDScript through the registered signal. When GDScript sends the `bridge_ready` handshake, the plugin returns the current Firebase-authenticated UID and display name as explicitly untrusted display context.

The bridge does not grant gameplay authority. Player display context remains untrusted, and the Android client cannot issue artifacts, grant currency, alter ownership, or bypass callable Cloud Function checks.

## Build and verification

- Godot project: `SYSTEM-WORLD/project.godot`.
- Android host: `app/src/main/java/com/system/irtqaa/SystemGodotActivity.kt`.
- Runtime fragment and plugin: `SystemGodotFragment.kt`, `SystemAndroidHostPlugin.kt`.
- Runtime pack: generated during CI at `app/src/main/assets/main.pck`; it is not committed as a large generated binary.
- The app-shell workflow builds the Compose app and embedded Godot runtime together.
- Godot bridge validators still verify request IDs, allowlisted operations, malformed messages and unavailable-host behavior in headless mode. A physical-device round trip is still required to prove the native plugin, Firebase Authentication, callable functions and Godot scene work together on Android.

## Remaining activation and QA gates

1. Deploy Firebase Cloud Functions and Firestore indexes before claiming the online player market is live.
2. Connect trusted quest/dungeon reward issuance and verified virtual-currency awards to the server-authoritative marketplace.
3. Run the Android app-shell workflow and canonical Godot validation on the exact same branch HEAD.
4. Install the resulting APK on a physical Android device and test login, app-to-world launch, pause/resume/back, touch controls, marketplace browse/list/purchase/auction/exchange, network loss/retry, memory and sustained performance.
5. Confirm the single-engine-instance lifecycle on device; only one Godot engine instance is supported per Android process.

## Versioned message contract

`app/src/main/java/com/system/irtqaa/SystemGodotMessageContract.kt` defines version-1 JSON envelopes and the direction allowlist. `SystemGodotRuntimeContract.kt` restricts external entry to the modern world and leaves all other world transitions inside the Baghdad Star Gate system.
