
package com.system.irtqaa

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
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
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

private const val INTRO_DURATION = 9500L

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

    DisposableEffect(music) {
        music.play()

        onDispose {
            music.stop()
        }
    }

    if (showIntro) {
        SystemIntroScreen(
            onFinished = {
                showIntro = false
            }
        )
    } else {
        content()
    }
}

@Composable
private fun SystemIntroScreen(
    onFinished: () -> Unit
) {
    var elapsed by remember {
        mutableLongStateOf(0L)
    }

    LaunchedEffect(Unit) {
        val start = System.currentTimeMillis()

        while (elapsed < INTRO_DURATION) {
            elapsed = System.currentTimeMillis() - start
            delay(35)
        }

        onFinished()
    }

    val progress = (elapsed.toFloat() / INTRO_DURATION)
        .coerceIn(0f, 1f)

    val transition = rememberInfiniteTransition(
        label = "SYSTEM Cinematic Opening"
    )

    val pulse by transition.animateFloat(
        initialValue = 0.55f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                900,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "Energy Pulse"
    )

    val rotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                10000,
                easing = LinearEasing
            )
        ),
        label = "Energy Rotation"
    )

    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)
    val white = Color.White

    val isCombat = elapsed in 1500L..7200L
    val isFinal = elapsed >= 7200L

    val headline = when {
        elapsed < 1500L -> "SYSTEM WORLD"
        elapsed < 3600L -> "THE BATTLE BEGINS"
        elapsed < 5400L -> "POWER AWAKENS"
        elapsed < 7200L -> "ENTER THE UNKNOWN"
        else -> "SYSTEM WORLD"
    }

    val subtitle = when {
        elapsed < 1500L -> "نحو الارتقاء"
        elapsed < 3600L -> "معارك • تحديات • مغامرات"
        elapsed < 5400L -> "القوة تبدأ من الداخل"
        elapsed < 7200L -> "عوالم لا حدود لها"
        else -> "YOUR ASCENSION BEGINS"
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFF02040B),
                        Color(0xFF071329),
                        Color(0xFF02050D)
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
            val base = size.minDimension * 0.27f

            // Cinematic background particles
            for (i in 0 until 48) {
                val angle = i * 0.73
                val distance = (
                    0.15f + (i % 7) * 0.095f
                ) * size.minDimension

                val x = cx + cos(angle).toFloat() * distance
                val y = cy + sin(angle).toFloat() * distance

                drawCircle(
                    color = if (i % 2 == 0) {
                        cyan.copy(alpha = 0.45f)
                    } else {
                        gold.copy(alpha = 0.35f)
                    },
                    radius = if (i % 4 == 0) 3.dp.toPx() else 1.5.dp.toPx(),
                    center = androidx.compose.ui.geometry.Offset(x, y)
                )
            }

            // Energy rings
            rotate(rotation) {
                drawCircle(
                    color = cyan.copy(alpha = 0.30f),
                    radius = base * 1.5f,
                    center = androidx.compose.ui.geometry.Offset(cx, cy),
                    style = Stroke(width = 2.dp.toPx())
                )

                drawArc(
                    color = gold,
                    startAngle = 20f,
                    sweepAngle = 95f,
                    useCenter = false,
                    topLeft = androidx.compose.ui.geometry.Offset(
                        cx - base * 1.5f,
                        cy - base * 1.5f
                    ),
                    size = androidx.compose.ui.geometry.Size(
                        base * 3f,
                        base * 3f
                    ),
                    style = Stroke(
                        width = 5.dp.toPx()
                    )
                )
            }

            rotate(-rotation * 0.65f) {
                drawCircle(
                    color = gold.copy(alpha = 0.24f),
                    radius = base * 1.08f,
                    center = androidx.compose.ui.geometry.Offset(cx, cy),
                    style = Stroke(width = 2.dp.toPx())
                )
            }

            if (isCombat) {
                val battleTime = elapsed.toFloat() / 1000f

                // Fighter on the left
                drawFighter(
                    x = size.width * 0.30f,
                    y = size.height * 0.60f,
                    facing = 1f,
                    movement = battleTime,
                    color = cyan,
                    scale = 1f
                )

                // Fighter on the right
                drawFighter(
                    x = size.width * 0.70f,
                    y = size.height * 0.60f,
                    facing = -1f,
                    movement = battleTime + 1.3f,
                    color = gold,
                    scale = 1f
                )

                // Sword clash
                val clashX = cx
                val clashY = size.height * 0.49f

                drawLine(
                    color = white.copy(alpha = 0.95f),
                    start = androidx.compose.ui.geometry.Offset(
                        clashX - base * 0.48f,
                        clashY - base * 0.45f
                    ),
                    end = androidx.compose.ui.geometry.Offset(
                        clashX + base * 0.48f,
                        clashY + base * 0.45f
                    ),
                    strokeWidth = 5.dp.toPx()
                )

                drawLine(
                    color = cyan,
                    start = androidx.compose.ui.geometry.Offset(
                        clashX - base * 0.42f,
                        clashY + base * 0.38f
                    ),
                    end = androidx.compose.ui.geometry.Offset(
                        clashX + base * 0.42f,
                        clashY - base * 0.38f
                    ),
                    strokeWidth = 4.dp.toPx()
                )

                // Impact flash
                val flash = abs(
                    sin(battleTime * 4.2f)
                )

                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            white.copy(alpha = 0.65f * flash),
                            gold.copy(alpha = 0.22f * flash),
                            Color.Transparent
                        ),
                        center = androidx.compose.ui.geometry.Offset(
                            clashX,
                            clashY
                        ),
                        radius = base * 0.85f
                    ),
                    radius = base * 0.85f,
                    center = androidx.compose.ui.geometry.Offset(
                        clashX,
                        clashY
                    )
                )

                // Monster boss silhouette
                if (elapsed >= 3900L) {
                    drawMonsterBoss(
                        x = cx,
                        y = size.height * 0.30f,
                        scale = 0.78f,
                        color = Color(0xFF9B5CFF),
                        movement = battleTime
                    )
                }

                // Energy attack
                if (elapsed >= 5400L) {
                    drawLine(
                        color = cyan.copy(alpha = 0.8f),
                        start = androidx.compose.ui.geometry.Offset(
                            size.width * 0.18f,
                            size.height * 0.35f
                        ),
                        end = androidx.compose.ui.geometry.Offset(
                            size.width * 0.82f,
                            size.height * 0.35f
                        ),
                        strokeWidth = 7.dp.toPx()
                    )
                }
            }

            if (isFinal) {
                // Final logo energy burst
                for (i in 0 until 20) {
                    val angle = i * 2.0 * PI / 20.0
                    val inner = base * 0.75f
                    val outer = base * (1.0f + pulse * 0.35f)

                    drawLine(
                        color = if (i % 2 == 0) gold else cyan,
                        start = androidx.compose.ui.geometry.Offset(
                            cx + cos(angle).toFloat() * inner,
                            cy + sin(angle).toFloat() * inner
                        ),
                        end = androidx.compose.ui.geometry.Offset(
                            cx + cos(angle).toFloat() * outer,
                            cy + sin(angle).toFloat() * outer
                        ),
                        strokeWidth = 2.dp.toPx()
                    )
                }
            }
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.Center)
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {

            Spacer(Modifier.weight(1f))

            Text(
                text = headline,
                color = gold,
                fontSize = if (isCombat) 27.sp else 36.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 3.sp,
                modifier = Modifier.alpha(pulse)
            )

            Spacer(Modifier.height(12.dp))

            Text(
                text = subtitle,
                color = white,
                fontSize = 17.sp,
                fontWeight = FontWeight.SemiBold
            )

            if (isCombat) {
                Spacer(Modifier.height(14.dp))

                Text(
                    text = "⚔  BATTLE • ENERGY • POWER  ⚔",
                    color = cyan,
                    fontSize = 11.sp,
                    letterSpacing = 2.sp
                )
            }

            if (isFinal) {
                Spacer(Modifier.height(18.dp))

                Text(
                    text = "ميار",
                    color = gold,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    text = "رفيقتك في SYSTEM WORLD",
                    color = white.copy(alpha = 0.85f),
                    fontSize = 14.sp
                )
            }

            Spacer(Modifier.weight(1f))

            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth(0.55f)
                    .height(3.dp),
                color = gold,
                trackColor = cyan.copy(alpha = 0.15f)
            )

            Spacer(Modifier.height(16.dp))

            Text(
                text = "INITIALIZING SYSTEM",
                color = Color.LightGray.copy(alpha = 0.75f),
                fontSize = 10.sp,
                letterSpacing = 2.sp
            )

            Spacer(Modifier.height(35.dp))
        }
    }
}

