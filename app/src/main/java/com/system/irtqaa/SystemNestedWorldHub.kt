
package com.system.irtqaa

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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

    val backgroundTop by animateColorAsState(
        targetValue = activeStyle?.deep ?: Color(0xFF070B12),
        animationSpec = tween(850),
        label = "world-background-top"
    )

    val backgroundBottom by animateColorAsState(
        targetValue = activeStyle?.surface ?: Color(0xFF101A2A),
        animationSpec = tween(850),
        label = "world-background-bottom"
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    listOf(
                        backgroundTop,
                        backgroundBottom,
                        Color(0xFF05070D)
                    )
                )
            )
            .padding(horizontal = 9.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
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
            "اضغط على أحد المشاهد لتغيير خلفية شاشة العوالم.",
            color = Color.LightGray,
            fontSize = 12.sp
        )

        SystemWorldMiyarGuide()

        Spacer(Modifier.height(2.dp))

        SystemWorldVisualStyles.all.forEachIndexed { index, style ->
            SystemLivingWorldCard(
                style = style,
                index = index,
                selected = selectedKind == style.kind,
                onClick = {
                    // اختيار معاينة فقط، لا يدخل اللاعب إلى العالم
                    selectedKind = style.kind
                }
            )
        }

        if (selectedKind != null) {
            Button(
                onClick = {
                    // الدخول يحدث فقط بعد ضغط الزر المنفصل
                    selectedKind?.let(onWorldSelected)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(17.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = activeStyle?.accent
                        ?: Color(0xFFFFC857),
                    contentColor = Color(0xFF07101B)
                )
            ) {
                Text(
                    "دخول العالم المختار  ←",
                    fontWeight = FontWeight.Black,
                    fontSize = 15.sp
                )
            }

            Text(
                "تم اختيار: ${activeStyle?.title ?: ""}",
                color = activeStyle?.accent ?: Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        } else {
            Text(
                "اختر أحد العوالم الأربعة لمعاينة خلفيته.",
                color = Color(0xFF45D6E8),
                fontSize = 12.sp
            )
        }

        Spacer(Modifier.height(12.dp))
    }
}

