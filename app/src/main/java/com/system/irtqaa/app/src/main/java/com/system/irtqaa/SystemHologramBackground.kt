
package com.system.irtqaa

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun SystemHologramBackground(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val transition = rememberInfiniteTransition(
        label = "system_hologram"
    )

    val pulse by transition.animateFloat(
        initialValue = 0.35f,
        targetValue = 0.9f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                2600,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse"
    )

    val rotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 6.28318f,
        animationSpec = infiniteRepeatable(
            animation = tween(18000),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    Box(modifier = modifier) {
        Canvas(Modifier.fillMaxSize()) {
            val cyan = Color(0xFF36D9F5)

            drawRect(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF050A13),
                        Color(0xFF071426),
                        Color(0xFF09182A)
                    )
                )
            )

            val spacing = 34.dp.toPx()
            val alpha = 0.055f + pulse * 0.035f

            var x = 0f
            while (x <= size.width) {
                drawLine(
                    cyan.copy(alpha = alpha),
                    Offset(x, 0f),
                    Offset(x, size.height),
                    1.dp.toPx()
                )
                x += spacing
            }

            var y = 0f
            while (y <= size.height) {
                drawLine(
                    cyan.copy(alpha = alpha),
                    Offset(0f, y),
                    Offset(size.width, y),
                    1.dp.toPx()
                )
                y += spacing
            }

            val center = Offset(
                size.width * 0.5f,
                size.height * 0.22f
            )

            val radius = size.minDimension * 0.19f

            for (ring in 0..2) {
                drawCircle(
                    color = cyan.copy(
                        alpha = 0.07f + pulse * 0.05f
                    ),
                    radius = radius * (1f + ring * 0.42f),
                    center = center,
                    style = Stroke(1.2f.dp.toPx())
                )
            }

            val orbitRadius = radius * 1.85f
            val point = Offset(
                center.x + kotlin.math.cos(rotation) * orbitRadius,
                center.y + kotlin.math.sin(rotation) * orbitRadius
            )

            drawCircle(
                color = cyan,
                radius = 3.dp.toPx(),
                center = point
            )

            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        cyan.copy(alpha = 0.12f),
                        Color.Transparent
                    ),
                    center = center,
                    radius = radius * 3.2f
                ),
                radius = radius * 3.2f,
                center = center
            )
        }

        content()
    }
}
