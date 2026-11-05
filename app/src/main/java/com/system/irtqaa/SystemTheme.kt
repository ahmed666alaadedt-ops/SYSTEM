package com.system.irtqaa

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

object SystemColors {
    val Background = Color(0xFF070B14)
    val Surface = Color(0xFF101827)
    val SurfaceVariant = Color(0xFF182438)
    val Gold = Color(0xFFFFC857)
    val GoldDark = Color(0xFFB98528)
    val Cyan = Color(0xFF35D9F2)
    val TextPrimary = Color(0xFFF4F7FC)
    val TextSecondary = Color(0xFF9BAAC0)
    val Success = Color(0xFF4ADE80)
    val Danger = Color(0xFFFF647C)
}

@Composable
fun SystemTheme(
    content: @Composable () -> Unit
) {
    val context = LocalContext.current

    val palette = remember(context) {
        SystemAppThemeSettings.getSelectedTheme(context)
    }

    val primary = Color(palette.primary)
    val secondary = Color(palette.secondary)
    val background = Color(palette.background)
    val surface = Color(palette.surface)
    val accent = Color(palette.accent)

    val colorScheme = darkColorScheme(
        primary = primary,
        onPrimary = background,
        secondary = secondary,
        onSecondary = background,
        tertiary = accent,
        onTertiary = background,
        background = background,
        onBackground = SystemColors.TextPrimary,
        surface = surface,
        onSurface = SystemColors.TextPrimary,
        surfaceVariant = secondary.copy(alpha = 0.22f),
        onSurfaceVariant = SystemColors.TextSecondary,
        error = SystemColors.Danger
    )

    MaterialTheme(
        colorScheme = colorScheme
    ) {
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            SystemThemeAmbientLighting(
                primary = primary,
                secondary = secondary
            )

            content()
        }
    }
}

@Composable
private fun SystemThemeAmbientLighting(
    primary: Color,
    secondary: Color
) {
    val transition = rememberInfiniteTransition(
        label = "system-theme-lighting"
    )

    val movement by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(8500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "system-theme-light-movement"
    )

    val breathing by transition.animateFloat(
        initialValue = 0.07f,
        targetValue = 0.19f,
        animationSpec = infiniteRepeatable(
            animation = tween(3200),
            repeatMode = RepeatMode.Reverse
        ),
        label = "system-theme-light-breathing"
    )

    Canvas(
        modifier = Modifier.fillMaxSize()
    ) {
        val width = size.width
        val height = size.height

        val firstCenter = Offset(
            x = width * (0.12f + movement * 0.24f),
            y = height * 0.18f
        )

        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(
                    primary.copy(alpha = breathing),
                    primary.copy(alpha = breathing * 0.25f),
                    Color.Transparent
                ),
                center = firstCenter,
                radius = width * 0.72f
            ),
            radius = width * 0.72f,
            center = firstCenter
        )

        val secondCenter = Offset(
            x = width * (0.88f - movement * 0.20f),
            y = height * 0.76f
        )

        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(
                    secondary.copy(alpha = breathing * 0.75f),
                    secondary.copy(alpha = 0.025f),
                    Color.Transparent
                ),
                center = secondCenter,
                radius = width * 0.62f
            ),
            radius = width * 0.62f,
            center = secondCenter
        )
    }
}
