
package com.system.irtqaa

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.sin

@Composable
fun SystemNestedWorldHub(
    onWorldSelected: (SystemWorldKind) -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedKind by remember {
        mutableStateOf<SystemWorldKind?>(null)
    }

    val activeStyle = selectedKind?.let {
        SystemWorldVisualStyles.forKind(it)
    }

    val top by animateColorAsState(
        activeStyle?.deep ?: Color(0xFF070B12),
        tween(850),
        label = "world-top"
    )

    val bottom by animateColorAsState(
        activeStyle?.surface ?: Color(0xFF101A2A),
        tween(850),
        label = "world-bottom"
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    listOf(top, bottom, Color.Black)
                )
            )
            .padding(horizontal = 9.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(11.dp)
    ) {
        Text(
            "SYSTEM WORLD",
            color = activeStyle?.accent ?: Color(0xFFFFC857),
            fontSize = 25.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            "اختر العالم الذي تريد مشاهدة أجوائه",
            color = Color.White,
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold
        )

        Text(
            "عوالم مختلفة، حياة مختلفة، وتجارب مستقلة.",
            color = Color.LightGray,
            fontSize = 12.sp
        )

        SystemWorldMiyarGuide()

        SystemWorldVisualStyles.all.forEachIndexed { index, style ->
            LivingWorldCard(
                style = style,
                index = index,
                selected = selectedKind == style.kind,
                onClick = {
                    selectedKind = style.kind
                }
            )
        }

        if (selectedKind != null) {
            Button(
                onClick = {
                    selectedKind?.let(onWorldSelected)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(17.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = activeStyle!!.accent,
                    contentColor = Color.Black
                )
            ) {
                Text(
                    "دخول العالم المختار ←",
                    fontWeight = FontWeight.Black,
                    fontSize = 15.sp
                )
            }

            Text(
                "تم اختيار: ${activeStyle?.title}",
                color = activeStyle?.accent ?: Color.White,
                fontSize = 12.sp
            )
        } else {
            Text(
                "اختر أحد العوالم لمعاينة أجوائه.",
                color = Color(0xFF45D6E8),
                fontSize = 12.sp
            )
        }
    }
}

@Composable
private fun LivingWorldCard(
    style: SystemWorldVisualStyle,
    index: Int,
    selected: Boolean,
    onClick: () -> Unit
) {
    val animation = rememberInfiniteTransition(
        label = "world-${style.kind}"
    )

    val movement by animation.animateFloat(
        -13f,
        13f,
        infiniteRepeatable(
            tween(4200 + index * 350),
            RepeatMode.Reverse
        ),
        label = "movement"
    )

    val pulse by animation.animateFloat(
        0.25f,
        0.9f,
        infiniteRepeatable(
            tween(1900 + index * 250),
            RepeatMode.Reverse
        ),
        label = "pulse"
    )

    val rotation by animation.animateFloat(
        0f,
        360f,
        infiniteRepeatable(
            tween(15000 + index * 1000),
            RepeatMode.Restart
        ),
        label = "rotation"
    )

    val borderColor by animateColorAsState(
        if (selected) style.accent
        else style.accent.copy(alpha = 0.48f),
        tween(350),
        label = "border"
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(145.dp)
            .clip(RoundedCornerShape(18.dp))
            .border(
                if (selected) 2.5.dp else 1.dp,
                borderColor,
                RoundedCornerShape(18.dp)
            )
            .clickable(onClick = onClick)
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height

            drawRect(
                Brush.verticalGradient(
                    listOf(
                        style.deep,
                        style.surface,
                        Color.Black
                    )
                )
            )

            when (style.kind) {
                SystemWorldKind.MODERN_REALISTIC ->
                    modernCity(w, h, movement, rotation, pulse)

                SystemWorldKind.MYTHOLOGY_HISTORY ->
                    historicCity(w, h, movement, rotation, pulse)

                SystemWorldKind.FANTASY ->
                    fantasyKingdom(w, h, movement, rotation, pulse)

                SystemWorldKind.GREED_ISLAND ->
                    greedIsland(w, h, movement, rotation, pulse)
            }

            // حركة الإضاءة والجسيمات
            for (i in 0..22) {
                val x = (
                    w * ((i * 37 % 100) / 100f) +
                    movement * (0.15f + (i % 3) * 0.15f)
                ).let { ((it % w) + w) % w }

                val y = h * ((i * 23 % 90) / 100f)

                val alpha = 0.2f + 0.5f *
                    (0.5f + 0.5f * sin(rotation / 35f + i))

                drawCircle(
                    style.accent.copy(alpha = alpha),
                    (1.2f + i % 3).dp.toPx(),
                    Offset(x, y)
                )
            }

            // لمعان متحرك
            val shine = (rotation % 5000f) / 5000f

            drawRect(
                Brush.linearGradient(
                    listOf(
                        Color.Transparent,
                        Color.White.copy(alpha = 0.08f),
                        style.accent.copy(alpha = 0.08f),
                        Color.Transparent
                    ),
                    Offset(w * shine, 0f),
                    Offset(w * shine + w * 0.35f, h)
                )
            )
        }

        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.78f),
                            Color.Black.copy(alpha = 0.35f),
                            Color.Transparent
                        )
                    )
                )
        )

        Column(
            Modifier
                .align(Alignment.CenterStart)
                .padding(start = 14.dp)
                .fillMaxWidth(0.76f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                style.title,
                color = Color.White,
                fontSize = 15.sp,
                fontWeight = FontWeight.Black
            )

            Text(
                style.subtitle,
                color = Color.White,
                fontSize = 10.sp,
                maxLines = 1
            )

            Text(
                if (selected) "✓ تمت معاينة العالم"
                else "اضغط لمعاينة العالم",
                color = style.accent,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold
            )
        }

        if (selected) {
            Text(
                "SELECTED",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .clip(RoundedCornerShape(30.dp))
                    .background(style.accent.copy(alpha = 0.2f))
                    .padding(horizontal = 9.dp, vertical = 5.dp),
                color = style.accent,
                fontSize = 8.sp,
                fontWeight = FontWeight.Black
            )
        }
    }
}