@Composable
private fun SystemLivingWorldCard(
    style: SystemWorldVisualStyle,
    index: Int,
    selected: Boolean,
    onClick: () -> Unit
) {
    val transition = rememberInfiniteTransition(
        label = "living-world-${style.kind}"
    )

    val drift by transition.animateFloat(
        initialValue = -12f,
        targetValue = 12f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 3600 + index * 500
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scene-drift"
    )

    val pulse by transition.animateFloat(
        initialValue = 0.25f,
        targetValue = 0.9f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 1800 + index * 250
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scene-pulse"
    )

    val rotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = 14000 + index * 1000
            ),
            repeatMode = RepeatMode.Restart
        ),
        label = "scene-rotation"
    )

    val borderColor by animateColorAsState(
        targetValue = if (selected) {
            style.accent
        } else {
            style.accent.copy(alpha = 0.48f)
        },
        animationSpec = tween(400),
        label = "world-border"
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(112.dp)
            .clip(RoundedCornerShape(19.dp))
            .border(
                width = if (selected) 2.5.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(19.dp)
            )
            .clickable(onClick = onClick)
    ) {
        Canvas(
            modifier = Modifier.fillMaxSize()
        ) {
            val w = size.width
            val h = size.height

            drawRect(
                brush = Brush.verticalGradient(
                    listOf(
                        style.deep,
                        style.surface,
                        Color.Black
                    )
                )
            )

            // ضوء البيئة المتغير
            val lightCenter = Offset(
                w * 0.75f + drift,
                h * 0.36f
            )

            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        style.accent.copy(alpha = pulse * 0.55f),
                        style.secondary.copy(alpha = 0.18f),
                        Color.Transparent
                    ),
                    center = lightCenter,
                    radius = h * 1.1f
                ),
                radius = h * 1.1f,
                center = lightCenter
            )

            when (style.kind) {
                SystemWorldKind.MODERN_REALISTIC -> {
                    drawModernLivingScene(
                        w, h, style, drift, rotation, pulse
                    )
                }

                SystemWorldKind.MYTHOLOGY_HISTORY -> {
                    drawHistoricalLivingScene(
                        w, h, style, drift, rotation, pulse
                    )
                }

                SystemWorldKind.FANTASY -> {
                    drawFantasyLivingScene(
                        w, h, style, drift, rotation, pulse
                    )
                }

                SystemWorldKind.GREED_ISLAND -> {
                    drawGreedLivingScene(
                        w, h, style, drift, rotation, pulse
                    )
                }
            }

            // جسيمات ضوئية متحركة
            for (i in 0..21) {
                val x = (
                    w * ((i * 37 % 100) / 100f) +
                    drift * ((i % 3 + 1) * 0.18f)
                ).let { ((it % w) + w) % w }

                val y = h * ((i * 23 % 85) / 100f)

                val alpha = (
                    0.2f +
                    0.5f * (0.5f + 0.5f * sin(
                        rotation / 35f + i
                    ))
                )

                drawCircle(
                    color = style.accent.copy(alpha = alpha),
                    radius = (1.2f + i % 3).dp.toPx(),
                    center = Offset(x, y)
                )
            }

            // لمعان متحرك على المشهد
            drawRect(
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color.Transparent,
                        Color.White.copy(alpha = 0.09f),
                        style.accent.copy(alpha = 0.10f),
                        Color.Transparent
                    ),
                    start = Offset(w * ((rotation % 5000f) / 5000f), 0f),
                    end = Offset(
                        w * ((rotation % 5000f) / 5000f) + w * 0.35f,
                        h
                    )
                )
            )
        }

        // تدرج يساعد على وضوح العنوان
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.78f),
                            Color.Black.copy(alpha = 0.34f),
                            Color.Transparent
                        )
                    )
                )
        )

        Column(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .padding(start = 14.dp, end = 8.dp)
                .fillMaxWidth(0.73f),
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
                color = Color.White.copy(alpha = 0.9f),
                fontSize = 10.sp,
                maxLines = 1
            )

            Text(
                if (selected) "✓ تمت معاينة هذا العالم"
                else "اضغط لمعاينة الخلفية",
                color = style.accent,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold
            )
        }

        if (selected) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .clip(RoundedCornerShape(50))
                    .background(style.accent.copy(alpha = 0.2f))
                    .padding(
                        horizontal = 9.dp,
                        vertical = 5.dp
                    )
            ) {
                Text(
                    "SELECTED",
                    color = style.accent,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Black
                )
            }
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawModernLivingScene(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    drift: Float,
    rotation: Float,
    pulse: Float
) {
    val ground = h * 0.91f

    // أفق المدينة وأبراجها
    for (i in 0..11) {
        val x = w * (i / 12f)
        val buildingHeight = h * (
            0.25f + (i % 5) * 0.105f
        )

        drawRect(
            color = style.secondary.copy(alpha = 0.78f),
            topLeft = Offset(x, ground - buildingHeight),
            size = Size(
                w * 0.075f,
                buildingHeight
            )
        )

        for (row in 0..3) {
            drawRect(
                color = style.accent.copy(alpha = 0.75f),
                topLeft = Offset(
                    x + w * 0.025f,
                    ground - buildingHeight + row * 8.dp.toPx()
                ),
                size = Size(
                    3.dp.toPx(),
                    4.dp.toPx()
                )
            )
        }
    }

    // بوابة زمنية دائرية في وسط المشهد
    val center = Offset(
        w * 0.72f + drift * 0.25f,
        h * 0.43f
    )

    val diameter = h * 0.78f

    drawCircle(
        color = style.accent.copy(alpha = 0.14f),
        radius = diameter * 0.57f,
        center = center
    )

    drawArc(
        color = style.accent.copy(alpha = 0.95f),
        startAngle = rotation,
        sweepAngle = 285f,
        useCenter = false,
        topLeft = Offset(
            center.x - diameter / 2f,
            center.y - diameter / 2f
        ),
        size = Size(diameter, diameter),
        style = androidx.compose.ui.graphics.drawscope.Stroke(
            width = 3.dp.toPx()
        )
    )

    drawArc(
        color = Color.White.copy(alpha = pulse * 0.8f),
        startAngle = -rotation * 0.8f,
        sweepAngle = 190f,
        useCenter = false,
        topLeft = Offset(
            center.x - diameter * 0.38f,
            center.y - diameter * 0.38f
        ),
        size = Size(
            diameter * 0.76f,
            diameter * 0.76f
        ),
        style = androidx.compose.ui.graphics.drawscope.Stroke(
            width = 1.5.dp.toPx()
        )
    )

    drawCircle(
        brush = Brush.radialGradient(
            listOf(
                Color.White.copy(alpha = pulse * 0.75f),
                style.accent.copy(alpha = 0.45f),
                Color.Transparent
            ),
            center = center,
            radius = diameter * 0.34f
        ),
        radius = diameter * 0.34f,
        center = center
    )

    // حركة أضواء الشارع
    for (i in 0..5) {
        val x = w * (i / 5f) + drift * (i % 2 + 1)
        drawCircle(
            style.accent.copy(alpha = 0.8f),
            2.dp.toPx(),
            Offset(x, h * 0.89f)
        )
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawHistoricalLivingScene(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    drift: Float,
    rotation: Float,
    pulse: Float
) {
    val ground = h * 0.91f

    // مبانٍ ومعابد قديمة
    for (i in 0..4) {
        val x = w * (0.06f + i * 0.10f)

        drawRect(
            color = style.secondary.copy(alpha = 0.85f),
            topLeft = Offset(x, h * 0.43f),
            size = Size(
                w * 0.035f,
                h * 0.48f
            )
        )

        drawLine(
            color = style.accent.copy(alpha = 0.8f),
            start = Offset(x - 3.dp.toPx(), h * 0.43f),
            end = Offset(x + 10.dp.toPx(), h * 0.43f),
            strokeWidth = 3.dp.toPx()
        )
    }

    // هرم بعيد
    val pyramid = Path().apply {
        moveTo(w * 0.48f, ground)
        lineTo(w * 0.60f, h * 0.40f)
        lineTo(w * 0.73f, ground)
        close()
    }

    drawPath(
        pyramid,
        color = style.accent.copy(alpha = 0.42f)
    )

    // بوابة زمنية أثرية
    val center = Offset(
        w * 0.79f + drift * 0.18f,
        h * 0.48f
    )

    val diameter = h * 0.72f

    drawCircle(
        color = style.accent.copy(alpha = 0.13f),
        radius = diameter * 0.65f,
        center = center
    )

    drawArc(
        color = style.accent.copy(alpha = 0.95f),
        startAngle = rotation,
        sweepAngle = 300f,
        useCenter = false,
        topLeft = Offset(
            center.x - diameter / 2f,
            center.y - diameter / 2f
        ),
        size = Size(diameter, diameter),
        style = androidx.compose.ui.graphics.drawscope.Stroke(
            width = 4.dp.toPx()
        )
    )

    drawArc(
        color = Color.White.copy(alpha = pulse * 0.65f),
        startAngle = -rotation,
        sweepAngle = 145f,
        useCenter = false,
        topLeft = Offset(
            center.x - diameter * 0.35f,
            center.y - diameter * 0.35f
        ),
        size = Size(
            diameter * 0.70f,
            diameter * 0.70f
        ),
        style = androidx.compose.ui.graphics.drawscope.Stroke(
            width = 2.dp.toPx()
        )
    )

    drawCircle(
        color = style.secondary.copy(alpha = 0.45f),
        radius = diameter * 0.25f,
        center = center
    )

    // غبار ذهبي متحرك
    for (i in 0..8) {
        drawCircle(
            style.accent.copy(alpha = 0.3f + pulse * 0.35f),
            (1 + i % 2).dp.toPx(),
            Offset(
                w * (i / 9f) + drift * 0.2f,
                h * (0.24f + (i % 3) * 0.12f)
            )
        )
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFantasyLivingScene(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    drift: Float,
    rotation: Float,
    pulse: Float
) {
    // سماء زرقاء وسحب مضيئة
    drawRect(
        brush = Brush.verticalGradient(
            listOf(
                Color(0xFF153E75),
                Color(0xFF377FC2),
                style.deep
            )
        )
    )

    for (i in 0..3) {
        val cloudX = w * (0.15f + i * 0.25f) + drift * (i % 2 + 1)

        drawCircle(
            color = Color.White.copy(alpha = 0.12f),
            radius = h * 0.13f,
            center = Offset(cloudX, h * (0.20f + (i % 2) * 0.15f)
            )
        )
    }

    // جبال بعيدة
    val mountains = Path().apply {
        moveTo(0f, h * 0.91f)
        lineTo(w * 0.20f, h * 0.37f)
        lineTo(w * 0.39f, h * 0.87f)
        lineTo(w * 0.58f, h * 0.30f)
        lineTo(w * 0.82f, h * 0.89f)
        lineTo(w, h * 0.55f)
        lineTo(w, h)
        lineTo(0f, h)
        close()
    }

    drawPath(
        mountains,
        color = style.secondary.copy(alpha = 0.82f)
    )

    // قلعة خيالية
    for (i in 0..2) {
        val x = w * (0.43f + i * 0.055f)

        drawRect(
            color = Color(0xFF263C6A),
            topLeft = Offset(x, h * 0.43f),
            size = Size(w * 0.045f, h * 0.38f)
        )

        val tower = Path().apply {
            moveTo(x - 2.dp.toPx(), h * 0.43f)
            lineTo(x + w * 0.022f, h * 0.25f)
            lineTo(x + w * 0.047f, h * 0.43f)
            close()
        }

        drawPath(tower, style.accent.copy(alpha = 0.85f))
    }

    // تنين أزرق طائر
    val dragonX = w * 0.69f + drift * 1.4f
    val dragonY = h * 0.32f + sin(rotation / 35f) * 5.dp.toPx()

    val body = Path().apply {
        moveTo(dragonX - 18.dp.toPx(), dragonY)
        cubicTo(
            dragonX - 5.dp.toPx(),
            dragonY - 10.dp.toPx(),
            dragonX + 12.dp.toPx(),
            dragonY - 5.dp.toPx(),
            dragonX + 19.dp.toPx(),
            dragonY
        )
        cubicTo(
            dragonX + 5.dp.toPx(),
            dragonY + 9.dp.toPx(),
            dragonX - 8.dp.toPx(),
            dragonY + 8.dp.toPx(),
            dragonX - 18.dp.toPx(),
            dragonY
        )
        close()
    }

    drawPath(
        body,
        color = Color(0xFF42BDEB)
    )

    // الجناح الأول
    val wingOne = Path().apply {
        moveTo(dragonX - 3.dp.toPx(), dragonY)
        quadraticTo(
            dragonX - 17.dp.toPx(),
            dragonY - 32.dp.toPx(),
            dragonX - 34.dp.toPx(),
            dragonY - 24.dp.toPx()
        )
        lineTo(dragonX - 19.dp.toPx(), dragonY + 5.dp.toPx())
        close()
    }

    drawPath(
        wingOne,
        color = Color(0xFF75D7F4).copy(alpha = 0.9f)
    )

    // الجناح الثاني
    val wingTwo = Path().apply {
        moveTo(dragonX + 1.dp.toPx(), dragonY)
        quadraticTo(
            dragonX + 17.dp.toPx(),
            dragonY - 31.dp.toPx(),
            dragonX + 34.dp.toPx(),
            dragonY - 20.dp.toPx()
        )
        lineTo(dragonX + 18.dp.toPx(), dragonY + 5.dp.toPx())
        close()
    }

    drawPath(
        wingTwo,
        color = Color(0xFF368CCB)
    )

    // ذيل التنين
    drawLine(
        color = Color(0xFF42BDEB),
        start = Offset(
            dragonX - 17.dp.toPx(),
            dragonY
        ),
        end = Offset(
            dragonX - 35.dp.toPx(),
            dragonY + 8.dp.toPx()
        ),
        strokeWidth = 3.dp.toPx()
    )

    // وهج سحري خلف التنين
    drawCircle(
        color = style.accent.copy(alpha = pulse * 0.22f),
        radius = 24.dp.toPx(),
        center = Offset(dragonX, dragonY)
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawGreedLivingScene(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    drift: Float,
    rotation: Float,
    pulse: Float
) {
    // سماء الجزيرة المظلمة
    drawRect(
        brush = Brush.verticalGradient(
            listOf(
                Color(0xFF03070C),
                Color(0xFF102B2B),
                Color(0xFF050A10)
            )
        )
    )

    // هالة غامضة
    val center = Offset(
        w * 0.67f + drift * 0.2f,
        h * 0.43f
    )

    drawCircle(
        brush = Brush.radialGradient(
            listOf(
                style.accent.copy(alpha = pulse * 0.25f),
                style.secondary.copy(alpha = 0.10f),
                Color.Transparent
            ),
            center = center,
            radius = h * 1.0f
        ),
        radius = h * 1.0f,
        center = center
    )

    // الجزيرة الطافية
    val island = Path().apply {
        moveTo(w * 0.34f + drift * 0.2f, h * 0.43f)
        cubicTo(
            w * 0.48f + drift * 0.2f,
            h * 0.26f,
            w * 0.76f + drift * 0.2f,
            h * 0.28f,
            w * 0.88f + drift * 0.2f,
            h * 0.45f
        )
        lineTo(w * 0.76f + drift * 0.2f, h * 0.62f)
        lineTo(w * 0.62f, h * 0.91f)
        lineTo(w * 0.49f, h * 0.64f)
        close()
    }

    drawPath(
        island,
        brush = Brush.verticalGradient(
            listOf(
                Color(0xFF376C55),
                Color(0xFF183B32),
                Color(0xFF171E1C)
            )
        )
    )

    // أشجار صغيرة فوق الجزيرة
    for (i in 0..4) {
        val x = w * (0.43f + i * 0.085f) + drift * 0.2f
        val y = h * (0.40f + (i % 2) * 0.05f)

        drawLine(
            color = Color(0xFF513E2C),
            start = Offset(x, y + 15.dp.toPx()),
            end = Offset(x, y),
            strokeWidth = 2.dp.toPx()
        )

        drawCircle(
            color = Color(0xFF3E8061),
            radius = 7.dp.toPx(),
            center = Offset(x, y - 4.dp.toPx())
        )
    }

    // ضباب متحرك أسفل الجزيرة
    for (i in 0..4) {
        drawCircle(
            color = Color.White.copy(alpha = 0.06f + pulse * 0.04f),
            radius = h * 0.14f,
            center = Offset(
                w * (0.40f + i * 0.13f) + drift,
                h * 0.80f
            )
        )
    }

    // رمز S خافت داخل الجزيرة
    drawArc(
        color = style.accent.copy(alpha = 0.24f),
        startAngle = rotation,
        sweepAngle = 220f,
        useCenter = false,
        topLeft = Offset(
            w * 0.62f,
            h * 0.39f
        ),
        size = Size(
            h * 0.20f,
            h * 0.20f
        ),
        style = androidx.compose.ui.graphics.drawscope.Stroke(
            width = 2.dp.toPx()
        )
    )
}
