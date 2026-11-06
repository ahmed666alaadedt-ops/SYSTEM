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

    DisposableEffect(audioEngine) {
        onDispose {
            audioEngine.close()
        }
    }

    LaunchedEffect(selectedWorld) {
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
}