// =====================================================
// 1. MODERN REALISTIC WORLD
// مدينة حديثة، أبراج، شوارع، مطاعم، سيارات وطائرة
// =====================================================

private fun modernCity(
    w: Float,
    h: Float,
    movement: Float,
    rotation: Float,
    pulse: Float
) {
    drawRect(
        Brush.verticalGradient(
            listOf(
                Color(0xFF071D35),
                Color(0xFF16476B),
                Color(0xFF101C2A)
            )
        )
    )

    // أضواء السماء
    drawCircle(
        Color(0xFF42D9E8).copy(alpha = 0.12f),
        h * 0.55f,
        Offset(w * 0.76f, h * 0.35f)
    )

    // طبقات المدينة البعيدة
    for (i in 0..17) {
        val x = w * (i / 17f)
        val buildingHeight = h * (
            0.27f + (i % 6) * 0.075f
        )

        drawRect(
            Color(0xFF17334B),
            Offset(x, h * 0.78f - buildingHeight),
            Size(w * 0.065f, buildingHeight)
        )

        // نوافذ الأبراج
        for (row in 0..5) {
            for (column in 0..1) {
                drawRect(
                    Color(0xFFFFD77A).copy(
                        alpha = 0.35f + pulse * 0.25f
                    ),
                    Offset(
                        x + 3.dp.toPx() + column * 5.dp.toPx(),
                        h * 0.78f - buildingHeight +
                            row * 9.dp.toPx()
                    ),
                    Size(3.dp.toPx(), 4.dp.toPx())
                )
            }
        }
    }

    // أبراج أمامية
    for (i in 0..5) {
        val x = w * (0.05f + i * 0.14f)
        val bh = h * (0.34f + (i % 3) * 0.12f)

        drawRect(
            Color(0xFF0D263C),
            Offset(x, h * 0.82f - bh),
            Size(w * 0.105f, bh)
        )

        for (row in 0..6) {
            drawLine(
                Color(0xFF49D9E9).copy(alpha = 0.6f),
                Offset(x + 5.dp.toPx(), h * 0.82f - bh + row * 8.dp.toPx()),
                Offset(x + w * 0.09f, h * 0.82f - bh + row * 8.dp.toPx()),
                1.dp.toPx()
            )
        }
    }

    // شارع المدينة
    drawRect(
        Color(0xFF101821),
        Offset(0f, h * 0.82f),
        Size(w, h * 0.18f)
    )

    drawLine(
        Color(0xFFFFD56C),
        Offset(0f, h * 0.91f),
        Offset(w, h * 0.91f),
        1.5.dp.toPx()
    )

    // خطوط الطريق
    for (i in 0..5) {
        val x = (w * (i / 5f) + movement * 2f) % w
        drawRect(
            Color.White.copy(alpha = 0.6f),
            Offset(x, h * 0.96f),
            Size(w * 0.07f, 2.dp.toPx())
        )
    }

    // مطاعم ومحلات في مستوى الشارع
    for (i in 0..3) {
        val x = w * (0.04f + i * 0.17f)

        drawRect(
            Color(0xFF263C4B),
            Offset(x, h * 0.66f),
            Size(w * 0.13f, h * 0.16f)
        )

        drawRect(
            Color(0xFFFFB45C).copy(alpha = 0.85f),
            Offset(x, h * 0.66f),
            Size(w * 0.13f, h * 0.035f)
        )

        drawRect(
            Color(0xFF6ADCEB).copy(alpha = 0.75f),
            Offset(x + w * 0.025f, h * 0.71f),
            Size(w * 0.08f, h * 0.075f)
        )
    }

    // سيارات تتحرك
    for (i in 0..3) {
        val x = (
            w * (0.12f + i * 0.24f) + movement * 2.2f
        ).let { ((it % w) + w) % w }

        drawRoundRect(
            Color(0xFF182C40),
            Offset(x, h * (0.86f + (i % 2) * 0.045f)),
            Size(w * 0.075f, h * 0.035f),
            androidx.compose.ui.geometry.CornerRadius(5f)
        )

        drawCircle(
            Color(0xFFFFD16C),
            2.dp.toPx(),
            Offset(x + w * 0.065f, h * (0.875f + (i % 2) * 0.045f))
        )

        drawCircle(
            Color(0xFFFF4E54),
            2.dp.toPx(),
            Offset(x + 3.dp.toPx(), h * (0.875f + (i % 2) * 0.045f))
        )
    }

    // طائرة في السماء
    val planeX = w * 0.38f + movement * 2f
    val planeY = h * 0.20f + sin(rotation / 45f) * 3.dp.toPx()

    drawLine(
        Color.White.copy(alpha = 0.9f),
        Offset(planeX - 15.dp.toPx(), planeY),
        Offset(planeX + 15.dp.toPx(), planeY),
        2.dp.toPx()
    )

    drawLine(
        Color.White,
        Offset(planeX, planeY),
        Offset(planeX - 5.dp.toPx(), planeY - 9.dp.toPx()),
        2.dp.toPx()
    )

    drawLine(
        Color.White,
        Offset(planeX, planeY),
        Offset(planeX + 5.dp.toPx(), planeY + 8.dp.toPx()),
        1.5.dp.toPx()
    )

    // البوابة الزمنية
    val center = Offset(w * 0.79f, h * 0.48f)
    val diameter = h * 0.72f

    drawCircle(
        Color(0xFF35DDF4).copy(alpha = pulse * 0.15f),
        diameter * 0.7f,
        center
    )

    drawArc(
        Color(0xFF48E8FF),
        rotation,
        285f,
        false,
        Offset(center.x - diameter / 2, center.y - diameter / 2),
        Size(diameter, diameter),
        style = androidx.compose.ui.graphics.drawscope.Stroke(3.dp.toPx())
    )

    drawCircle(
        Brush.radialGradient(
            listOf(
                Color.White.copy(alpha = pulse),
                Color(0xFF21BEEB).copy(alpha = 0.5f),
                Color.Transparent
            ),
            center,
            diameter * 0.35f
        ),
        diameter * 0.35f,
        center
    )
}

