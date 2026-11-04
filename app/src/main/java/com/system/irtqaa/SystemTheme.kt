package com.system.irtqaa

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

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

private val SystemDarkColorScheme = darkColorScheme(
    primary = SystemColors.Gold,
    onPrimary = SystemColors.Background,
    secondary = SystemColors.Cyan,
    onSecondary = SystemColors.Background,
    background = SystemColors.Background,
    onBackground = SystemColors.TextPrimary,
    surface = SystemColors.Surface,
    onSurface = SystemColors.TextPrimary,
    surfaceVariant = SystemColors.SurfaceVariant,
    onSurfaceVariant = SystemColors.TextSecondary,
    error = SystemColors.Danger
)

@Composable
fun SystemTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = SystemDarkColorScheme,
        content = content
    )
}
