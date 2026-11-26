package com.system.irtqaa

import android.app.Activity
import android.content.Context
import android.content.Intent

/**
 * Stable Android-side message contract for the future embedded Godot runtime.
 * It has no Godot imports, so Compose/Firebase remains buildable before AAR export.
 */
object SystemGodotRuntimeContract {
    const val ACTION_OPEN_WORLD = "com.system.irtqaa.action.OPEN_GODOT_WORLD"
    const val EXTRA_WORLD_ID = "com.system.irtqaa.extra.GODOT_WORLD_ID"
    const val EXTRA_REQUEST_SOURCE = "com.system.irtqaa.extra.REQUEST_SOURCE"
    const val EXTRA_ACCOUNT_UID = "com.system.irtqaa.extra.ACCOUNT_UID"
    const val SOURCE_SYSTEM_APP = "system_android_app"

    enum class WorldId(val wireValue: String) {
        SELECTION("selection"),
        NPC_SHOWCASE("npc_showcase"),
        MODERN("modern"),
        HISTORICAL("historical"),
        FANTASY("fantasy"),
        GREED_ISLAND("greed_island");

        companion object {
            fun fromWireValue(value: String?): WorldId? =
                entries.firstOrNull { it.wireValue == value?.trim()?.lowercase() }
        }
    }

    data class WorldRequest(
        val worldId: WorldId,
        val source: String = SOURCE_SYSTEM_APP,
        val accountUid: String? = null
    ) {
        fun isAllowedAsExternalEntry(): Boolean = worldId == WorldId.MODERN || worldId == WorldId.SELECTION || worldId == WorldId.NPC_SHOWCASE
    }

    fun createWorldIntent(
        context: Context,
        hostActivity: Class<out Activity>,
        request: WorldRequest
    ): Intent {
        require(request.isAllowedAsExternalEntry()) {
            "Only the modern world, four-world selection, or NPC showcase may be launched externally."
        }
        return Intent(context, hostActivity).apply {
            action = ACTION_OPEN_WORLD
            putExtra(EXTRA_WORLD_ID, request.worldId.wireValue)
            putExtra(EXTRA_REQUEST_SOURCE, request.source)
            request.accountUid?.takeIf { it.isNotBlank() }
                ?.let { putExtra(EXTRA_ACCOUNT_UID, it) }
        }
    }

    fun readWorldRequest(intent: Intent?): WorldRequest? {
        if (intent?.action != ACTION_OPEN_WORLD) return null
        val worldId = WorldId.fromWireValue(intent.getStringExtra(EXTRA_WORLD_ID)) ?: return null
        val source = intent.getStringExtra(EXTRA_REQUEST_SOURCE)
            ?.takeIf { it.isNotBlank() } ?: SOURCE_SYSTEM_APP
        val accountUid = intent.getStringExtra(EXTRA_ACCOUNT_UID)
            ?.takeIf { it.isNotBlank() }
        return WorldRequest(worldId, source, accountUid)
    }
}
