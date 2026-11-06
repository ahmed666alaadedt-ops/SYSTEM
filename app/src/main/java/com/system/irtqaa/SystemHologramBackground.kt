
package com.system.irtqaa

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
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
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.unit.dp
import kotlin.math.cos
import kotlin.math.sin

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

    val coinRotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 16000,
                easing = LinearEasing
            ),
            repeatMode = RepeatMode.Restart
        ),
        label = "belly_coin_rotation"
    )

    val coinFloat by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 3200,
                easing = FastOutSlowInEasing
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "belly_coin_float"
    )

    Box(modifier = modifier) {

        Canvas(Modifier.fillMaxSize()) {
            val cyan = Color(0xFF36D9F5)
            val gold = Color(0xFFFFC857)

            // خلفية SYSTEM الأساسية
            drawRect(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF050A13),
                        Color(0xFF071426),
                        Color(0xFF09182A)
                    )
                )
            )

            // الشبكة الهولوغرافية
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

            // حلقات الطاقة
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
                center.x + cos(rotation) * orbitRadius,
                center.y + sin(rotation) * orbitRadius
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

            // عملات Belly الذهبية بالخلفية
            val coinPositions = listOf(
                Offset(0.12f, 0.30f),
                Offset(0.88f, 0.32f),
                Offset(0.18f, 0.68f),
                Offset(0.84f, 0.72f),
                Offset(0.52f, 0.90f),
                Offset(0.96f, 0.53f)
            )

            coinPositions.forEachIndexed { index, position ->

                val coinCenter = Offset(
                    x = size.width * position.x,
                    y = size.height * position.y +
                        sin(
                            coinFloat * Math.PI * 2.0 +
                                index.toDouble()
                        ).toFloat() * 5.dp.toPx()
                )

                val coinRadius =
                    (10 + (index % 3) * 3).dp.toPx()

                val coinAlpha =
                    0.17f + pulse * 0.055f

                rotate(
                    degrees = coinRotation * if (index % 2 == 0) {
                        1f
                    } else {
                        -0.7f
                    } + index * 31f,
                    pivot = coinCenter
                ) {

                    // جسم العملة الذهبي
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                Color(0xFFFFF0A0).copy(
                                    alpha = coinAlpha
                                ),
                                Color(0xFFFFC857).copy(
                                    alpha = coinAlpha
                                ),
                                Color(0xFF9C641B).copy(
                                    alpha = coinAlpha
                                )
                            ),
                            center = coinCenter,
                            radius = coinRadius
                        ),
                        radius = coinRadius,
                        center = coinCenter
                    )

                    // الحافة الخارجية
                    drawCircle(
                        color = gold.copy(
                            alpha = coinAlpha + 0.12f
                        ),
                        radius = coinRadius,
                        center = coinCenter,
                        style = Stroke(
                            width = 1.5.dp.toPx()
                        )
                    )

                    // النقش الداخلي
                    drawCircle(
                        color = Color(0xFFFFE69A).copy(
                            alpha = coinAlpha + 0.08f
                        ),
                        radius = coinRadius * 0.72f,
                        center = coinCenter,
                        style = Stroke(
                            width = 1.dp.toPx()
                        )
                    )

                    // رمز زخرفي مستوحى من العملات
                    drawLine(
                        color = Color(0xFFFFF1B8).copy(
                            alpha = coinAlpha + 0.12f
                        ),
                        start = Offset(
                            coinCenter.x,
                            coinCenter.y - coinRadius * 0.38f
                        ),
                        end = Offset(
                            coinCenter.x,
                            coinCenter.y + coinRadius * 0.38f
                        ),
                        strokeWidth = 1.8.dp.toPx()
                    )

                    drawLine(
                        color = Color(0xFFFFF1B8).copy(
                            alpha = coinAlpha + 0.12f
                        ),
                        start = Offset(
                            coinCenter.x - coinRadius * 0.24f,
                            coinCenter.y - coinRadius * 0.20f
                        ),
                        end = Offset(
                            coinCenter.x + coinRadius * 0.25f,
                            coinCenter.y - coinRadius * 0.20f
                        ),
                        strokeWidth = 1.5.dp.toPx()
                    )

                    drawLine(
                        color = Color(0xFFFFF1B8).copy(
                            alpha = coinAlpha + 0.12f
                        ),
                        start = Offset(
                            coinCenter.x - coinRadius * 0.24f,
                            coinCenter.y + coinRadius * 0.20f
                        ),
                        end = Offset(
                            coinCenter.x + coinRadius * 0.25f,
                            coinCenter.y + coinRadius * 0.20f
                        ),
                        strokeWidth = 1.5.dp.toPx()
                    )
                }
            }
        }

        // محتوى التطبيق يبقى فوق الخلفية
        content()
    }
}
