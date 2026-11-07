
package com.system.irtqaa

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView

@Composable
fun SystemCinematicPlayer(
    videoUri: Uri,
    onFinished: () -> Unit,
    onSkip: () -> Unit
) {
    val context = LocalContext.current

    var muted by remember {
        mutableStateOf(false)
    }

    val player = remember(videoUri) {
        ExoPlayer.Builder(context)
            .build()
            .apply {
                setMediaItem(MediaItem.fromUri(videoUri))
                repeatMode = Player.REPEAT_MODE_OFF
                prepare()
                playWhenReady = true
            }
    }

    DisposableEffect(player, onFinished) {
        val listener = object : Player.Listener {
            override fun onPlaybackStateChanged(
                playbackState: Int
            ) {
                if (playbackState == Player.STATE_ENDED) {
                    onFinished()
                }
            }
        }

        player.addListener(listener)

        onDispose {
            player.removeListener(listener)
            player.release()
        }
    }

    LaunchedEffect(muted, player) {
        player.volume = if (muted) 0f else 1f
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { viewContext ->
                PlayerView(viewContext).apply {
                    useController = false
                    resizeMode =
                        AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                    this.player = player
                }
            },
            update = { view ->
                view.player = player
            }
        )

        Column(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(18.dp),
            horizontalAlignment = Alignment.End,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "تخطي المقدمة  »",
                color = Color.White,
                fontSize = 14.sp,
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.70f),
                        RoundedCornerShape(12.dp)
                    )
                    .clickable {
                        onSkip()
                    }
                    .padding(
                        horizontal = 16.dp,
                        vertical = 11.dp
                    )
            )

            Text(
                text = if (muted) {
                    "تشغيل الصوت 🔊"
                } else {
                    "كتم الصوت 🔇"
                },
                color = Color.White,
                fontSize = 13.sp,
                modifier = Modifier
                    .background(
                        Color.Black.copy(alpha = 0.70f),
                        RoundedCornerShape(12.dp)
                    )
                    .clickable {
                        muted = !muted
                    }
                    .padding(
                        horizontal = 16.dp,
                        vertical = 10.dp
                    )
            )
        }
    }
}
