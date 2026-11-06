package com.system.irtqaa

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SystemNestedWorldHub(
    onWorldSelected: (SystemWorldKind) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xFF070B12))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Text(
            "SYSTEM WORLD",
            color = Color(0xFFFFC857),
            fontSize = 26.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            "أربعة عوالم داخل بوابة واحدة",
            color = Color.White,
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold
        )

        Text(
            "اختر إحدى الطبقات ليتحول عالم SYSTEM بالكامل إليها.",
            color = Color.LightGray,
            fontSize = 13.sp
        )

        SystemWorldMiyarGuide()

        Spacer(Modifier.height(8.dp))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(430.dp)
        ) {
            SystemNestedPortalLayer(
                index = 0,
                onWorldSelected = onWorldSelected
            )
        }

        Text(
            "العوالم الأربعة تبقى مجتمعة، ويمكنك الانتقال بينها.",
            color = Color(0xFF45D6E8),
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun SystemNestedPortalLayer(
    index: Int,
    onWorldSelected: (SystemWorldKind) -> Unit,
    modifier: Modifier = Modifier
) {
    val styles = SystemWorldVisualStyles.all
    val style = styles[index]

    val transition = rememberInfiniteTransition(
        label = "nested-world-${style.kind}"
    )

    val movement by transition.animateFloat(
        initialValue = -3f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(
            animation = tween(2600 + index * 500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "world-movement"
    )

    val glow by transition.animateFloat(
        initialValue = 0.35f,
        targetValue = 0.85f,
        animationSpec = infiniteRepeatable(
            animation = tween(1800 + index * 300),
            repeatMode = RepeatMode.Reverse
        ),
        label = "world-glow"
    )

    Box(
        modifier = modifier
            .fillMaxSize()
            .graphicsLayer {
                translationY = movement
            }
            .clip(RoundedCornerShape(24.dp))
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        style.deep,
                        style.surface,
                        Color.Black
                    )
                )
            )
            .border(
                width = 2.dp,
                color = style.accent.copy(alpha = glow),
                shape = RoundedCornerShape(24.dp)
            )
            .clickable {
                onWorldSelected(style.kind)
            }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(
                    horizontal = 13.dp,
                    vertical = 9.dp
                ),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                "${index + 1}  |  ${style.title}",
                color = style.accent,
                fontSize = 15.sp,
                fontWeight = FontWeight.Black
            )

            Text(
                style.subtitle,
                color = Color.White.copy(alpha = 0.85f),
                fontSize = 10.sp
            )
        }

        if (index < styles.lastIndex) {
            SystemNestedPortalLayer(
                index = index + 1,
                onWorldSelected = onWorldSelected,
                modifier = Modifier
                    .padding(
                        start = 10.dp,
                        end = 10.dp,
                        top = 51.dp,
                        bottom = 10.dp
                    )
            )
        } else {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = 55.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "بوابة جزيرة الطمع\n\nالأسرار والكنوز والتحديات",
                    color = style.accent,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Black
                )
            }
        }
    }
}
