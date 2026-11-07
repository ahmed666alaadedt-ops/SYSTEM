package com.system.irtqaa

import android.net.Uri
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext

@Composable
fun SystemStartupGate(
    content: @Composable () -> Unit
) {
    val context = LocalContext.current
    var showIntro by remember { mutableStateOf(true) }

    if (showIntro) {
        val videoUri = remember(context) {
            Uri.parse(
                "android.resource://${context.packageName}/${R.raw.system_intro}"
            )
        }

        SystemCinematicPlayer(
            videoUri = videoUri,
            onFinished = { showIntro = false },
            onSkip = { showIntro = false }
        )
    } else {
        content()
    }
}