// =====================================================
// 2. HISTORICAL WORLD
// الحضارات والأسواق والمعابد والبوابة الأثرية
// =====================================================

private fun historicCity(
    w: Float,
    h: Float,
    movement: Float,
    rotation: Float,
    pulse: Float
) {
    drawRect(
        Brush.verticalGradient(
            listOf(
                Color(0xFF382217),
                Color(0xFF9A6034),
                Color(0xFF24170F)
            )
        )
    )

    // الشمس
    drawCircle(
        Color(0xFFFFD58B).copy(alpha = 0.65f),
        h * 0.19f,
        Offset(w * 0.77f, h * 0.24f)
    )

    // مبانٍ تاريخية
    for (i in 0..6) {
        val x = w * (0.03f + i * 0.13f)
        val bh = h * (0.28f + (i % 3) * 0.12f)

        drawRect(
            Color(0xFF795034),
            Offset(x, h * 0.83f - bh),
            Size(w * 0.105f, bh)
        )

        drawRect(
            Color(0xFFC08B50),
            Offset(x - 2.dp.toPx(), h * 0.83f - bh),
            Size(w * 0.11f, 5.dp.toPx())
        )

        drawRect(
            Color(0xFF352319),
            Offset(x + w * 0.035f, h * 0.72f),
            Size(w * 0.03f, h * 0.11f)
        )
    }

    // معبد بأعمدة
    for (i in 0..4) {
        val x = w * (0.48f + i * 0.045f)

        drawRect(
            Color(0xFFE2B878),
            Offset(x, h * 0.43f),
            Size(w * 0.025f, h * 0.40f)
        )

        drawRect(
            Color(0xFFFFD99B),
            Offset(x - 3.dp.toPx(), h * 0.42f),
            Size(w * 0.035f, 4.dp.toPx())
        )
    }

    // هرم بعيد
    val pyramid = Path().apply {
        moveTo(w * 0.10f, h * 0.83f)
        lineTo(w * 0.25f, h * 0.36f)
        lineTo(w * 0.42f, h * 0.83f)
        close()
    }

    drawPath(pyramid, Color(0xFFC9975D))

    // بوابة أثرية
    val center = Offset(w * 0.78f, h * 0.53f)
    val diameter = h * 0.68f

    drawArc(
        Color(0xFFFFD17A),
        rotation,
        300f,
        false,
        Offset(center.x - diameter / 2, center.y - diameter / 2),
        Size(diameter, diameter),
        style = androidx.compose.ui.graphics.drawscope.Stroke(4.dp.toPx())
    )

    drawCircle(
        Color(0xFFFFC66C).copy(alpha = pulse * 0.3f),
        diameter * 0.35f,
        center
    )

    // غبار ذهبي
    for (i in 0..12) {
        drawCircle(
            Color(0xFFFFD38A).copy(alpha = 0.35f + pulse * 0.3f),
            1.5.dp.toPx(),
            Offset(
                w * (i / 13f) + movement,
                h * (0.2f + (i % 4) * 0.13f)
            )
        )
    }
}

