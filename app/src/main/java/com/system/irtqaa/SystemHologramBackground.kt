
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
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun SystemHologramBackground(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val world = SystemWorldThemeRuntime.currentWorld

    val primary = when (world) {
        SystemWorldKind.MODERN_REALISTIC -> Color(0xFF35D9F2)
        SystemWorldKind.MYTHOLOGY_HISTORY -> Color(0xFFE6B65C)
        SystemWorldKind.FANTASY -> Color(0xFFB69BFF)
        SystemWorldKind.GREED_ISLAND -> Color(0xFF65E6A6)
        else -> Color(0xFF35D9F2)
    }

    val secondary = when (world) {
        SystemWorldKind.MODERN_REALISTIC -> Color(0xFF4388B8)
        SystemWorldKind.MYTHOLOGY_HISTORY -> Color(0xFFB96E3E)
        SystemWorldKind.FANTASY -> Color(0xFF5B72D6)
        SystemWorldKind.GREED_ISLAND -> Color(0xFF36AFC0)
        else -> Color(0xFF4388B8)
    }

    val backgroundTop = when (world) {
        SystemWorldKind.MODERN_REALISTIC -> Color(0xFF050A13)
        SystemWorldKind.MYTHOLOGY_HISTORY -> Color(0xFF28170F)
        SystemWorldKind.FANTASY -> Color(0xFF100D25)
        SystemWorldKind.GREED_ISLAND -> Color(0xFF062019)
        else -> Color(0xFF050A13)
    }

    val backgroundBottom = when (world) {
        SystemWorldKind.MODERN_REALISTIC -> Color(0xFF09182A)
        SystemWorldKind.MYTHOLOGY_HISTORY -> Color(0xFF49301B)
        SystemWorldKind.FANTASY -> Color(0xFF211747)
        SystemWorldKind.GREED_ISLAND -> Color(0xFF104638)
        else -> Color(0xFF09182A)
    }

    val transition = rememberInfiniteTransition(
        label = "world_background"
    )

    val pulse by transition.animateFloat(
        initialValue = 0.25f,
        targetValue = 0.85f,
        animationSpec = infiniteRepeatable(
            animation = tween(2800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "world_pulse"
    )

    val rotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 6.28318f,
        animationSpec = infiniteRepeatable(
            animation = tween(18000),
            repeatMode = RepeatMode.Restart
        ),
        label = "world_rotation"
    )

    Box(modifier = modifier) {
        Canvas(Modifier.fillMaxSize()) {
            drawRect(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        backgroundTop,
                        backgroundBottom
                    )
                )
            )

            val spacing = 34.dp.toPx()
            val gridAlpha = 0.025f + pulse * 0.045f

            var x = 0f
            while (x <= size.width) {
                drawLine(
                    primary.copy(alpha = gridAlpha),
                    Offset(x, 0f),
                    Offset(x, size.height),
                    1.dp.toPx()
                )
                x += spacing
            }

            var y = 0f
            while (y <= size.height) {
                drawLine(
                    primary.copy(alpha = gridAlpha),
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
                    color = primary.copy(
                        alpha = 0.055f + pulse * 0.055f
                    ),
                    radius = radius * (1f + ring * 0.42f),
                    center = center,
                    style = Stroke(1.3f.dp.toPx())
                )
            }

            val orbitRadius = radius * 1.85f

            val point = Offset(
                center.x + cos(rotation) * orbitRadius,
                center.y + sin(rotation) * orbitRadius
            )

            drawCircle(
                color = primary.copy(alpha = 0.9f),
                radius = 3.dp.toPx(),
                center = point
            )

            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        primary.copy(alpha = 0.13f + pulse * 0.04f),
                        secondary.copy(alpha = 0.035f),
                        Color.Transparent
                    ),
                    center = center,
                    radius = radius * 3.2f
                ),
                radius = radius * 3.2f,
                center = center
            )

            if (world == SystemWorldKind.GREED_ISLAND) {
                val coins = listOf(
                    Offset(0.12f, 0.30f),
                    Offset(0.88f, 0.32f),
                    Offset(0.18f, 0.68f),
                    Offset(0.84f, 0.72f),
                    Offset(0.52f, 0.90f)
                )

                coins.forEachIndexed { index, position ->
                    val coinCenter = Offset(
                        size.width * position.x,
                        size.height * position.y +
                            sin(rotation + index) * 5.dp.toPx()
                    )

                    val coinRadius = (9 + index % 3 * 3).dp.toPx()

                    drawCircle(
                        color = Color(0xFFFFC857).copy(
                            alpha = 0.16f + pulse * 0.08f
                        ),
                        radius = coinRadius,
                        center = coinCenter
                    )

                    drawCircle(
                        color = Color(0xFFFFE69A).copy(alpha = 0.35f),
                        radius = coinRadius,
                        center = coinCenter,
                        style = Stroke(1.2.dp.toPx())
                    )
                }
            }

            if (world == SystemWorldKind.MYTHOLOGY_HISTORY) {
                val horizon = size.height * 0.78f

                for (index in 0..4) {
                    val baseX = size.width * (0.12f + index * 0.19f)
                    val towerHeight = (35 + index % 3 * 17).dp.toPx()

                    drawRect(
                        color = secondary.copy(alpha = 0.12f),
                        topLeft = Offset(baseX, horizon - towerHeight),
                        size = androidx.compose.ui.geometry.Size(
                            18.dp.toPx(),
                            towerHeight
                        )
                    )
                }
            }

            if (world == SystemWorldKind.FANTASY) {
                for (index in 0..5) {
                    val starX = size.width * (0.12f + index * 0.15f)
                    val starY = size.height * (0.12f + (index % 3) * 0.12f)

                    drawCircle(
                        color = Color.White.copy(
                            alpha = 0.20f + pulse * 0.25f
                        ),
                        radius = 2.dp.toPx(),
                        center = Offset(starX, starY)
                    )
                }
            }
        }

        content()
    }
}
