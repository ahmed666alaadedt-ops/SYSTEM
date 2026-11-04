package com.system.irtqaa

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.sin

@Composable
fun SystemStartupGate(
    content: @Composable () -> Unit
) {
    var showIntro by remember {
        mutableStateOf(true)
    }

    val music = remember {
        SystemEntranceMusic()
    }

    DisposableEffect(showIntro) {
        if (showIntro) {
            music.play()
        }

        onDispose {
            if (showIntro) {
                music.stop()
            }
        }
    }

    LaunchedEffect(Unit) {
        delay(4200)
        showIntro = false
    }

    if (showIntro) {
        SystemIntroScreen()
    } else {
        content()
    }
}

@Composable
private fun SystemIntroScreen() {

    val transition = rememberInfiniteTransition(
        label = "system_intro"
    )

    val pulse by transition.animateFloat(
        initialValue = 0.65f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 1800,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "system_pulse"
    )

    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF030711),
                        Color(0xFF101C32),
                        Color(0xFF050914)
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {

        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .alpha(pulse)
        ) {
            val centerX = size.width / 2f
            val centerY = size.height / 2f
            val baseRadius = size.minDimension * 0.27f

            drawCircle(
                color = cyan.copy(alpha = 0.22f),
                radius = baseRadius * 1.45f,
                center = androidx.compose.ui.geometry.Offset(
                    centerX,
                    centerY
                ),
                style = Stroke(width = 2.dp.toPx())
            )

            drawCircle(
                color = gold.copy(alpha = 0.30f),
                radius = baseRadius * 1.18f,
                center = androidx.compose.ui.geometry.Offset(
                    centerX,
                    centerY
                ),
                style = Stroke(width = 1.5.dp.toPx())
            )

            drawCircle(
                color = cyan.copy(alpha = 0.18f),
                radius = baseRadius * 0.88f,
                center = androidx.compose.ui.geometry.Offset(
                    centerX,
                    centerY
                ),
                style = Stroke(width = 1.dp.toPx())
            )
        }

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {

            Text(
                text = "SYSTEM",
                color = gold,
                fontSize = 43.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 5.sp,
                modifier = Modifier.alpha(pulse)
            )

            Spacer(
                modifier = Modifier.height(14.dp)
            )

            Text(
                text = "نحو الارتقاء",
                color = Color.White,
                fontSize = 20.sp,
                fontWeight = FontWeight.Medium
            )

            Spacer(
                modifier = Modifier.height(12.dp)
            )

            Text(
                text = "YOUR ASCENSION BEGINS",
                color = cyan,
                fontSize = 11.sp,
                letterSpacing = 3.sp
            )

            Spacer(
                modifier = Modifier.height(42.dp)
            )

            LinearProgressIndicator(
                progress = { pulse },
                modifier = Modifier
                    .width(150.dp)
                    .height(2.dp),
                color = gold,
                trackColor = cyan.copy(alpha = 0.15f)
            )

            Spacer(
                modifier = Modifier.height(12.dp)
            )

            Text(
                text = "INITIALIZING SYSTEM",
                color = Color.LightGray.copy(alpha = 0.75f),
                fontSize = 10.sp,
                letterSpacing = 2.sp
            )
        }
    }
}

private class SystemEntranceMusic {

    @Volatile
    private var running = false

    private var audioThread: Thread? = null

    fun play() {
        if (running) return

        running = true

        audioThread = Thread {
            var track: AudioTrack? = null

            try {
                val sampleRate = 22050
                val durationSeconds = 4.2
                val totalFrames =
                    (sampleRate * durationSeconds).toInt()

                val bufferSize = 2048

                val format = AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(
                        AudioFormat.ENCODING_PCM_16BIT
                    )
                    .setChannelMask(
                        AudioFormat.CHANNEL_OUT_MONO
                    )
                    .build()

                val attributes = AudioAttributes.Builder()
                    .setUsage(
                        AudioAttributes.USAGE_ASSISTANCE_SONIFICATION
                    )
                    .setContentType(
                        AudioAttributes.CONTENT_TYPE_MUSIC
                    )
                    .build()

                track = AudioTrack.Builder()
                    .setAudioAttributes(attributes)
                    .setAudioFormat(format)
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(
                        AudioTrack.MODE_STREAM
                    )
                    .build()

                track.play()

                val buffer = ShortArray(1024)
                var frame = 0

                val melody = doubleArrayOf(
                    130.81,
                    164.81,
                    196.00,
                    261.63,
                    196.00,
                    164.81
                )

                while (
                    running &&
                    frame < totalFrames
                ) {
                    var index = 0

                    while (
                        index < buffer.size &&
                        frame < totalFrames &&
                        running
                    ) {
                        val time =
                            frame.toDouble() / sampleRate

                        val noteIndex =
                            ((time / 0.7).toInt())
                                .coerceIn(
                                    0,
                                    melody.lastIndex
                                )

                        val frequency =
                            melody[noteIndex]

                        val noteTime =
                            time % 0.7

                        val noteFade = minOf(
                            1.0,
                            noteTime / 0.12,
                            (0.7 - noteTime) / 0.15
                        ).coerceAtLeast(0.0)

                        val introFade =
                            minOf(1.0, time / 0.8)

                        val finalFade =
                            minOf(
                                1.0,
                                (durationSeconds - time) / 0.7
                            ).coerceAtLeast(0.0)

                        val envelope =
                            noteFade *
                            introFade *
                            finalFade

                        val mainTone = sin(
                            2.0 * PI * frequency * time
                        )

                        val harmony = sin(
                            2.0 * PI *
                                (frequency * 1.5) *
                                time
                        )

                        val deepTone = sin(
                            2.0 * PI * 65.41 * time
                        )

                        val sample =
                            (
                                mainTone * 0.20 +
                                harmony * 0.07 +
                                deepTone * 0.08
                            ) * envelope

                        buffer[index] = (
                            sample * Short.MAX_VALUE
                        ).toInt().toShort()

                        index++
                        frame++
                    }

                    if (index > 0) {
                        track.write(
                            buffer,
                            0,
                            index
                        )
                    }
                }

            } catch (_: Exception) {
                // Keep the app running if audio is unavailable.
            } finally {
                try {
                    track?.stop()
                } catch (_: Exception) {
                }

                try {
                    track?.release()
                } catch (_: Exception) {
                }

                running = false
            }
        }.apply {
            name = "SYSTEM-Entrance-Music"
            start()
        }
    }

    fun stop() {
        running = false
    }
}
