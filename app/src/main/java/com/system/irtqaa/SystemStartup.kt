package com.system.irtqaa

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.cos
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
        if (showIntro) music.play()

        onDispose {
            if (showIntro) music.stop()
        }
    }

    LaunchedEffect(Unit) {
        delay(5200)
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
        label = "SYSTEM cinematic intro"
    )

    val pulse by transition.animateFloat(
        initialValue = 0.55f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                1700,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse"
    )

    val rotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                12000,
                easing = LinearEasing
            )
        ),
        label = "rotation"
    )

    val reverseRotation by transition.animateFloat(
        initialValue = 360f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                18000,
                easing = LinearEasing
            )
        ),
        label = "reverse rotation"
    )

    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)
    val deepBlue = Color(0xFF071329)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFF02050D),
                        deepBlue,
                        Color(0xFF030711)
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
            val cx = size.width / 2f
            val cy = size.height / 2f
            val base = size.minDimension * 0.29f

            // Central glow
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        cyan.copy(alpha = 0.12f),
                        gold.copy(alpha = 0.045f),
                        Color.Transparent
                    ),
                    center = androidx.compose.ui.geometry.Offset(cx, cy),
                    radius = base * 2.2f
                ),
                radius = base * 2.2f,
                center = androidx.compose.ui.geometry.Offset(cx, cy)
            )

            // Outer rotating ring
            rotate(rotation) {
                drawCircle(
                    color = cyan.copy(alpha = 0.38f),
                    radius = base * 1.48f,
                    center = androidx.compose.ui.geometry.Offset(cx, cy),
                    style = Stroke(width = 2.dp.toPx())
                )

                drawArc(
                    color = gold,
                    startAngle = 15f,
                    sweepAngle = 75f,
                    useCenter = false,
                    topLeft = androidx.compose.ui.geometry.Offset(
                        cx - base * 1.48f,
                        cy - base * 1.48f
                    ),
                    size = androidx.compose.ui.geometry.Size(
                        base * 2.96f,
                        base * 2.96f
                    ),
                    style = Stroke(
                        width = 5.dp.toPx(),
                        cap = StrokeCap.Round
                    )
                )

                for (i in 0 until 36) {
                    val angle = i * 10.0 * PI / 180.0
                    val r1 = base * 1.35f
                    val r2 = if (i % 3 == 0) {
                        base * 1.44f
                    } else {
                        base * 1.39f
                    }

                    drawLine(
                        color = cyan.copy(
                            alpha = if (i % 3 == 0) 0.8f else 0.28f
                        ),
                        start = androidx.compose.ui.geometry.Offset(
                            cx + cos(angle).toFloat() * r1,
                            cy + sin(angle).toFloat() * r1
                        ),
                        end = androidx.compose.ui.geometry.Offset(
                            cx + cos(angle).toFloat() * r2,
                            cy + sin(angle).toFloat() * r2
                        ),
                        strokeWidth = 2.dp.toPx()
                    )
                }
            }

            // Inner ring
            rotate(reverseRotation) {
                drawCircle(
                    color = gold.copy(alpha = 0.32f),
                    radius = base * 1.08f,
                    center = androidx.compose.ui.geometry.Offset(cx, cy),
                    style = Stroke(width = 1.5.dp.toPx())
                )

                drawArc(
                    color = cyan.copy(alpha = 0.85f),
                    startAngle = 190f,
                    sweepAngle = 105f,
                    useCenter = false,
                    topLeft = androidx.compose.ui.geometry.Offset(
                        cx - base * 1.08f,
                        cy - base * 1.08f
                    ),
                    size = androidx.compose.ui.geometry.Size(
                        base * 2.16f,
                        base * 2.16f
                    ),
                    style = Stroke(
                        width = 3.dp.toPx(),
                        cap = StrokeCap.Round
                    )
                )
            }

            // Core ring
            drawCircle(
                color = cyan.copy(alpha = 0.25f),
                radius = base * 0.78f,
                center = androidx.compose.ui.geometry.Offset(cx, cy),
                style = Stroke(width = 1.dp.toPx())
            )

            drawCircle(
                color = gold.copy(alpha = 0.45f),
                radius = base * 0.66f,
                center = androidx.compose.ui.geometry.Offset(cx, cy),
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
                fontSize = 45.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 7.sp,
                modifier = Modifier.alpha(pulse)
            )

            Spacer(Modifier.height(13.dp))

            Text(
                text = "نحو الارتقاء",
                color = Color.White,
                fontSize = 21.sp,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(Modifier.height(9.dp))

            Text(
                text = "YOUR ASCENSION BEGINS",
                color = cyan,
                fontSize = 10.sp,
                letterSpacing = 3.sp
            )

            Spacer(Modifier.height(52.dp))

            LinearProgressIndicator(
                progress = { pulse },
                modifier = Modifier
                    .width(165.dp)
                    .height(3.dp),
                color = gold,
                trackColor = cyan.copy(alpha = 0.13f)
            )

            Spacer(Modifier.height(15.dp))

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
                val sampleRate = 44100
                val duration = 5.2
                val totalFrames = (sampleRate * duration).toInt()

                val format = AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                    .build()

                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()

                val bufferSize = AudioTrack.getMinBufferSize(
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_STEREO,
                    AudioFormat.ENCODING_PCM_16BIT
                ).coerceAtLeast(4096)

                track = AudioTrack.Builder()
                    .setAudioAttributes(attributes)
                    .setAudioFormat(format)
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()

                track.play()

                val buffer = ShortArray(2048)
                var frame = 0

                val notes = doubleArrayOf(
                    130.81, 164.81, 196.00,
                    261.63, 329.63, 392.00,
                    329.63, 261.63, 196.00
                )

                while (running && frame < totalFrames) {
                    var index = 0

                    while (
                        index + 1 < buffer.size &&
                        frame < totalFrames &&
                        running
                    ) {
                        val time = frame.toDouble() / sampleRate

                        val noteIndex = (
                            time / 0.57
                        ).toInt().coerceIn(0, notes.lastIndex)

                        val frequency = notes[noteIndex]
                        val localTime = time % 0.57

                        val attack = (localTime / 0.09).coerceIn(0.0, 1.0)
                        val release = (
                            (0.57 - localTime) / 0.18
                        ).coerceIn(0.0, 1.0)

                        val fadeIn = (time / 0.8).coerceIn(0.0, 1.0)
                        val fadeOut = (
                            (duration - time) / 0.8
                        ).coerceIn(0.0, 1.0)

                        val envelope = attack * release * fadeIn * fadeOut

                        val melody = sin(
                            2.0 * PI * frequency * time
                        )

                        val harmonic = sin(
                            2.0 * PI * frequency * 2.0 * time
                        )

                        val shimmer = sin(
                            2.0 * PI * frequency * 3.0 * time
                        )

                        val bass = sin(
                            2.0 * PI * 65.41 * time
                        )

                        val pad = sin(
                            2.0 * PI * 98.00 * time
                        )

                        val atmosphere = sin(
                            2.0 * PI * 523.25 * time
                        )

                        val sweep = sin(
                            2.0 * PI * (180.0 + time * 35.0) * time
                        )

                        val sample = (
                            melody * 0.19 +
                            harmonic * 0.065 +
                            shimmer * 0.025 +
                            bass * 0.11 +
                            pad * 0.045 +
                            atmosphere * 0.018 +
                            sweep * 0.025
                        ) * envelope

                        val output = (
                            sample * Short.MAX_VALUE
                        ).toInt().coerceIn(
                            Short.MIN_VALUE.toInt(),
                            Short.MAX_VALUE.toInt()
                        ).toShort()

                        buffer[index] = output
                        buffer[index + 1] = output

                        index += 2
                        frame++
                    }

                    if (index > 0) {
                        track.write(buffer, 0, index)
                    }
                }

            } catch (_: Exception) {
                // Audio failure must never stop SYSTEM.
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
            name = "SYSTEM-Cinematic-Entrance"
            start()
        }
    }

    fun stop() {
        running = false
    }
}
