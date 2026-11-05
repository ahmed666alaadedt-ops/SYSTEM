
package com.system.irtqaa

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.matchParentSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.hapticfeedback.LocalHapticFeedback
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

enum class SystemWorldKind {
    MODERN_REALISTIC,
    MYTHOLOGY_HISTORY,
    FANTASY,
    GREED_ISLAND
}

data class SystemWorldVisualStyle(
    val kind: SystemWorldKind,
    val title: String,
    val subtitle: String,
    val accent: Color,
    val secondary: Color,
    val deep: Color,
    val surface: Color
)

object SystemWorldVisualStyles {
    val modern = SystemWorldVisualStyle(
        SystemWorldKind.MODERN_REALISTIC,
        "العالم الواقعي الحديث", "مدن حقيقية وحياة معاصرة",
        Color(0xFF42D9E8), Color(0xFF4388B8),
        Color(0xFF071B2B), Color(0xFF102B3C)
    )

    val mythology = SystemWorldVisualStyle(
        SystemWorldKind.MYTHOLOGY_HISTORY,
        "عالم الأساطير والتاريخ", "حضارات قديمة وأساطير الشعوب",
        Color(0xFFE6B65C), Color(0xFFB96E3E),
        Color(0xFF28170F), Color(0xFF42291C)
    )

    val fantasy = SystemWorldVisualStyle(
        SystemWorldKind.FANTASY,
        "العالم الخيالي", "ممالك وسحر ومغامرات",
        Color(0xFFB69BFF), Color(0xFF5B72D6),
        Color(0xFF17132F), Color(0xFF29234B)
    )

    val greedIsland = SystemWorldVisualStyle(
        SystemWorldKind.GREED_ISLAND,
        "جزيرة الطمع", "جزيرة الأسرار والتحديات",
        Color(0xFF65E6A6), Color(0xFF36AFC0),
        Color(0xFF08251F), Color(0xFF123C35)
    )

    val all = listOf(modern, mythology, fantasy, greedIsland)

    fun forKind(kind: SystemWorldKind): SystemWorldVisualStyle =
        all.first { it.kind == kind }
}

object SystemMobileVisualTheme {
    val background = Color(0xFF070B12)
    val panel = Color(0xE6121D2D)
    val panelRaised = Color(0xFF19283B)
    val gold = Color(0xFFD9A441)
    val cyan = Color(0xFF25D9E8)
    val textPrimary = Color(0xFFF4F7FC)
    val textSecondary = Color(0xFFB7C5D6)
}

@Composable
fun SystemWorldThemeGallery(
    onWorldSelected: (SystemWorldKind) -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedKind by remember { mutableStateOf<SystemWorldKind?>(null) }
    var visibleCardCount by remember { mutableStateOf(0) }

    LaunchedEffect(Unit) {
        for (index in 1..SystemWorldVisualStyles.all.size) {
            delay(150)
            visibleCardCount = index
        }
    }

    LaunchedEffect(selectedKind) {
        val selected = selectedKind
        if (selected != null) {
            delay(260)
            onWorldSelected(selected)
        }
    }

    Box(modifier = modifier.fillMaxWidth()) {
        SystemWorldAmbientBackground(
            modifier = Modifier.matchParentSize()
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Text(
                text = "عوالم SYSTEM",
                color = SystemMobileVisualTheme.gold,
                fontSize = 23.sp,
                fontWeight = FontWeight.Black
            )

            Text(
                text = "أربع بوابات مستقلة، ولكل عالم هويته وألوانه الخاصة.",
                color = SystemMobileVisualTheme.textSecondary,
                fontSize = 13.sp
            )

            SystemWorldVisualStyles.all.forEachIndexed { index, style ->
                AnimatedVisibility(
                    visible = visibleCardCount > index,
                    enter = fadeIn(
                        animationSpec = tween(480)
                    ) + slideInHorizontally(
                        initialOffsetX = { fullWidth -> fullWidth / 4 },
                        animationSpec = tween(480)
                    )
                ) {
                    SystemWorldThemeCard(
                        style = style,
                        selected = selectedKind == style.kind,
                        enabled = selectedKind == null,
                        onClick = { selectedKind = style.kind }
                    )
                }
            }
        }
    }
}

