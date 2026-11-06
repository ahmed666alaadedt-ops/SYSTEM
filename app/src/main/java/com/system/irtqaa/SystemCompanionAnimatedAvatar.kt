package com.system.irtqaa

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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun SystemCompanionAnimatedAvatar(
    appearance: SystemCompanionAppearance,
    modifier: Modifier = Modifier
) {
    val transition = rememberInfiniteTransition(
        label = "Companion animation"
    )

    val breathing by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "Breathing"
    )

    val floating by transition.animateFloat(
        initialValue = -2.5f,
        targetValue = 2.5f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400),
            repeatMode = RepeatMode.Reverse
        ),
        label = "Floating"
    )

    val female =
        appearance.gender == SystemCompanionGender.FEMALE

    val accent = when (appearance.world) {
        SystemWorldKind.MODERN_REALISTIC -> Color(0xFF43DDF4)
        SystemWorldKind.MYTHOLOGY_HISTORY -> Color(0xFFE7B65B)
        SystemWorldKind.FANTASY -> Color(0xFFB99AFF)
        SystemWorldKind.GREED_ISLAND -> Color(0xFF65E6A6)
    }

    val outfit = when (appearance.world) {
        SystemWorldKind.MODERN_REALISTIC -> Color(0xFF14263E)
        SystemWorldKind.MYTHOLOGY_HISTORY -> Color(0xFF68401F)
        SystemWorldKind.FANTASY -> Color(0xFF35245F)
        SystemWorldKind.GREED_ISLAND -> Color(0xFF164A3C)
    }

    Canvas(
        modifier = modifier
            .size(118.dp, 150.dp)
            .graphicsLayer {
                translationY = floating.dp.toPx()
            }
    ) {
        val w = size.width
        val h = size.height
        val cx = w * 0.5f
        val headY = h * 0.27f
        val headRadius = w * 0.155f
        val pulse = breathing * 0.12f

        drawCircle(
            color = accent.copy(alpha = 0.12f + pulse),
            radius = w * 0.43f,
            center = Offset(cx, h * 0.48f)
        )

        drawCircle(
            color = accent.copy(alpha = 0.5f),
            radius = w * 0.39f,
            center = Offset(cx, h * 0.48f),
            style = Stroke(width = 1.5.dp.toPx())
        )

        if (female) {
            val hair = Path().apply {
                moveTo(cx - headRadius * 0.9f, headY)
                quadraticTo(
                    cx - headRadius * 2.1f,
                    headY - headRadius * 0.9f,
                    cx - headRadius * 1.15f,
                    headY + headRadius * 1.9f
                )
                lineTo(cx - headRadius * 1.05f, h * 0.77f)
                quadraticTo(
                    cx, h * 0.85f,
                    cx + headRadius * 1.05f, h * 0.77f
                )
                lineTo(
                    cx + headRadius * 1.15f,
                    headY + headRadius * 1.9f
                )
                quadraticTo(
                    cx + headRadius * 2.1f,
                    headY - headRadius * 0.9f,
                    cx + headRadius * 0.9f,
                    headY
                )
                close()
            }
            drawPath(hair, Color(0xFF24182E))
        } else {
            drawOval(
                color = Color(0xFF29212D),
                topLeft = Offset(
                    cx - headRadius * 1.18f,
                    headY - headRadius * 1.05f
                ),
                size = Size(
                    headRadius * 2.36f,
                    headRadius * 1.65f
                )
            )
        }

        drawCircle(
            color = Color(0xFFEBC2A5),
            radius = headRadius,
            center = Offset(cx, headY)
        )

        val fringe = Path().apply {
            moveTo(
                cx - headRadius,
                headY - headRadius * 0.25f
            )
            quadraticTo(
                cx - headRadius * 0.65f,
                headY - headRadius * 1.35f,
                cx + headRadius * 0.15f,
                headY - headRadius * 0.95f
            )
            quadraticTo(
                cx + headRadius * 0.85f,
                headY - headRadius * 1.25f,
                cx + headRadius,
                headY - headRadius * 0.15f
            )
            lineTo(
                cx + headRadius * 0.45f,
                headY - headRadius * 0.48f
            )
            quadraticTo(
                cx,
                headY - headRadius * 0.05f,
                cx - headRadius,
                headY - headRadius * 0.25f
            )
            close()
        }

        drawPath(fringe, Color(0xFF24182E))

        val eyeY = headY + headRadius * 0.05f

        drawCircle(
            Color(0xFF302331),
            1.8.dp.toPx(),
            Offset(cx - headRadius * 0.38f, eyeY)
        )

        drawCircle(
            Color(0xFF302331),
            1.8.dp.toPx(),
            Offset(cx + headRadius * 0.38f, eyeY)
        )

        drawArc(
            color = Color(0xFFAD6570),
            startAngle = 15f,
            sweepAngle = 150f,
            useCenter = false,
            topLeft = Offset(
                cx - headRadius * 0.25f,
                headY + headRadius * 0.25f
            ),
            size = Size(
                headRadius * 0.5f,
                headRadius * 0.28f
            ),
            style = Stroke(width = 1.2.dp.toPx())
        )

        drawRect(
            color = Color(0xFFEBC2A5),
            topLeft = Offset(
                cx - w * 0.055f,
                headY + headRadius * 0.75f
            ),
            size = Size(w * 0.11f, h * 0.10f)
        )

        val body = Path().apply {
            moveTo(cx - w * 0.12f, h * 0.43f)
            quadraticTo(
                cx - w * 0.34f, h * 0.43f,
                cx - w * 0.43f, h * 0.61f
            )
            lineTo(cx - w * 0.35f, h * 0.95f)
            quadraticTo(
                cx, h * 1.02f,
                cx + w * 0.35f, h * 0.95f
            )
            lineTo(cx + w * 0.43f, h * 0.61f)
            quadraticTo(
                cx + w * 0.34f, h * 0.43f,
                cx + w * 0.12f, h * 0.43f
            )
            close()
        }

        drawPath(body, outfit)

        drawLine(
            color = accent,
            start = Offset(cx, h * 0.46f),
            end = Offset(cx, h * 0.94f),
            strokeWidth = 2.dp.toPx()
        )

        drawLine(
            color = accent.copy(alpha = 0.85f),
            start = Offset(cx - w * 0.30f, h * 0.64f),
            end = Offset(cx + w * 0.30f, h * 0.64f),
            strokeWidth = 1.5.dp.toPx()
        )

        drawCircle(
            color = accent,
            radius = w * 0.055f,
            center = Offset(cx, h * 0.58f)
        )

        drawCircle(
            color = outfit,
            radius = w * 0.028f,
            center = Offset(cx, h * 0.58f)
        )

        drawLine(
            color = accent.copy(alpha = 0.8f),
            start = Offset(cx - w * 0.39f, h * 0.62f),
            end = Offset(cx - w * 0.25f, h * 0.49f),
            strokeWidth = 2.dp.toPx()
        )

        drawLine(
            color = accent.copy(alpha = 0.8f),
            start = Offset(cx + w * 0.39f, h * 0.62f),
            end = Offset(cx + w * 0.25f, h * 0.49f),
            strokeWidth = 2.dp.toPx()
        )
    }
}
