
package com.system.irtqaa

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

enum class SystemAudioEventType {
    BUTTON,
    PORTAL_OPEN,
    WORLD_SELECTED,
    TRANSITION,
    QUEST_STARTED,
    QUEST_COMPLETED,
    QUEST_FAILED,
    REWARD,
    WARNING,
    LEVEL_UP,
    COMBAT_STARTED,
    COMBAT_VICTORY,
    COMBAT_DEFEAT,
    DISCOVERY,
    HEALING,
    GREED_ISLAND_OPEN
}

data class SystemAudioEvent(
    val id: Long = 0L,
    val type: SystemAudioEventType = SystemAudioEventType.BUTTON
)

object SystemAudioEvents {

    var latestEvent by mutableStateOf(SystemAudioEvent())
        private set

    private var eventCounter = 0L

    fun emit(type: SystemAudioEventType) {
        eventCounter += 1L

        latestEvent = SystemAudioEvent(
            id = eventCounter,
            type = type
        )
    }

    fun button() = emit(SystemAudioEventType.BUTTON)

    fun portal() = emit(SystemAudioEventType.PORTAL_OPEN)

    fun questStarted() = emit(SystemAudioEventType.QUEST_STARTED)

    fun questCompleted() = emit(SystemAudioEventType.QUEST_COMPLETED)

    fun questFailed() = emit(SystemAudioEventType.QUEST_FAILED)

    fun reward() = emit(SystemAudioEventType.REWARD)

    fun warning() = emit(SystemAudioEventType.WARNING)

    fun levelUp() = emit(SystemAudioEventType.LEVEL_UP)

    fun combatStarted() = emit(SystemAudioEventType.COMBAT_STARTED)

    fun combatVictory() = emit(SystemAudioEventType.COMBAT_VICTORY)

    fun combatDefeat() = emit(SystemAudioEventType.COMBAT_DEFEAT)

    fun discovery() = emit(SystemAudioEventType.DISCOVERY)

    fun healing() = emit(SystemAudioEventType.HEALING)

    fun greedIslandOpened() = emit(SystemAudioEventType.GREED_ISLAND_OPEN)
}
