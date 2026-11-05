
package com.system.irtqaa

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.sin

@Composable
fun SystemThemeSelectionScreen(
    onBack: () -> Unit,
    onThemeSelected: (String) -> Unit
) {
    val context = LocalContext.current

    var selectedTheme by remember {
        mutableStateOf(
            SystemAppThemeSettings.getSelectedTheme(context).id
        )
    }

    val themes = SystemAppThemeCatalog.all

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        Button(onClick = onBack) {
            Text("رجوع")
        }

        Text(
            "SYSTEM DIMENSION",
            color = MaterialTheme.colorScheme.primary,
            fontSize = 25.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            "اختر العالم الذي تريد أن تعيش أجواءه",
            color = Color.White,
            fontSize = 21.sp,
            fontWeight = FontWeight.Bold
        )

        Text(
            "كل عالم له بيئته وألوانه وشخصيته الخاصة.",
            color = Color.LightGray,
            fontSize = 14.sp
        )

        themes.forEach { theme ->
            SystemThemeDimensionCard(
                theme = theme,
                selected = selectedTheme == theme.id,
                onClick = {
                    val saved =
                        SystemAppThemeSettings.saveSelectedTheme(
                            context,
                            theme.id
                        )

                    if (saved) {
                        selectedTheme = theme.id
                        onThemeSelected(theme.id)
                    }
                }
            )
        }

        Text(
            "سيتم حفظ اختيارك على هذا الجهاز.",
            color = Color.LightGray,
            fontSize = 12.sp
        )

        Spacer(Modifier.height(20.dp))
    }
}

