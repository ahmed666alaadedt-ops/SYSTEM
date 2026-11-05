package com.system.irtqaa

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SystemMiyarWelcomeCard(
    onExplainClick: () -> Unit,
    onTalkClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF35D9F2)

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xE6101828)
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 8.dp
        )
    ) {
        Box(
            modifier = Modifier
                .background(
                    Brush.linearGradient(
                        listOf(
                            Color(0xFF101827),
                            Color(0xFF172B42),
                            Color(0xFF211B36)
                        )
                    )
                )
                .padding(16.dp)
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(66.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.radialGradient(
                                    listOf(
                                        cyan.copy(alpha = 0.30f),
                                        gold.copy(alpha = 0.18f),
                                        Color(0xFF090E18)
                                    )
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Image(
                            painter = painterResource(
                                id = R.drawable.ic_system_foreground
                            ),
                            contentDescription = "شعار SYSTEM",
                            modifier = Modifier.size(46.dp)
                        )
                    }

                    Column(
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = "MIYAR",
                            color = gold,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 2.sp
                        )

                        Text(
                            text = "مرشدتك الذكية داخل SYSTEM",
                            color = Color(0xFFD7E2F0),
                            fontSize = 13.sp
                        )
                    }

                    Text(
                        text = "●",
                        color = Color(0xFF4ADE80),
                        fontSize = 13.sp
                    )
                }

                Text(
                    text = "أهلاً بك من جديد!",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    text = "أنا ميار، أرافقك في رحلتك. أشرح لك الأنظمة والعوالم والمهام، وأساعدك تعرف خطوتك القادمة.",
                    color = Color(0xFFB9C7D9),
                    fontSize = 14.sp,
                    lineHeight = 21.sp
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Button(
                        onClick = onExplainClick,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = gold,
                            contentColor = Color(0xFF101827)
                        )
                    ) {
                        Text(
                            "اشرحي لي SYSTEM",
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Button(
                        onClick = onTalkClick,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF18364A),
                            contentColor = cyan
                        )
                    ) {
                        Text(
                            "تحدثي مع ميار",
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}
