package com.system.irtqaa

import org.json.JSONObject

/**
 * Android-side, transport-independent router for the SYSTEM/Godot protocol.
 *
 * A future Godot host Activity/plugin supplies [sendRawToGodot] and forwards
 * received Godot JSON to [receiveFromGodot]. This class deliberately does not
 * depend on Godot APIs or grant gameplay authority to client messages.
 */
class SystemGodotMessageRouter(
    private val authenticatedPlayerId: () -> String?,
    private val sendRawToGodot: (String) -> Boolean
) {
    data class WorldState(val worldId: String, val worldName: String)
    data class WorldEntryResult(
        val worldId: String,
        val accepted: Boolean,
        val reason: String
    )

    interface Listener {
        fun onBridgeReady() {}
        fun onWorldState(state: WorldState) {}
        fun onWorldEntryResult(result: WorldEntryResult) {}
        fun onRejectedMessage(reason: String) {}
    }

    /**
     * External Android entry is intentionally restricted to the modern world.
     * Cross-world travel remains an in-world Baghdad Star Gate action.
     */
    fun requestWorld(worldId: String): Boolean {
        if (worldId != "modern") return false
        return send(
            SystemGodotMessageContract.Type.OPEN_WORLD,
            JSONObject().put("world_id", worldId)
        )
    }

    /**
     * Sends only a minimal display context. The UID comes from the current
     * Firebase-authenticated session provider, never from a caller-supplied UID.
     * Godot must still treat this context as untrusted.
     */
    fun sendPlayerContext(displayName: String?): Boolean {
        val uid = authenticatedPlayerId()?.takeIf { it.isNotBlank() } ?: return false
        val cleanName = displayName.orEmpty().trim().take(80)
        return send(
            SystemGodotMessageContract.Type.PLAYER_CONTEXT,
            JSONObject()
                .put("uid", uid.take(128))
                .put("display_name", cleanName)
                .put("trusted", false)
        )
    }

    /** Returns false for malformed, unknown, oversized or wrong-direction data. */
    fun receiveFromGodot(rawJson: String, listener: Listener): Boolean {
        val envelope = SystemGodotMessageContract.decode(rawJson)
        if (envelope == null ||
            !SystemGodotMessageContract.isAllowedFromGodot(envelope.type)
        ) {
            listener.onRejectedMessage("Invalid or disallowed Godot message.")
            return false
        }

        val payload = envelope.payload
        when (envelope.type) {
            SystemGodotMessageContract.Type.BRIDGE_READY -> {
                listener.onBridgeReady()
            }
            SystemGodotMessageContract.Type.WORLD_STATE -> {
                val worldId = payload.optString("world_id").take(40)
                val worldName = payload.optString("world_name").take(80)
                if (worldId.isBlank()) {
                    listener.onRejectedMessage("World state has no world_id.")
                    return false
                }
                listener.onWorldState(WorldState(worldId, worldName))
            }
            SystemGodotMessageContract.Type.WORLD_ENTRY_RESULT -> {
                val worldId = payload.optString("world_id").take(40)
                if (worldId.isBlank() || !payload.has("accepted")) {
                    listener.onRejectedMessage("World entry result is incomplete.")
                    return false
                }
                listener.onWorldEntryResult(
                    WorldEntryResult(
                        worldId = worldId,
                        accepted = payload.optBoolean("accepted", false),
                        reason = payload.optString("reason").take(160)
                    )
                )
            }
            else -> {
                listener.onRejectedMessage("Unexpected message direction.")
                return false
            }
        }
        return true
    }

    private fun send(
        type: SystemGodotMessageContract.Type,
        payload: JSONObject
    ): Boolean {
        if (!SystemGodotMessageContract.isAllowedFromAndroid(type)) return false
        return runCatching {
            sendRawToGodot(
                SystemGodotMessageContract.encode(type = type, payload = payload)
            )
        }.getOrDefault(false)
    }
}