@Composable
private fun SystemWorldAmbientBackground(
    modifier: Modifier = Modifier
) {
    val transition = rememberInfiniteTransition(
        label = "world-ambient-particles"
    )

    val progress by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(9000),
            repeatMode = RepeatMode.Restart
        ),
        label = "ambient-particle-progress"
    )

    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height

        drawRect(
            brush = Brush.verticalGradient(
                colors = listOf(
                    Color(0xFF07111E).copy(alpha = 0.12f),
                    Color(0xFF0B1422).copy(alpha = 0.04f),
                    Color.Transparent
                )
            ),
            size = size
        )

        val particleColors = listOf(
            SystemWorldVisualStyles.modern.accent,
            SystemWorldVisualStyles.mythology.accent,
            SystemWorldVisualStyles.fantasy.accent,
            SystemWorldVisualStyles.greedIsland.accent
        )

        for (index in 0 until 22) {
            val seed = index + 1
            val xFactor = ((seed * 37) % 97) / 100f
            val baseY = ((seed * 53) % 101) / 100f
            val travel = (progress + seed * 0.071f) % 1f
            val yFactor = (baseY + travel * 0.22f) % 1f
            val radius = (1.1f + (seed % 4) * 0.55f).dp.toPx()

            val pulse = 0.24f + 0.30f *
                (0.5f + 0.5f * kotlin.math.sin(
                    (progress * 6.28318f) + seed
                ))

            drawCircle(
                color = particleColors[index % particleColors.size]
                    .copy(alpha = pulse),
                radius = radius,
                center = Offset(width * xFactor, height * yFactor)
            )
        }

        drawCircle(
            brush = Brush.radialGradient(
                colors = listOf(
                    SystemWorldVisualStyles.fantasy.accent.copy(alpha = 0.055f),
                    Color.Transparent
                ),
                center = Offset(width * 0.92f, height * 0.28f),
                radius = width * 0.58f
            ),
            radius = width * 0.58f,
            center = Offset(width * 0.92f, height * 0.28f)
        )
    }
}

