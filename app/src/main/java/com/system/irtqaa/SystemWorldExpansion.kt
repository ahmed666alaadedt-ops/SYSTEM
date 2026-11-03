
package com.system.irtqaa

import java.util.UUID

// ========================================
// SYSTEM WORLD - EXPANSION
// بوابات العوالم والتنقل بينها
// ========================================

data class WorldGate(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val destinationEra: WorldEra,
    val requiredRank: WorldRank = WorldRank.F,
    val requiredLevel: Int = 1,
    val requiredKeyId: String? = null,
    val isDiscovered: Boolean = false,
    val isUnlocked: Boolean = false
)

enum class WorldGateActionStatus {
    SUCCESS,
    LEVEL_TOO_LOW,
    RANK_TOO_LOW,
    GATE_NOT_DISCOVERED,
    KEY_REQUIRED,
    GATE_LOCKED
}

data class WorldGateResult(
    val gate: WorldGate,
    val status: WorldGateActionStatus,
    val message: String
)

data class WorldGateTravelResult(
    val player: WorldPlayer,
    val success: Boolean,
    val message: String
)

// ========================================
// إدارة البوابات
// ========================================

object SystemWorldExpansion {

    fun discoverGate(
        gate: WorldGate,
        player: WorldPlayer
    ): WorldGateResult {

        if (player.level < gate.requiredLevel) {
            return WorldGateResult(
                gate,
                WorldGateActionStatus.LEVEL_TOO_LOW,
                "مستواك غير كافٍ لاكتشاف هذه البوابة"
            )
        }

        val discoveredGate = gate.copy(
            isDiscovered = true
        )

        return WorldGateResult(
            discoveredGate,
            WorldGateActionStatus.SUCCESS,
            "تم اكتشاف البوابة: ${gate.name}"
        )
    }

    fun unlockGate(
        gate: WorldGate,
        player: WorldPlayer,
        ownedKeyIds: Set<String> = emptySet()
    ): WorldGateResult {

        if (!gate.isDiscovered) {
            return WorldGateResult(
                gate,
                WorldGateActionStatus.GATE_NOT_DISCOVERED,
                "يجب اكتشاف البوابة أولاً"
            )
        }

        if (player.level < gate.requiredLevel) {
            return WorldGateResult(
                gate,
                WorldGateActionStatus.LEVEL_TOO_LOW,
                "مستواك أقل من المستوى المطلوب"
            )
        }

        if (player.rank.ordinal < gate.requiredRank.ordinal) {
            return WorldGateResult(
                gate,
                WorldGateActionStatus.RANK_TOO_LOW,
                "رتبتك لا تسمح بفتح هذه البوابة"
            )
        }

        val requiredKey = gate.requiredKeyId

        if (requiredKey != null &&
            requiredKey !in ownedKeyIds
        ) {
            return WorldGateResult(
                gate,
                WorldGateActionStatus.KEY_REQUIRED,
                "تحتاج إلى مفتاح خاص لفتح البوابة"
            )
        }

        val unlockedGate = gate.copy(
            isUnlocked = true
        )

        return WorldGateResult(
            unlockedGate,
            WorldGateActionStatus.SUCCESS,
            "تم فتح البوابة بنجاح"
        )
    }

    // ====================================
    // الانتقال بين العصور
    // ====================================

    fun enterGate(
        gate: WorldGate,
        player: WorldPlayer
    ): WorldGateTravelResult {

        if (!gate.isUnlocked) {
            return WorldGateTravelResult(
                player,
                false,
                "هذه البوابة مغلقة"
            )
        }

        if (player.level < gate.requiredLevel) {
            return WorldGateTravelResult(
                player,
                false,
                "مستواك غير كافٍ لدخول هذا العالم"
            )
        }

        val updatedPlayer = player.copy(
            currentEra = gate.destinationEra
        )

        return WorldGateTravelResult(
            updatedPlayer,
            true,
            "تم الانتقال إلى ${gate.destinationEra}"
        )
    }
}