// =====================================================
// 3. FANTASY WORLD
// جبال وقلعة وتنين أزرق وسحر
// =====================================================

private fun fantasyKingdom(
    w: Float,
    h: Float,
    movement: Float,
    rotation: Float,
    pulse: Float
) {
    drawRect(
        Brush.verticalGradient(
            listOf(
                Color(0xFF174E91),
                Color(0xFF4C91D0),
                Color(0xFF171B3A)
            )
        )
    )

    // الجبال
    val mountains = Path().apply {
        moveTo(0f, h * 0.88f)
        lineTo(w * 0.18f, h * 0.32f)
        lineTo(w * 0.39f, h * 0.85f)
        lineTo(w * 0.60f, h * 0.22f)
        lineTo(w * 0.83f, h * 0.85f)
        lineTo(w, h * 0.43f)
        lineTo(w, h)
        lineTo(0f, h)
        close()
    }

    drawPath(mountains, Color(0xFF263D6B))

    // قمم ثلجية
    drawLine(
        Color.White.copy(alpha = 0.7f),
        Offset(w * 0.60f, h * 0.22f),
        Offset(w * 0.55f, h * 0.37f),
        3.dp.toPx()
    )

    // القلعة
    drawRect(
        Color(0xFF27385F),
        Offset(w * 0.40f, h * 0.45f),
        Size(w * 0.25f, h * 0.39f)
    )

    for (i in 0..3) {
        val x = w * (0.40f + i * 0.075f)

        drawRect(
            Color(0xFF354E7A),
            Offset(x, h * 0.36f),
            Size(w * 0.055f, h * 0.48f)
        )

        val tower = Path().apply {
            moveTo(x - 2.dp.toPx(), h * 0.36f)
            lineTo(x + w * 0.027f, h * 0.23f)
            lineTo(x + w * 0.057f, h * 0.36f)
            close()
        }

        drawPath(tower, Color(0xFF9D9AD6))
    }

    // التنين
    val dragonX = w * 0.76f + movement * 1.3f
    val dragonY = h * 0.27f + sin(rotation / 35f) * 5.dp.toPx()

    drawOval(
        Color(0xFF42C7F3),
        Offset(dragonX - 18.dp.toPx(), dragonY - 6.dp.toPx()),
        Size(38.dp.toPx(), 14.dp.toPx())
    )

    // جناحان
    val wingMotion = sin(rotation / 18f) * 12.dp.toPx()

    val wingLeft = Path().apply {
        moveTo(dragonX - 4.dp.toPx(), dragonY)
        quadraticTo(
            dragonX - 18.dp.toPx(),
            dragonY - 35.dp.toPx() - wingMotion,
            dragonX - 38.dp.toPx(),
            dragonY - 22.dp.toPx()
        )
        lineTo(dragonX - 18.dp.toPx(), dragonY + 7.dp.toPx())
        close()
    }

    drawPath(wingLeft, Color(0xFF8AE7FF))

    val wingRight = Path().apply {
        moveTo(dragonX + 3.dp.toPx(), dragonY)
        quadraticTo(
            dragonX + 18.dp.toPx(),
            dragonY - 35.dp.toPx() + wingMotion,
            dragonX + 39.dp.toPx(),
            dragonY - 20.dp.toPx()
        )
        lineTo(dragonX + 18.dp.toPx(), dragonY + 7.dp.toPx())
        close()
    }

    drawPath(wingRight, Color(0xFF368CCB))

    // الذيل
    drawLine(
        Color(0xFF42C7F3),
        Offset(dragonX - 17.dp.toPx(), dragonY),
        Offset(dragonX - 37.dp.toPx(), dragonY + 12.dp.toPx()),
        3.dp.toPx()
    )

    // وهج سحري
    drawCircle(
        Color(0xFFB69BFF).copy(alpha = pulse * 0.3f),
        30.dp.toPx(),
        Offset(dragonX, dragonY)
    )
}

