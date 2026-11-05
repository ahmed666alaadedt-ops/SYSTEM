
package com.system.irtqaa

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun SystemAnimatedGlobe(
    modifier: Modifier = Modifier,
    globeSize: Dp = 112.dp
) {
    val rotation = rememberInfiniteTransition(
        label = "system-globe-rotation"
    )

    val angle by rotation.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 14000,
                easing = LinearEasing
            ),
            repeatMode = RepeatMode.Restart
        ),
        label = "globe-angle"
    )

    val pulse by rotation.animateFloat(
        initialValue = 0.75f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "globe-pulse"
    )

    Canvas(
        modifier = modifier.size(globeSize)
    ) {
        val diameter = size.minDimension * 0.78f
        val radius = diameter / 2f
        val center = Offset(
            size.width / 2f,
            size.height / 2f
        )

        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(
                    Color(0xFF55E8FF).copy(alpha = 0.28f * pulse),
                    Color(0xFF1684C7).copy(alpha = 0.12f),
                    Color.Transparent
                ),
                center = center,
                radius = radius * 1.55f
            ),
            radius = radius * 1.55f,
            center = center
        )

        drawCircle(
            brush = Brush.linearGradient(
                colors = listOf(
                    Color(0xFF36D9F5),
                    Color(0xFF07518C),
                    Color(0xFF06172D)
                ),
                start = Offset(
                    center.x - radius,
                    center.y - radius
                ),
                end = Offset(
                    center.x + radius,
                    center.y + radius
                )
            ),
            radius = radius,
            center = center
        )

        val globeBounds = Size(
            radius * 2f,
            radius * 2f
        )

        val globeTopLeft = Offset(
            center.x - radius,
            center.y - radius
        )

        for (index in 0..3) {
            val shift = (angle + index * 90f) % 360f
            val widthFactor =
                0.16f + 0.72f *
                kotlin.math.abs(
                    cos(Math.toRadians(shift.toDouble())).toFloat()
                )

            drawOval(
                color = Color(0xFF8BEAFF).copy(
                    alpha = 0.48f * pulse
                ),
                topLeft = Offset(
                    center.x - radius * widthFactor,
                    center.y - radius
                ),
                size = Size(
                    radius * 2f * widthFactor,
                    radius * 2f
                ),
                style = Stroke(width = 1.2.dp.toPx())
            )
        }

        val continentShift =
            Math.toRadians(angle.toDouble())

        val continentPoints = listOf(
            Offset(-0.42f, -0.20f),
            Offset(-0.16f, -0.34f),
            Offset(0.02f, -0.18f),
            Offset(-0.08f, 0.02f),
            Offset(-0.28f, 0.13f),
            Offset(-0.35f, 0.36f),
            Offset(0.12f, 0.30f),
            Offset(0.30f, 0.10f),
            Offset(0.22f, -0.12f),
            Offset(0.43f, -0.28f)
        )

        continentPoints.forEachIndexed { index, point ->
            val drift = sin(
                continentShift + index * 0.7
            ).toFloat()

            val x = center.x +
                point.x * radius +
                drift * radius * 0.035f

            val y = center.y + point.y * radius

            drawCircle(
                color = Color(0xFF70E7A0).copy(
                    alpha = 0.78f
                ),
                radius = 2.4.dp.toPx(),
                center = Offset(x, y)
            )
        }

        drawCircle(
            color = Color(0xFF8CEBFF).copy(alpha = 0.85f),
            radius = radius,
            center = center,
            style = Stroke(width = 1.5.dp.toPx())
        )

        drawCircle(
            color = Color.White.copy(alpha = 0.75f),
            radius = 2.2.dp.toPx(),
            center = Offset(
                center.x + cos(continentShift).toFloat() * radius,
                center.y + sin(continentShift).toFloat() * radius
            )
        )
    }
}