@Composable
private fun SystemThemeDimensionCard(
    theme: SystemAppThemePalette,
    selected: Boolean,
    onClick: () -> Unit
) {
    val primary = Color(theme.primary)
    val secondary = Color(theme.secondary)
    val background = Color(theme.background)
    val accent = Color(theme.accent)

    val transition = rememberInfiniteTransition(
        label = "world-${theme.id}"
    )

    val rotation by transition.animateFloat(
        initialValue = -1.2f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(4200),
            repeatMode = RepeatMode.Reverse
        ),
        label = "world-rotation"
    )

    val movement by transition.animateFloat(
        initialValue = -12f,
        targetValue = 12f,
        animationSpec = infiniteRepeatable(
            animation = tween(5000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "world-movement"
    )

    val light by transition.animateFloat(
        initialValue = 0.18f,
        targetValue = 0.42f,
        animationSpec = infiniteRepeatable(
            animation = tween(2800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "world-light"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(225.dp)
            .graphicsLayer {
                rotationY = rotation
                rotationZ = rotation * 0.12f
                cameraDistance = 22f * density
                shadowElevation = if (selected) 22f else 10f
            }
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(25.dp),
        colors = CardDefaults.cardColors(
            containerColor = background
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (selected) 15.dp else 8.dp
        )
    ) {
        Box(Modifier.fillMaxSize()) {

            Canvas(Modifier.fillMaxSize()) {
                val w = size.width
                val h = size.height

                drawRect(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            background,
                            secondary.copy(alpha = 0.65f),
                            background
                        )
                    )
                )

                val sunCenter = Offset(
                    x = w * 0.78f + movement,
                    y = h * 0.32f
                )

                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            primary.copy(alpha = light),
                            secondary.copy(alpha = 0.16f),
                            Color.Transparent
                        ),
                        center = sunCenter,
                        radius = h * 0.95f
                    ),
                    radius = h * 0.95f,
                    center = sunCenter
                )

                // ضوء الأفق
                drawRect(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            primary.copy(alpha = 0.08f),
                            Color.Transparent
                        ),
                        startY = h * 0.35f,
                        endY = h
                    )
                )

                when (theme.id) {
                    "modern" -> {
                        drawModernCity(w, h, primary, secondary, movement)
                    }

                    "historical" -> {
                        drawHistoricalWorld(w, h, primary, secondary)
                    }

                    "fantasy" -> {
                        drawFantasyWorld(w, h, primary, secondary, movement)
                    }

                    "greed" -> {
                        drawGreedIsland(w, h, primary, secondary, movement)
                    }
                }

                // نقاط ضوء وجسيمات في الجو
                for (i in 0..17) {
                    val x = w * ((i * 37 % 100) / 100f)
                    val y = h * ((i * 23 % 70) / 100f)

                    val pulse = 0.25f +
                        0.25f * sin(light * 8f + i)

                    drawCircle(
                        color = accent.copy(alpha = pulse),
                        radius = (1.2f + i % 3).dp.toPx(),
                        center = Offset(x, y)
                    )
                }

                // إطار ضوئي حول المشهد
                drawRoundRect(
                    color = primary.copy(
                        alpha = if (selected) 0.75f else 0.25f
                    ),
                    style = Stroke(
                        width = if (selected) 2.4.dp.toPx()
                        else 1.dp.toPx()
                    ),
                    size = size
                )
            }

            // طبقة ظل لتوضيح النص
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                background.copy(alpha = 0.96f),
                                background.copy(alpha = 0.75f),
                                Color.Transparent
                            ),
                            startX = 0f,
                            endX = sizeWidth()
                        )
                    )
            )

            Column(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .padding(18.dp)
                    .fillMaxWidth(0.76f)
            ) {
                Text(
                    theme.name,
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Black
                )

                Spacer(Modifier.height(8.dp))

                Text(
                    theme.description,
                    color = Color.White.copy(alpha = 0.86f),
                    fontSize = 12.sp
                )

                Spacer(Modifier.height(19.dp))

                Text(
                    if (selected) "✓ العالم المختار"
                    else "اضغط للدخول إلى هذا الثيم",
                    color = accent,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp
                )
            }

            if (selected) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(12.dp)
                        .clip(RoundedCornerShape(50))
                        .background(accent.copy(alpha = 0.22f))
                        .padding(
                            horizontal = 12.dp,
                            vertical = 7.dp
                        )
                ) {
                    Text(
                        "ACTIVE",
                        color = accent,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Black
                    )
                }
            }
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawModernCity(
    w: Float,
    h: Float,
    primary: Color,
    secondary: Color,
    movement: Float
) {
    val base = h * 0.78f

    // مبانٍ بعيدة
    for (i in 0..10) {
        val x = w * (i / 11f)
        val buildingWidth = w * 0.075f
        val buildingHeight = h * (0.20f + (i % 4) * 0.08f)

        drawRect(
            color = secondary.copy(alpha = 0.35f),
            topLeft = Offset(x, base - buildingHeight),
            size = androidx.compose.ui.geometry.Size(
                buildingWidth,
                buildingHeight
            )
        )

        for (row in 0..3) {
            drawRect(
                color = primary.copy(alpha = 0.45f),
                topLeft = Offset(
                    x + buildingWidth * 0.25f,
                    base - buildingHeight + row * 12.dp.toPx()
                ),
                size = androidx.compose.ui.geometry.Size(
                    3.dp.toPx(),
                    5.dp.toPx()
                )
            )
        }
    }

    // برج مركزي
    drawRect(
        brush = Brush.verticalGradient(
            listOf(primary.copy(alpha = 0.65f), secondary)
        ),
        topLeft = Offset(w * 0.72f + movement * 0.3f, h * 0.22f),
        size = androidx.compose.ui.geometry.Size(
            w * 0.09f,
            h * 0.58f
        )
    )

    drawCircle(
        color = primary.copy(alpha = 0.7f),
        radius = 3.dp.toPx(),
        center = Offset(w * 0.765f + movement * 0.3f, h * 0.19f)
    )

    drawRect(
        color = Color.Black.copy(alpha = 0.32f),
        topLeft = Offset(0f, base),
        size = androidx.compose.ui.geometry.Size(w, h - base)
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawHistoricalWorld(
    w: Float,
    h: Float,
    primary: Color,
    secondary: Color
) {
    val ground = h * 0.79f

    // الأفق الصحراوي
    val dunes = Path().apply {
        moveTo(0f, ground)
        cubicTo(
            w * 0.25f, h * 0.64f,
            w * 0.45f, h * 0.83f,
            w * 0.68f, h * 0.73f
        )
        cubicTo(
            w * 0.84f, h * 0.65f,
            w * 0.92f, h * 0.75f,
            w, ground
        )
        lineTo(w, h)
        lineTo(0f, h)
        close()
    }

    drawPath(
        dunes,
        color = secondary.copy(alpha = 0.62f)
    )

    // أهرامات
    for (i in 0..2) {
        val x = w * (0.58f + i * 0.13f)
        val width = w * 0.15f
        val height = h * (0.28f + (i % 2) * 0.08f)

        val pyramid = Path().apply {
            moveTo(x, ground)
            lineTo(x + width / 2f, ground - height)
            lineTo(x + width, ground)
            close()
        }

        drawPath(
            pyramid,
            color = primary.copy(alpha = 0.66f)
        )

        drawLine(
            color = Color.White.copy(alpha = 0.16f),
            start = Offset(x + width / 2f, ground - height),
            end = Offset(x + width * 0.72f, ground),
            strokeWidth = 1.5.dp.toPx()
        )
    }

    // أعمدة أثرية
    for (i in 0..2) {
        val x = w * (0.12f + i * 0.11f)

        drawRect(
            color = primary.copy(alpha = 0.52f),
            topLeft = Offset(x, h * 0.42f),
            size = androidx.compose.ui.geometry.Size(
                w * 0.035f,
                h * 0.37f
            )
        )

        drawRect(
            color = primary.copy(alpha = 0.75f),
            topLeft = Offset(x - 5.dp.toPx(), h * 0.40f),
            size = androidx.compose.ui.geometry.Size(
                w * 0.055f,
                7.dp.toPx()
            )
        )
    }

    drawCircle(
        color = Color(0xFFFFD98A).copy(alpha = 0.75f),
        radius = h * 0.10f,
        center = Offset(w * 0.84f, h * 0.20f)
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFantasyWorld(
    w: Float,
    h: Float,
    primary: Color,
    secondary: Color,
    movement: Float
) {
    // جبال بعيدة
    val mountains = Path().apply {
        moveTo(0f, h * 0.78f)
        lineTo(w * 0.22f, h * 0.27f)
        lineTo(w * 0.40f, h * 0.72f)
        lineTo(w * 0.63f, h * 0.20f)
        lineTo(w * 0.88f, h * 0.72f)
        lineTo(w, h * 0.48f)
        lineTo(w, h)
        lineTo(0f, h)
        close()
    }

    drawPath(
        mountains,
        color = secondary.copy(alpha = 0.55f)
    )

    // قمة مضيئة
    drawPath(
        Path().apply {
            moveTo(w * 0.55f, h * 0.40f)
            lineTo(w * 0.63f, h * 0.20f)
            lineTo(w * 0.72f, h * 0.40f)
            close()
        },
        color = Color.White.copy(alpha = 0.35f)
    )

    // قلعة خيالية
    val castleX = w * 0.73f + movement * 0.25f

    drawRect(
        color = primary.copy(alpha = 0.60f),
        topLeft = Offset(castleX, h * 0.45f),
        size = androidx.compose.ui.geometry.Size(
            w * 0.13f,
            h * 0.28f
        )
    )

    for (i in 0..2) {
        val x = castleX + i * w * 0.045f

        drawRect(
            color = primary.copy(alpha = 0.75f),
            topLeft = Offset(x, h * 0.35f),
            size = androidx.compose.ui.geometry.Size(
                w * 0.025f,
                h * 0.12f
            )
        )
    }

    // هالة سحرية
    drawCircle(
        brush = Brush.radialGradient(
            colors = listOf(
                primary.copy(alpha = 0.50f),
                Color.Transparent
            ),
            center = Offset(w * 0.78f, h * 0.39f),
            radius = h * 0.35f
        ),
        radius = h * 0.35f,
        center = Offset(w * 0.78f, h * 0.39f)
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawGreedIsland(
    w: Float,
    h: Float,
    primary: Color,
    secondary: Color,
    movement: Float
) {
    // سماء الجزيرة
    drawCircle(
        color = primary.copy(alpha = 0.28f),
        radius = h * 0.27f,
        center = Offset(w * 0.78f + movement, h * 0.25f)
    )

    // الجزيرة العائمة
    val island = Path().apply {
        moveTo(w * 0.34f, h * 0.46f)
        cubicTo(
            w * 0.48f, h * 0.35f,
            w * 0.72f, h * 0.35f,
            w * 0.88f, h * 0.48f
        )
        lineTo(w * 0.76f, h * 0.67f)
        lineTo(w * 0.65f, h * 0.88f)
        lineTo(w * 0.51f, h * 0.67f)
        close()
    }

    drawPath(
        island,
        brush = Brush.verticalGradient(
            listOf(
                primary.copy(alpha = 0.85f),
                secondary.copy(alpha = 0.65f),
                Color(0xFF392B24)
            )
        )
    )

    // أشجار الجزيرة
    for (i in 0..4) {
        val x = w * (0.43f + i * 0.085f)
        val y = h * (0.43f + (i % 2) * 0.04f)

        drawLine(
            color = Color(0xFF704B30),
            start = Offset(x, y + 18.dp.toPx()),
            end = Offset(x, y),
            strokeWidth = 3.dp.toPx()
        )

        drawCircle(
            color = primary.copy(alpha = 0.82f),
            radius = 9.dp.toPx(),
            center = Offset(x, y - 3.dp.toPx())
        )
    }

    // شلال طاقة أسفل الجزيرة
    drawLine(
        color = secondary.copy(alpha = 0.50f),
        start = Offset(w * 0.60f, h * 0.70f),
        end = Offset(w * 0.62f, h * 0.94f),
        strokeWidth = 5.dp.toPx()
    )

    drawLine(
        color = primary.copy(alpha = 0.35f),
        start = Offset(w * 0.68f, h * 0.67f),
        end = Offset(w * 0.72f, h * 0.89f),
        strokeWidth = 3.dp.toPx()
    )
}

private fun sizeWidth(): Float = 1200f