@Composable
fun SystemWorldThemeCard(
    style: SystemWorldVisualStyle,
    selected: Boolean = false,
    enabled: Boolean = true,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember {
        MutableInteractionSource()
    }

    val isPressed by interactionSource.collectIsPressedAsState()
    val haptic = LocalHapticFeedback.current

    // نبض ضوئي متكرر للبطاقة المحددة.
    val glowTransition = rememberInfiniteTransition(
        label = "selected-world-glow"
    )

    val glowAlpha by glowTransition.animateFloat(
        initialValue = 0.18f,
        targetValue = 0.75f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 1700
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "selected-world-glow-alpha"
    )

    val animatedScale by animateFloatAsState(
        targetValue = when {
            isPressed -> 0.975f
            selected -> 1.035f
            else -> 1f
        },
        animationSpec = tween(160),
        label = "world-card-scale"
    )

    val animatedAlpha by animateFloatAsState(
        targetValue = if (!enabled && !selected) 0.58f else 1f,
        animationSpec = tween(220),
        label = "world-card-alpha"
    )

    val animatedContainer by animateColorAsState(
        targetValue = when {
            isPressed -> style.accent.copy(alpha = 0.22f)
            selected -> style.accent.copy(alpha = 0.30f)
            else -> style.surface
        },
        animationSpec = tween(220),
        label = "world-card-color"
    )

    val animatedBorderColor by animateColorAsState(
        targetValue = when {
            selected -> style.accent.copy(alpha = glowAlpha)
            isPressed -> style.accent.copy(alpha = 0.85f)
            else -> style.accent.copy(alpha = 0.24f)
        },
        animationSpec = tween(180),
        label = "world-card-border-color"
    )

    val animatedBorderWidth by animateDpAsState(
        targetValue = when {
            selected -> 2.5.dp
            isPressed -> 2.dp
            else -> 1.dp
        },
        animationSpec = tween(180),
        label = "world-card-border-width"
    )

    val animatedElevation by animateDpAsState(
        targetValue = when {
            isPressed -> 3.dp
            selected -> 14.dp
            else -> 7.dp
        },
        animationSpec = tween(180),
        label = "world-card-elevation"
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = animatedScale
                scaleY = animatedScale
                alpha = animatedAlpha
            }
            .border(
                width = animatedBorderWidth,
                color = animatedBorderColor,
                shape = RoundedCornerShape(22.dp)
            )
            .semantics(mergeDescendants = true) {
                contentDescription = "${style.title}. ${style.subtitle}"
                this.selected = selected
            }
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                enabled = enabled,
                role = Role.Button,
                onClick = {
                    haptic.performHapticFeedback(
                        HapticFeedbackType.LongPress
                    )
                    onClick()
                }
            ),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(
            containerColor = animatedContainer
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = animatedElevation
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.linearGradient(
                        listOf(
                            style.deep,
                            if (selected || isPressed) {
                                style.accent.copy(alpha = 0.30f)
                            } else {
                                style.surface
                            },
                            style.secondary.copy(alpha = 0.48f)
                        )
                    )
                )
                .padding(15.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            SystemWorldThreeDimensionalEmblem(
                style = style,
                modifier = Modifier.size(112.dp)
            )

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                Text(
                    style.title,
                    color = Color.White,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    style.subtitle,
                    color = Color(0xFFD1DCE8),
                    fontSize = 12.sp
                )

                Text(
                    if (selected) "جاري فتح البوابة..."
                    else if (!enabled) "غير متاح حالياً"
                    else "دخول العالم  ←",
                    color = style.accent,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
fun SystemWorldThreeDimensionalEmblem(
    style: SystemWorldVisualStyle,
    modifier: Modifier = Modifier
) {
    val lightTransition = rememberInfiniteTransition(
        label = "world-emblem-light"
    )

    val lightPosition by lightTransition.animateFloat(
        initialValue = -0.85f,
        targetValue = 1.85f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 3200,
                delayMillis = 350
            ),
            repeatMode = RepeatMode.Restart
        ),
        label = "world-emblem-shimmer"
    )

    Canvas(
        modifier = modifier.clip(RoundedCornerShape(20.dp))
    ) {
        val w = size.width
        val h = size.height

        drawRoundRect(
            brush = Brush.linearGradient(
                listOf(
                    style.secondary.copy(alpha = 0.65f),
                    style.deep,
                    Color.Black.copy(alpha = 0.45f)
                )
            ),
            topLeft = Offset(w * 0.04f, h * 0.04f),
            size = Size(w * 0.92f, h * 0.92f),
            cornerRadius = CornerRadius(w * 0.16f)
        )

        drawCircle(
            brush = Brush.radialGradient(
                listOf(
                    style.accent.copy(alpha = 0.34f),
                    style.accent.copy(alpha = 0.02f),
                    Color.Transparent
                ),
                radius = w * 0.48f
            ),
            radius = w * 0.46f,
            center = Offset(w * 0.5f, h * 0.49f)
        )

        when (style.kind) {
            SystemWorldKind.MODERN_REALISTIC -> {
                val buildings = listOf(
                    floatArrayOf(0.16f, 0.48f, 0.17f, 0.35f),
                    floatArrayOf(0.36f, 0.34f, 0.18f, 0.49f),
                    floatArrayOf(0.58f, 0.43f, 0.14f, 0.40f),
                    floatArrayOf(0.75f, 0.51f, 0.10f, 0.32f)
                )

                buildings.forEach { b ->
                    drawRect(
                        Brush.horizontalGradient(
                            listOf(
                                style.secondary,
                                style.accent.copy(alpha = 0.55f)
                            )
                        ),
                        Offset(w * b[0], h * b[1]),
                        Size(w * b[2], h * b[3])
                    )

                    for (r in 0..3) {
                        drawLine(
                            style.accent.copy(alpha = 0.8f),
                            Offset(
                                w * (b[0] + 0.035f),
                                h * (b[1] + 0.06f + r * 0.065f)
                            ),
                            Offset(
                                w * (b[0] + b[2] - 0.025f),
                                h * (b[1] + 0.06f + r * 0.065f)
                            ),
                            1.4.dp.toPx()
                        )
                    }
                }

                drawLine(
                    style.accent,
                    Offset(w * 0.10f, h * 0.84f),
                    Offset(w * 0.90f, h * 0.84f),
                    3.dp.toPx()
                )
            }

            SystemWorldKind.MYTHOLOGY_HISTORY -> {
                val roof = Path().apply {
                    moveTo(w * 0.12f, h * 0.36f)
                    lineTo(w * 0.50f, h * 0.15f)
                    lineTo(w * 0.88f, h * 0.36f)
                    close()
                }

                drawPath(roof, style.accent)

                drawRect(
                    Brush.verticalGradient(
                        listOf(
                            style.accent,
                            style.secondary,
                            style.deep
                        )
                    ),
                    Offset(w * 0.20f, h * 0.36f),
                    Size(w * 0.60f, h * 0.39f)
                )

                for (x in listOf(0.29f, 0.43f, 0.57f, 0.71f)) {
                    drawRoundRect(
                        Color(0xFFFFD995),
                        Offset(w * x, h * 0.40f),
                        Size(w * 0.055f, h * 0.31f),
                        CornerRadius(3.dp.toPx())
                    )
                }

                drawRect(
                    style.deep,
                    Offset(w * 0.44f, h * 0.55f),
                    Size(w * 0.12f, h * 0.20f)
                )

                drawLine(
                    style.accent,
                    Offset(w * 0.15f, h * 0.77f),
                    Offset(w * 0.85f, h * 0.77f),
                    3.dp.toPx()
                )
            }

            SystemWorldKind.FANTASY -> {
                drawCircle(
                    style.accent.copy(alpha = 0.85f),
                    w * 0.105f,
                    Offset(w * 0.73f, h * 0.25f)
                )

                val mountain = Path().apply {
                    moveTo(w * 0.08f, h * 0.82f)
                    lineTo(w * 0.34f, h * 0.42f)
                    lineTo(w * 0.49f, h * 0.64f)
                    lineTo(w * 0.68f, h * 0.36f)
                    lineTo(w * 0.94f, h * 0.82f)
                    close()
                }

                drawPath(
                    mountain,
                    Brush.verticalGradient(
                        listOf(style.secondary, style.deep)
                    )
                )

                drawRect(
                    style.accent,
                    Offset(w * 0.39f, h * 0.48f),
                    Size(w * 0.25f, h * 0.28f)
                )

                for (x in listOf(0.34f, 0.61f)) {
                    drawRect(
                        style.secondary,
                        Offset(w * x, h * 0.42f),
                        Size(w * 0.08f, h * 0.34f)
                    )

                    val tower = Path().apply {
                        moveTo(w * x, h * 0.43f)
                        lineTo(w * (x + 0.04f), h * 0.30f)
                        lineTo(w * (x + 0.08f), h * 0.43f)
                        close()
                    }

                    drawPath(tower, style.accent)
                }

                drawCircle(
                    style.accent,
                    2.dp.toPx(),
                    Offset(w * 0.20f, h * 0.28f)
                )
            }

            SystemWorldKind.GREED_ISLAND -> {
                drawOval(
                    Brush.verticalGradient(
                        listOf(
                            style.accent.copy(alpha = 0.7f),
                            style.secondary
                        )
                    ),
                    Offset(w * 0.12f, h * 0.58f),
                    Size(w * 0.76f, h * 0.23f)
                )

                val island = Path().apply {
                    moveTo(w * 0.22f, h * 0.62f)
                    quadraticTo(
                        w * 0.50f, h * 0.38f,
                        w * 0.78f, h * 0.62f
                    )
                    lineTo(w * 0.70f, h * 0.73f)
                    lineTo(w * 0.30f, h * 0.73f)
                    close()
                }

                drawPath(
                    island,
                    Brush.verticalGradient(
                        listOf(
                            Color(0xFFFFD78A),
                            Color(0xFF9B693C)
                        )
                    )
                )

                drawLine(
                    Color(0xFF8D5734),
                    Offset(w * 0.53f, h * 0.59f),
                    Offset(w * 0.57f, h * 0.30f),
                    4.dp.toPx()
                )

                for (angle in listOf(-0.9f, -0.35f, 0.25f, 0.75f)) {
                    drawLine(
                        style.accent,
                        Offset(w * 0.57f, h * 0.31f),
                        Offset(
                            w * (0.57f + angle * 0.22f),
                            h * (0.20f + kotlin.math.abs(angle) * 0.10f)
                        ),
                        4.dp.toPx()
                    )
                }

                drawCircle(
                    Color(0xFFFFE7A8),
                    w * 0.075f,
                    Offset(w * 0.25f, h * 0.22f)
                )

                drawOval(
                    style.accent.copy(alpha = 0.65f),
                    Offset(w * 0.18f, h * 0.78f),
                    Size(w * 0.64f, h * 0.045f),
                    style = Stroke(width = 1.5.dp.toPx())
                )
            }
        }

        drawRect(
            brush = Brush.linearGradient(
                colors = listOf(
                    Color.Transparent,
                    Color.White.copy(alpha = 0.025f),
                    style.accent.copy(alpha = 0.16f),
                    Color.White.copy(alpha = 0.10f),
                    Color.Transparent
                ),
                start = Offset(w * lightPosition, h * 0.08f),
                end = Offset(w * (lightPosition + 0.48f), h * 0.92f)
            ),
            topLeft = Offset.Zero,
            size = Size(w, h)
        )

        drawLine(
            brush = Brush.horizontalGradient(
                listOf(
                    Color.Transparent,
                    style.accent.copy(alpha = 0.72f),
                    Color.Transparent
                )
            ),
            start = Offset(w * 0.18f, h * 0.91f),
            end = Offset(w * 0.82f, h * 0.91f),
            strokeWidth = 2.dp.toPx()
        )

        drawRoundRect(
            Color.White.copy(alpha = 0.10f),
            Offset(w * 0.04f, h * 0.04f),
            Size(w * 0.92f, h * 0.92f),
            CornerRadius(w * 0.16f),
            style = Stroke(width = 1.dp.toPx())
        )

        drawRoundRect(
            style.accent.copy(alpha = 0.72f),
            Offset(w * 0.04f, h * 0.04f),
            Size(w * 0.92f, h * 0.92f),
            CornerRadius(w * 0.16f),
            style = Stroke(width = 1.2.dp.toPx())
        )
    }
}
