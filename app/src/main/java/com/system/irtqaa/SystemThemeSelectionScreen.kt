
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
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
        verticalArrangement = Arrangement.spacedBy(16.dp)
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
            "اختر هوية عالمك",
            color = Color.White,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold
        )

        Text(
            "أربعة عوالم، أربعة أجواء بصرية مستقلة.",
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
        label = "dimension-${theme.id}"
    )

    val rotation by transition.animateFloat(
        initialValue = -1.8f,
        targetValue = 1.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(3200),
            repeatMode = RepeatMode.Reverse
        ),
        label = "dimension-rotation"
    )

    val light by transition.animateFloat(
        initialValue = 0.10f,
        targetValue = 0.32f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400),
            repeatMode = RepeatMode.Reverse
        ),
        label = "dimension-light"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(190.dp)
            .graphicsLayer {
                rotationY = rotation
                cameraDistance = 18f * density
            }
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = background
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (selected) 14.dp else 7.dp
        )
    ) {
        Box(
            modifier = Modifier.fillMaxSize()
        ) {
            Canvas(
                modifier = Modifier.fillMaxSize()
            ) {
                val w = size.width
                val h = size.height

                drawRect(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            background,
                            secondary.copy(alpha = 0.65f),
                            background
                        ),
                        start = Offset(0f, 0f),
                        end = Offset(w, h)
                    )
                )

                val center = Offset(
                    x = w * 0.78f,
                    y = h * 0.45f
                )

                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(
                            primary.copy(alpha = light),
                            secondary.copy(alpha = 0.12f),
                            Color.Transparent
                        ),
                        center = center,
                        radius = h * 0.85f
                    ),
                    radius = h * 0.85f,
                    center = center
                )

                drawCircle(
                    color = accent.copy(alpha = 0.35f),
                    radius = h * 0.19f,
                    center = center
                )

                drawCircle(
                    color = primary.copy(alpha = 0.5f),
                    radius = h * 0.24f,
                    center = center,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(
                        width = 2.dp.toPx()
                    )
                )

                for (i in 0..8) {
                    val x = w * (0.55f + i * 0.045f)
                    val y = h * (0.16f + (i % 4) * 0.19f)

                    drawCircle(
                        color = accent.copy(alpha = 0.35f),
                        radius = (2 + i % 3).dp.toPx(),
                        center = Offset(x, y)
                    )
                }
            }

            Column(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .padding(18.dp)
                    .fillMaxWidth(0.72f)
            ) {
                Text(
                    theme.name,
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Black
                )

                Spacer(Modifier.height(7.dp))

                Text(
                    theme.description,
                    color = Color.LightGray,
                    fontSize = 12.sp
                )

                Spacer(Modifier.height(16.dp))

                Text(
                    if (selected) "✓ الثيم الحالي"
                    else "اضغط لاختيار هذا العالم",
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
                        .background(accent.copy(alpha = 0.18f))
                        .padding(
                            horizontal = 12.dp,
                            vertical = 6.dp
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
