package com.system.irtqaa

import org.json.JSONException
import org.json.JSONObject

/**
 * Versioned, non-authoritative message envelope shared by the Android host
 * and the embedded Godot runtime. This file deliberately has no Godot imports.
 */
object SystemGodotMessageContract {
    const val PROTOCOL_VERSION = 1
    const val MAX_MESSAGE_LENGTH = 16 * 1024

    enum class Type(val wireValue: String) {
        OPEN_WORLD("open_world"),
        PLAYER_CONTEXT("player_context"),
        BRIDGE_READY("bridge_ready"),
        WORLD_STATE("world_state"),
        WORLD_ENTRY_RESULT("world_entry_result"),
        MARKETPLACE_REQUEST("marketplace_request"),
        MARKETPLACE_RESULT("marketplace_result");

        companion object {
            fun fromWireValue(value: String?): Type? =
                entries.firstOrNull { it.wireValue == value }
        }
    }

    data class Envelope(
        val version: Int,
        val type: Type,
        val requestId: String?,
        val payload: JSONObject
    )

    /** Messages Android is permitted to send to Godot. */
    val androidToGodotTypes: Set<Type> = setOf(
        Type.OPEN_WORLD,
        Type.PLAYER_CONTEXT,
        Type.MARKETPLACE_RESULT
    )

    /** Messages Godot is permitted to send to Android. */
    val godotToAndroidTypes: Set<Type> = setOf(
        Type.BRIDGE_READY,
        Type.WORLD_STATE,
        Type.WORLD_ENTRY_RESULT,
        Type.MARKETPLACE_REQUEST
    )

    fun encode(
        type: Type,
        payload: JSONObject = JSONObject(),
        requestId: String? = null
    ): String {
        require(type in androidToGodotTypes || type in godotToAndroidTypes) {
            "Unsupported SYSTEM Godot message type."
        }
        require(requestId == null || requestId.length <= 128) {
            "Request ID is too long."
        }

        val message = JSONObject()
            .put("version", PROTOCOL_VERSION)
            .put("type", type.wireValue)
            .put("payload", payload)

        if (!requestId.isNullOrBlank()) {
            message.put("request_id", requestId)
        }

        val encoded = message.toString()
        require(encoded.length <= MAX_MESSAGE_LENGTH) {
            "SYSTEM Godot message exceeds the size limit."
        }
        return encoded
    }

    /**
     * Parses only the stable envelope. Callers must still validate each
     * payload field and must never treat client messages as trusted gameplay.
     */
    fun decode(rawMessage: String): Envelope? {
        if (rawMessage.isBlank() || rawMessage.length > MAX_MESSAGE_LENGTH) {
            return null
        }

        return try {
            val json = JSONObject(rawMessage)
            val version = json.optInt("version", -1)
            if (version != PROTOCOL_VERSION) return null

            val type = Type.fromWireValue(json.optString("type"))
                ?: return null
            val payload = json.optJSONObject("payload")
                ?: return null
            val requestId = json.optString("request_id")
                .takeIf { it.isNotBlank() && it != "null" }

            if (requestId != null && requestId.length > 128) return null

            Envelope(version, type, requestId, payload)
        } catch (_: JSONException) {
            null
        }
    }

    fun isAllowedFromAndroid(type: Type): Boolean =
        type in androidToGodotTypes

    fun isAllowedFromGodot(type: Type): Boolean =
        type in godotToAndroidTypes
}
