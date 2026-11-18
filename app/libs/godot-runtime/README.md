# Godot runtime AAR drop location

Reserved for the Android AAR/JAR outputs exported from the canonical Godot
project at `SYSTEM-WORLD/`.

The app Gradle configuration discovers `*.aar` and `*.jar` files here.
Do not upload placeholder or guessed binaries. Export the actual project from
Godot Editor using Android Gradle Build with Export Format set to AAR.

The app intentionally remains buildable while this directory is empty.
After the real export exists, add the generated archives and complete the
Godot host Activity/Fragment, GodotHost and host-plugin lifecycle integration.

Android message contract:
`app/src/main/java/com/system/irtqaa/SystemGodotRuntimeContract.kt`.