private fun DrawScope.drawFighter(
    x: Float,
    y: Float,
    facing: Float,
    movement: Float,
    color: Color,
    scale: Float
) {
    val unit = size.minDimension * 0.075f * scale
    val swing = sin(movement * 5f) * unit * 0.65f

    val center = androidx.compose.ui.geometry.Offset(x, y)

    // Head
    drawCircle(
        color = color,
        radius = unit * 0.24f,
        center = androidx.compose.ui.geometry.Offset(
            x,
            y - unit * 1.5f
        )
    )

    // Body
    drawLine(
        color = color,
        start = androidx.compose.ui.geometry.Offset(
            x,
            y - unit * 1.25f
        ),
        end = center,
        strokeWidth = unit * 0.20f
    )

    // Arms
    drawLine(
        color = color,
        start = androidx.compose.ui.geometry.Offset(
            x,
            y - unit * 0.95f
        ),
        end = androidx.compose.ui.geometry.Offset(
            x + facing * unit * 0.75f,
            y - unit * 0.55f + swing
        ),
        strokeWidth = unit * 0.17f
    )

    drawLine(
        color = color,
        start = androidx.compose.ui.geometry.Offset(
            x,
            y - unit * 0.95f
        ),
        end = androidx.compose.ui.geometry.Offset(
            x - facing * unit * 0.55f,
            y - unit * 0.35f
        ),
        strokeWidth = unit * 0.17f
    )

    // Legs
    drawLine(
        color = color,
        start = center,
        end = androidx.compose.ui.geometry.Offset(
            x - facing * unit * 0.38f,
            y + unit * 0.85f
        ),
        strokeWidth = unit * 0.19f
    )

    drawLine(
        color = color,
        start = center,
        end = androidx.compose.ui.geometry.Offset(
            x + facing * unit * 0.45f,
            y + unit * 0.85f
        ),
        strokeWidth = unit * 0.19f
    )

    // Weapon
    drawLine(
        color = Color.White,
        start = androidx.compose.ui.geometry.Offset(
            x + facing * unit * 0.70f,
            y - unit * 0.55f + swing
        ),
        end = androidx.compose.ui.geometry.Offset(
            x + facing * unit * 1.55f,
            y - unit * 1.35f + swing
        ),
        strokeWidth = unit * 0.09f
    )
}