// =====================================================
// 4. GREED ISLAND
// جزيرة عائمة، بحر، أمواج، شلالات، جبال وقصور
// =====================================================

private fun greedIsland(
    w: Float,
    h: Float,
    movement: Float,
    rotation: Float,
    pulse: Float
) {
    drawRect(
        Brush.verticalGradient(
            listOf(
                Color(0xFF06192A),
                Color(0xFF14546A),
                Color(0xFF07141E)
            )
        )
    )

    // الجبال البعيدة
    val mountains = Path().apply {
        moveTo(0f, h * 0.70f)
        lineTo(w * 0.16f, h * 0.31f)
        lineTo(w * 0.31f, h * 0.70f)
        lineTo(w * 0.48f, h * 0.24f)
        lineTo(w * 0.70f, h * 0.70f)
        lineTo(w * 0.88f, h * 0.35f)
        lineTo(w, h * 0.68f)
        lineTo(w, h)
        lineTo(0f, h)
        close()
    }

    drawPath(mountains, Color(0xFF1A4651))

    // البحر أسفل الجزيرة
    drawRect(
        Brush.verticalGradient(
            listOf(
                Color(0xFF145B78),
                Color(0xFF06283D),
                Color(0xFF03121F)
            )
        ),
        Offset(0f, h * 0.68f),
        Size(w, h * 0.32f)
    )

    // أمواج البحر المتحركة
    for (i in 0..6) {
        val y = h * (0.73f + i * 0.04f)
        val wave = Path().apply {
            moveTo(0f, y)
            cubicTo(
                w * 0.25f, y - 5.dp.toPx() - movement * 0.08f,
                w * 0.50f, y + 5.dp.toPx(),
                w * 0.75f, y - 4.dp.toPx()
            )
            cubicTo(
                w * 0.85f, y - 6.dp.toPx(),
                w * 0.94f, y + 4.dp.toPx(),
                w, y
            )
        }

        drawPath(
            wave,
            Color(0xFF7BE8E6).copy(alpha = 0.35f + pulse * 0.2f),
            style = androidx.compose.ui.graphics.drawscope.Stroke(1.2.dp.toPx())
        )
    }

    // الجزيرة العائمة
    val island = Path().apply {
        moveTo(w * 0.24f + movement * 0.12f, h * 0.43f)
        cubicTo(
            w * 0.34f, h * 0.25f,
            w * 0.70f, h * 0.24f,
            w * 0.83f + movement * 0.12f, h * 0.44f
        )
        lineTo(w * 0.75f, h * 0.60f)
        lineTo(w * 0.61f, h * 0.76f)
        lineTo(w * 0.48f, h * 0.65f)
        lineTo(w * 0.34f, h * 0.58f)
        close()
    }

    drawPath(
        island,
        Brush.verticalGradient(
            listOf(
                Color(0xFF5C986C),
                Color(0xFF245A43),
                Color(0xFF142C2A)
            )
        )
    )

    // قمة جبل وسط الجزيرة
    val peak = Path().apply {
        moveTo(w * 0.39f, h * 0.47f)
        lineTo(w * 0.53f, h * 0.20f)
        lineTo(w * 0.68f, h * 0.47f)
        close()
    }

    drawPath(peak, Color(0xFF547B76))

    // القصور
    drawRect(
        Color(0xFF9C8A6C),
        Offset(w * 0.52f, h * 0.36f),
        Size(w * 0.19f, h * 0.15f)
    )

    for (i in 0..2) {
        val x = w * (0.53f + i * 0.065f)

        drawRect(
            Color(0xFFC5A879),
            Offset(x, h * 0.27f),
            Size(w * 0.045f, h * 0.24f)
        )

        val roof = Path().apply {
            moveTo(x - 2.dp.toPx(), h * 0.27f)
            lineTo(x + w * 0.022f, h * 0.20f)
            lineTo(x + w * 0.047f, h * 0.27f)
            close()
        }

        drawPath(roof, Color(0xFFE0BD82))
    }

    // أشجار
    for (i in 0..5) {
        val x = w * (0.28f + i * 0.085f) + movement * 0.1f
        val y = h * (0.43f + (i % 2) * 0.045f)

        drawLine(
            Color(0xFF503C2C),
            Offset(x, y + 16.dp.toPx()),
            Offset(x, y),
            2.5.dp.toPx()
        )

        drawCircle(
            Color(0xFF39875A),
            8.dp.toPx(),
            Offset(x, y - 5.dp.toPx())
        )
    }

    // شلالات نازلة من الجزيرة
    for (i in 0..2) {
        val x = w * (0.37f + i * 0.16f)

        drawLine(
            Color(0xFF8BE9F3).copy(alpha = 0.75f),
            Offset(x, h * 0.57f),
            Offset(x - movement * 0.08f, h * 0.81f),
            3.dp.toPx()
        )

        drawLine(
            Color.White.copy(alpha = 0.55f),
            Offset(x + 4.dp.toPx(), h * 0.59f),
            Offset(x + 3.dp.toPx(), h * 0.77f),
            1.dp.toPx()
        )
    }

    // ضباب وسحب حول الجزيرة
    for (i in 0..5) {
        drawCircle(
            Color.White.copy(alpha = 0.07f + pulse * 0.05f),
            h * 0.13f,
            Offset(
                w * (0.15f + i * 0.14f) + movement,
                h * (0.60f + (i % 2) * 0.12f)
            )
        )
    }

    // ضوء غامض فوق القصور
    drawCircle(
        Color(0xFF65E6A6).copy(alpha = pulse * 0.25f),
        h * 0.28f,
        Offset(w * 0.62f, h * 0.34f)
    )

    // رمز SYSTEM المضيء
    drawArc(
        Color(0xFF65E6A6).copy(alpha = 0.55f),
        rotation,
        220f,
        false,
        Offset(w * 0.58f, h * 0.31f),
        Size(h * 0.16f, h * 0.16f),
        style = androidx.compose.ui.graphics.drawscope.Stroke(2.dp.toPx())
    )
}
