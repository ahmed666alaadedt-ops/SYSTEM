package com.system.irtqaa

import android.speech.tts.TextToSpeech
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInHorizontally
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
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.graphicsLayer
import kotlinx.coroutines.delay
import java.util.Locale
import kotlin.math.sin

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
        "العالم الحديث الواقعي",
        "مدن حقيقية وحياة معاصرة",
        Color(0xFF42D9E8),
        Color(0xFF4388B8),
        Color(0xFF071B2B),
        Color(0xFF102B3C)
    )

    val mythology = SystemWorldVisualStyle(
        SystemWorldKind.MYTHOLOGY_HISTORY,
        "عالم الحضارات التاريخية",
        "سومر وبابل ومصر واليونان والصين القديمة",
        Color(0xFFE6B65C),
        Color(0xFFB96E3E),
        Color(0xFF28170F),
        Color(0xFF42291C)
    )

    val fantasy = SystemWorldVisualStyle(
        SystemWorldKind.FANTASY,
        "عالم الأساطير والفانتازيا",
        "تنانين وسحر وممالك ومخلوقات أسطورية",
        Color(0xFFB69BFF),
        Color(0xFF5B72D6),
        Color(0xFF17132F),
        Color(0xFF29234B)
    )

    val greedIsland = SystemWorldVisualStyle(
        SystemWorldKind.GREED_ISLAND,
        "جزيرة الطمع",
        "جزيرة عائمة وأسرار ومواسم وتحديات",
        Color(0xFF65E6A6),
        Color(0xFF36AFC0),
        Color(0xFF08251F),
        Color(0xFF123C35)
    )

    val all = listOf(
        modern,
        mythology,
        fantasy,
        greedIsland
    )

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
    var selectedKind by remember {
        mutableStateOf<SystemWorldKind?>(null)
    }

    var visibleCardCount by remember {
        mutableIntStateOf(0)
    }

    LaunchedEffect(Unit) {
        for (index in 1..SystemWorldVisualStyles.all.size) {
            delay(180)
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

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(SystemMobileVisualTheme.background)
            .padding(vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(15.dp)
    ) {
        Text(
            "SYSTEM WORLD",
            color = SystemMobileVisualTheme.gold,
            fontSize = 25.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            "اختر بوابتك وابدأ رحلتك بين العوالم الأربعة",
            color = SystemMobileVisualTheme.textSecondary,
            fontSize = 14.sp
        )

        SystemWorldMiyarGuide()

        SystemWorldVisualStyles.all.forEachIndexed { index, style ->
            AnimatedVisibility(
                visible = visibleCardCount > index,
                enter = fadeIn(tween(650)) +
                    slideInHorizontally(
                        initialOffsetX = { it / 3 },
                        animationSpec = tween(650)
                    )
            ) {
                SystemWorldThemeCard(
                    style = style,
                    selected = selectedKind == style.kind,
                    enabled = selectedKind == null,
                    onClick = {
                        selectedKind = style.kind
                    }
                )
            }
        }

        Text(
            "كل بوابة تقود إلى عالم مستقل بقوانينه وخريطته وحياته الخاصة.",
            color = SystemMobileVisualTheme.textSecondary,
            fontSize = 12.sp
        )
    }
}

@Composable
fun SystemWorldMiyarGuide() {
    val context = LocalContext.current

    var speechEngine by remember {
        mutableStateOf<TextToSpeech?>(null)
    }

    var voiceReady by remember {
        mutableStateOf(false)
    }

    val explanation = """
        أهلاً بك في نظام SYSTEM WORLD.
        أنا ميار، مرشدتك داخل هذا العالم.
        أمامك أربع بوابات مختلفة.
        البوابة الأولى هي العالم الحديث، وفيه مدن ودول حقيقية وحياة معاصرة ومهن وتجارة ومغامرات.
        البوابة الثانية هي عالم الحضارات التاريخية، وفيه حضارات حقيقية مثل سومر وبابل وآشور ومصر القديمة واليونان والصين القديمة.
        البوابة الثالثة هي عالم الأساطير والفانتازيا، وفيه التنانين والسحر والممالك والمخلوقات الأسطورية.
        البوابة الرابعة هي جزيرة الطمع، وهي جزيرة عائمة مليئة بالأسرار والتحديات والمواسم الخاصة.
        اضغط على البوابة التي تريد دخولها.
        وسأساعدك على فهم أنظمة العالم ومهامه وقوانينه وخريطته خطوة بخطوة.
    """.trimIndent()

    DisposableEffect(context) {
        var created: TextToSpeech? = null

        created = TextToSpeech(context) { status ->
            val engine = created

            if (status == TextToSpeech.SUCCESS && engine != null) {
                val languageStatus = engine.setLanguage(Locale("ar"))
                voiceReady = languageStatus >= TextToSpeech.LANG_AVAILABLE
            }
        }

        speechEngine = created

        onDispose {
            created?.stop()
            created?.shutdown()
            speechEngine = null
            voiceReady = false
        }
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF142238)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                "ميار | مرشدتك في العوالم",
                color = SystemMobileVisualTheme.gold,
                fontSize = 19.sp,
                fontWeight = FontWeight.Black
            )

            Text(
                "أهلاً بك! سأعرّفك على البوابات الأربع، وأشرح لك طبيعة كل عالم قبل الدخول.",
                color = Color.White,
                fontSize = 14.sp
            )

            Button(
                onClick = {
                    speechEngine?.speak(
                        explanation,
                        TextToSpeech.QUEUE_FLUSH,
                        null,
                        "system_miyar_world_guide"
                    )
                },
                enabled = voiceReady,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    if (voiceReady) "استمع إلى شرح ميار الصوتي"
                    else "جارٍ تجهيز صوت ميار..."
                )
            }

            Text(
                "يمكن أن يعتمد نوع الصوت واللهجة على الأصوات العربية المثبتة في جهازك.",
                color = Color.LightGray,
                fontSize = 11.sp
            )
        }
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
    val transition = rememberInfiniteTransition(
        label = "portal-${style.kind}"
    )

    val movement by transition.animateFloat(
        initialValue = -12f,
        targetValue = 12f,
        animationSpec = infiniteRepeatable(
            animation = tween(4200),
            repeatMode = RepeatMode.Reverse
        ),
        label = "portal-movement"
    )

    val glow by transition.animateFloat(
        initialValue = 0.18f,
        targetValue = 0.65f,
        animationSpec = infiniteRepeatable(
            animation = tween(2200),
            repeatMode = RepeatMode.Reverse
        ),
        label = "portal-glow"
    )

    val shimmer by transition.animateFloat(
        initialValue = -1f,
        targetValue = 2f,
        animationSpec = infiniteRepeatable(
            animation = tween(5200),
            repeatMode = RepeatMode.Restart
        ),
        label = "portal-shimmer"
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(178.dp)
            .graphicsLayer {
                translationY = movement * 0.10f
                alpha = if (enabled || selected) 1f else 0.55f
            }
            .border(
                width = if (selected) 2.5.dp else 1.dp,
                color = style.accent.copy(
                    alpha = if (selected) glow else 0.45f
                ),
                shape = RoundedCornerShape(22.dp)
            )
            .semantics {
                contentDescription = "${style.title}. ${style.subtitle}"
            }
            .clickable(
                enabled = enabled,
                role = Role.Button,
                onClick = onClick
            ),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(
            containerColor = style.deep
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (selected) 18.dp else 9.dp
        )
    ) {
        Box(Modifier.fillMaxSize()) {

            Canvas(Modifier.fillMaxSize()) {
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

                drawCircle(
                    brush = Brush.radialGradient(
                        listOf(
                            style.accent.copy(alpha = glow),
                            style.accent.copy(alpha = 0.08f),
                            Color.Transparent
                        ),
                        center = Offset(
                            w * 0.80f + movement,
                            h * 0.40f
                        ),
                        radius = h * 0.90f
                    ),
                    radius = h * 0.90f,
                    center = Offset(
                        w * 0.80f + movement,
                        h * 0.40f
                    )
                )

                when (style.kind) {
                    SystemWorldKind.MODERN_REALISTIC -> {
                        drawModernPortal(w, h, style, movement)
                    }

                    SystemWorldKind.MYTHOLOGY_HISTORY -> {
                        drawHistoryPortal(w, h, style, movement)
                    }

                    SystemWorldKind.FANTASY -> {
                        drawFantasyPortal(w, h, style, movement)
                    }

                    SystemWorldKind.GREED_ISLAND -> {
                        drawGreedPortal(w, h, style, movement)
                    }
                }

                for (i in 0..18) {
                    val x = w * ((i * 37 % 100) / 100f)
                    val y = h * ((i * 23 % 100) / 100f)
                    val pulse = 0.2f +
                        0.45f * (0.5f + 0.5f * sin(i + shimmer * 3f))

                    drawCircle(
                        color = style.accent.copy(alpha = pulse),
                        radius = (1.2f + i % 3).dp.toPx(),
                        center = Offset(x, y)
                    )
                }

                drawRect(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.White.copy(alpha = 0.12f),
                            style.accent.copy(alpha = 0.14f),
                            Color.Transparent
                        ),
                        start = Offset(w * shimmer, 0f),
                        end = Offset(w * (shimmer + 0.35f), h)
                    )
                )
            }

            Box(
                Modifier
                    .fillMaxSize()
                    .background(
                        Brush.horizontalGradient(
                            listOf(
                                Color.Black.copy(alpha = 0.88f),
                                Color.Black.copy(alpha = 0.56f),
                                Color.Transparent
                            )
                        )
                    )
            )

            Column(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .padding(18.dp)
                    .fillMaxWidth(0.82f),
                verticalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                Text(
                    style.title,
                    color = Color.White,
                    fontSize = 19.sp,
                    fontWeight = FontWeight.Black
                )

                Text(
                    style.subtitle,
                    color = Color.White.copy(alpha = 0.88f),
                    fontSize = 12.sp
                )

                Text(
                    if (selected) "جاري فتح البوابة..."
                    else if (!enabled) "يرجى الانتظار..."
                    else "اضغط للدخول إلى العالم  ←",
                    color = style.accent,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawModernPortal(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    movement: Float
) {
    for (i in 0..9) {
        val x = w * (i / 10f)
        val buildingHeight = h * (0.25f + (i % 4) * 0.12f)

        drawRect(
            color = style.secondary.copy(alpha = 0.65f),
            topLeft = Offset(x, h - buildingHeight),
            size = Size(w * 0.075f, buildingHeight)
        )

        for (row in 0..3) {
            drawRect(
                color = style.accent.copy(alpha = 0.75f),
                topLeft = Offset(
                    x + 5.dp.toPx(),
                    h - buildingHeight + row * 13.dp.toPx()
                ),
                size = Size(4.dp.toPx(), 5.dp.toPx())
            )
        }
    }

    drawLine(
        style.accent.copy(alpha = 0.8f),
        Offset(w * 0.02f, h * 0.90f),
        Offset(w * 0.98f, h * 0.90f),
        3.dp.toPx()
    )

    for (i in 0..4) {
        val x = (w * 0.15f) + i * (w * 0.18f) + movement
        drawCircle(
            style.accent.copy(alpha = 0.8f),
            3.dp.toPx(),
            Offset(x, h * 0.88f)
        )
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawHistoryPortal(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    movement: Float
) {
    val ground = h * 0.88f

    for (i in 0..2) {
        val x = w * (0.55f + i * 0.14f)
        val width = w * 0.16f
        val height = h * (0.34f + (i % 2) * 0.10f)

        val pyramid = Path().apply {
            moveTo(x, ground)
            lineTo(x + width / 2f, ground - height)
            lineTo(x + width, ground)
            close()
        }

        drawPath(pyramid, style.accent.copy(alpha = 0.58f))
    }

    for (i in 0..3) {
        val x = w * (0.12f + i * 0.10f)
        drawRect(
            style.secondary.copy(alpha = 0.75f),
            Offset(x, h * 0.44f),
            Size(w * 0.035f, h * 0.43f)
        )
    }

    drawCircle(
        style.accent.copy(alpha = 0.65f),
        h * 0.11f,
        Offset(w * 0.84f + movement * 0.3f, h * 0.20f)
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawFantasyPortal(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    movement: Float
) {
    val mountains = Path().apply {
        moveTo(0f, h * 0.88f)
        lineTo(w * 0.22f, h * 0.30f)
        lineTo(w * 0.42f, h * 0.80f)
        lineTo(w * 0.65f, h * 0.18f)
        lineTo(w, h * 0.85f)
        lineTo(w, h)
        lineTo(0f, h)
        close()
    }

    drawPath(
        mountains,
        style.secondary.copy(alpha = 0.68f)
    )

    drawCircle(
        brush = Brush.radialGradient(
            listOf(
                style.accent.copy(alpha = 0.85f),
                style.accent.copy(alpha = 0.12f),
                Color.Transparent
            ),
            center = Offset(w * 0.80f + movement, h * 0.25f),
            radius = h * 0.38f
        ),
        radius = h * 0.38f,
        center = Offset(w * 0.80f + movement, h * 0.25f)
    )

    drawLine(
        style.accent,
        Offset(w * 0.25f, h * 0.38f),
        Offset(w * 0.35f, h * 0.25f),
        3.dp.toPx()
    )
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawGreedPortal(
    w: Float,
    h: Float,
    style: SystemWorldVisualStyle,
    movement: Float
) {
    val island = Path().apply {
        moveTo(w * 0.25f, h * 0.48f + movement * 0.15f)
        cubicTo(
            w * 0.42f, h * 0.30f + movement * 0.15f,
            w * 0.70f, h * 0.30f + movement * 0.15f,
            w * 0.88f, h * 0.49f + movement * 0.15f
        )
        lineTo(w * 0.73f, h * 0.70f + movement * 0.15f)
        lineTo(w * 0.61f, h * 0.94f)
        lineTo(w * 0.45f, h * 0.70f + movement * 0.15f)
        close()
    }

    drawPath(
        island,
        Brush.verticalGradient(
            listOf(
                style.accent,
                style.secondary,
                Color(0xFF382B24)
            )
        )
    )

    for (i in 0..4) {
        val x = w * (0.39f + i * 0.095f)
        val y = h * (0.42f + (i % 2) * 0.04f) + movement * 0.15f

        drawLine(
            Color(0xFF704B30),
            Offset(x, y + 18.dp.toPx()),
            Offset(x, y),
            3.dp.toPx()
        )

        drawCircle(
            style.accent.copy(alpha = 0.9f),
            9.dp.toPx(),
            Offset(x, y - 3.dp.toPx())
        )
    }

    for (i in 0..3) {
        drawCircle(
            Color.White.copy(alpha = 0.32f),
            13.dp.toPx(),
            Offset(w * (0.18f + i * 0.19f), h * 0.72f)
        )
    }
}

@Composable
fun SystemWorldThreeDimensionalEmblem(
    style: SystemWorldVisualStyle,
    modifier: Modifier = Modifier
) {
    val transition = rememberInfiniteTransition(
        label = "world-emblem"
    )

    val rotation by transition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(6500),
            repeatMode = RepeatMode.Restart
        ),
        label = "emblem-rotation"
    )

    Canvas(modifier = modifier.clip(RoundedCornerShape(18.dp))) {
        val center = Offset(size.width / 2f, size.height / 2f)

        drawRect(
            Brush.verticalGradient(
                listOf(style.secondary, style.deep)
            )
        )

        drawCircle(
            style.accent.copy(alpha = 0.16f),
            size.minDimension * 0.42f,
            center
        )

        drawArc(
            color = style.accent,
            startAngle = rotation,
            sweepAngle = 245f,
            useCenter = false,
            topLeft = Offset(
                size.width * 0.10f,
                size.height * 0.10f
            ),
            size = Size(
                size.width * 0.80f,
                size.height * 0.80f
            ),
            style = androidx.compose.ui.graphics.drawscope.Stroke(
                width = 2.dp.toPx()
            )
        )
    }
}