private fun DrawScope.drawMonsterBoss(
    x: Float,
    y: Float,
    scale: Float,
    color: Color,
    movement: Float
) {
    val unit = size.minDimension * 0.075f * scale
    val pulse = abs(sin(movement * 2f))

    // Monster head
    drawCircle(
        color = color.copy(alpha = 0.8f),
        radius = unit * (0.65f + pulse * 0.08f),
        center = androidx.compose.ui.geometry.Offset(
            x,
            y
        )
    )

    // Eyes
    drawCircle(
        color = Color.Red,
        radius = unit * 0.10f,
        center = androidx.compose.ui.geometry.Offset(
            x - unit * 0.25f,
            y - unit * 0.05f
        )
    )

    drawCircle(
        color = Color.Red,
        radius = unit * 0.10f,
        center = androidx.compose.ui.geometry.Offset(
            x + unit * 0.25f,
            y - unit * 0.05f
        )
    )

    // Body
    drawLine(
        color = color,
        start = androidx.compose.ui.geometry.Offset(
            x,
            y + unit * 0.55f
        ),
        end = androidx.compose.ui.geometry.Offset(
            x,
            y + unit * 1.75f
        ),
        strokeWidth = unit * 0.65f
    )

    // Monster arms
    drawLine(
        color = color,
        start = androidx.compose.ui.geometry.Offset(
            x,
            y + unit * 0.85f
        ),
        end = androidx.compose.ui.geometry.Offset(
            x - unit * 1.05f,
            y + unit * 1.45f
        ),
        strokeWidth = unit * 0.30f
    )

    drawLine(
        color = color,
        start = androidx.compose.ui.geometry.Offset(
            x,
            y + unit * 0.85f
        ),
        end = androidx.compose.ui.geometry.Offset(
            x + unit * 1.05f,
            y + unit * 1.45f
        ),
        strokeWidth = unit * 0.30f
    )
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
                val duration = INTRO_DURATION / 1000.0
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

                val impacts = doubleArrayOf(
                    2.2, 3.8, 5.5, 6.8
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
                            time / 0.72
                        ).toInt().coerceIn(0, notes.lastIndex)

                        val frequency = notes[noteIndex]

                        val localTime = time % 0.72

                        val attack = (
                            localTime / 0.10
                        ).coerceIn(0.0, 1.0)

                        val release = (
                            (0.72 - localTime) / 0.22
                        ).coerceIn(0.0, 1.0)

                        val fadeIn = (
                            time / 0.8
                        ).coerceIn(0.0, 1.0)

                        val fadeOut = (
                            (duration - time) / 0.8
                        ).coerceIn(0.0, 1.0)

                        val envelope =
                            attack * release * fadeIn * fadeOut

                        val melody = sin(
                            2.0 * PI * frequency * time
                        )

                        val harmonic = sin(
                            2.0 * PI * frequency * 2.0 * time
                        )

                        val bass = sin(
                            2.0 * PI * 65.41 * time
                        )

                        val atmosphere = sin(
                            2.0 * PI * 523.25 * time
                        )

                        // Cinematic combat impact effects
                        var impact = 0.0

                        for (impactTime in impacts) {
                            val distance = abs(time - impactTime)

                            impact = maxOf(
                                impact,
                                (1.0 - distance / 0.17)
                                    .coerceIn(0.0, 1.0)
                            )
                        }

                        val impactSound = sin(
                            2.0 * PI * (95.0 + impact * 110.0) * time
                        )

                        val sample = (
                            melody * 0.18 +
                            harmonic * 0.06 +
                            bass * 0.12 +
                            atmosphere * 0.02 +
                            impactSound * impact * 0.25
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
            name = "SYSTEM-Cinematic-Opening"
            start()
        }
    }

    fun stop() {
        running = false
    }
}
