
package com.system.irtqaa

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext

@Composable
fun SystemWorldAudioHost(
    selectedWorld: String,
    selectedTab: Int
) {
    val context = LocalContext.current

    val audioEngine = remember(context) {
        SystemWorldAudioEngine(context)
    }

    var firstWorldEvent by remember {
        mutableStateOf(true)
    }

    var firstTabEvent by remember {
        mutableStateOf(true)
    }

    LaunchedEffect(selectedWorld) {
        SystemWorldThemeRuntime.currentWorld =
            when (selectedWorld) {
                "real" -> SystemWorldKind.MODERN_REALISTIC
                "mythology" -> SystemWorldKind.MYTHOLOGY_HISTORY
                "fantasy" -> SystemWorldKind.FANTASY
                "greed" -> SystemWorldKind.GREED_ISLAND
                else -> null
            }

        if (firstWorldEvent) {
            firstWorldEvent = false
        } else {
            if (selectedWorld.isBlank()) {
                audioEngine.playTransition()
            } else {
                audioEngine.playWorldSelection()
            }
        }
    }

    LaunchedEffect(selectedTab) {
        if (firstTabEvent) {
            firstTabEvent = false
        } else {
            audioEngine.playButtonClick()

            if (selectedTab == 3) {
                audioEngine.playPortalOpen()
            }
        }
    }

    LaunchedEffect(SystemAudioEvents.latestEvent.id) {
        when (SystemAudioEvents.latestEvent.type) {
            SystemAudioEventType.BUTTON ->
                audioEngine.playButtonClick()

            SystemAudioEventType.PORTAL_OPEN ->
                audioEngine.playPortalOpen()

            SystemAudioEventType.WORLD_SELECTED ->
                audioEngine.playWorldSelection()

            SystemAudioEventType.TRANSITION ->
                audioEngine.playTransition()

            SystemAudioEventType.QUEST_STARTED ->
                audioEngine.playQuestStarted()

            SystemAudioEventType.QUEST_COMPLETED ->
                audioEngine.playQuestCompleted()

            SystemAudioEventType.QUEST_FAILED ->
                audioEngine.playQuestFailed()

            SystemAudioEventType.REWARD ->
                audioEngine.playReward()

            SystemAudioEventType.WARNING ->
                audioEngine.playWarning()

            SystemAudioEventType.LEVEL_UP ->
                audioEngine.playLevelUp()

            SystemAudioEventType.COMBAT_STARTED ->
                audioEngine.playCombatStarted()

            SystemAudioEventType.COMBAT_VICTORY ->
                audioEngine.playCombatVictory()

            SystemAudioEventType.COMBAT_DEFEAT ->
                audioEngine.playCombatDefeat()

            SystemAudioEventType.DISCOVERY ->
                audioEngine.playDiscovery()

            SystemAudioEventType.HEALING ->
                audioEngine.playHealing()

            SystemAudioEventType.GREED_ISLAND_OPEN ->
                audioEngine.playGreedIslandOpen()
        }
    }

    DisposableEffect(audioEngine) {
        onDispose {
            audioEngine.close()
        }
    }
}
