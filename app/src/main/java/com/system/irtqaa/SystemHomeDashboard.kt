package com.system.irtqaa

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SystemHomeDashboard(
    overallLevel: Int,
    totalExperience: Int,
    completedCount: Int,
    totalTasks: Int,
    onSelectWorld: (String) -> Unit,
    onExplainClick: () -> Unit,
    onTalkClick: () -> Unit,
    onChatClick: () -> Unit,
    onAccountLinkClick: () -> Unit
) {
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)
    val panel = Color(0xE6132035)
    val white = Color.White

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    listOf(
                        Color(0xFF07111F),
                        Color(0xFF101C32),
                        Color(0xFF17152D)
                    )
                )
            )
            .padding(12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {

        // المنطقة اليسرى: العوالم الأربعة
        Column(
            modifier = Modifier
                .width(225.dp)
                .fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(9.dp)
        ) {
            Text(
                "عوالم SYSTEM",
                color = gold,
                fontSize = 21.sp,
                fontWeight = FontWeight.Black
            )

            Text(
                "اختر عالم رحلتك",
                color = Color.LightGray,
                fontSize = 12.sp
            )

            HomeWorldCard(
                title = "العالم الحديث",
                subtitle = "المدن والحياة الواقعية",
                symbol = "🌆",
                accent = Color(0xFF45D6E8),
                modifier = Modifier.weight(1f),
                onClick = { onSelectWorld("real") }
            )

            HomeWorldCard(
                title = "عالم التاريخ",
                subtitle = "الحضارات والأساطير",
                symbol = "🏛️",
                accent = Color(0xFFE6B65C),
                modifier = Modifier.weight(1f),
                onClick = { onSelectWorld("mythology") }
            )

            HomeWorldCard(
                title = "العالم الخيالي",
                subtitle = "الممالك والسحر",
                symbol = "🐉",
                accent = Color(0xFFB69BFF),
                modifier = Modifier.weight(1f),
                onClick = { onSelectWorld("fantasy") }
            )

            HomeWorldCard(
                title = "جزيرة الطمع",
                subtitle = "العالم الموسمي الغامض",
                symbol = "🏝️",
                accent = Color(0xFF65E6A6),
                modifier = Modifier.weight(1f),
                onClick = { onSelectWorld("greed") }
            )
        }

        // المنطقة الوسطى: ميار والإنجازات
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        "SYSTEM",
                        color = gold,
                        fontSize = 27.sp,
                        fontWeight = FontWeight.Black
                    )

                    Text(
                        "نظام البشرية نحو الارتقاء",
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )
                }

                Text(
                    "الرئيسية",
                    color = cyan,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            SystemMiyarWelcomeCard(
                onExplainClick = onExplainClick,
                onTalkClick = onTalkClick,
                modifier = Modifier.weight(1f)
            )

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(
                    containerColor = panel
                )
            ) {
                Column(
                    modifier = Modifier.padding(15.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        "مرحباً بك أيها المقاتل",
                        color = white,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        "إنجازات اليوم: $completedCount / $totalTasks",
                        color = cyan,
                        fontSize = 14.sp
                    )

                    LinearProgressIndicator(
                        progress = {
                            if (totalTasks > 0) {
                                completedCount.toFloat() / totalTasks
                            } else {
                                0f
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        color = gold,
                        trackColor = Color.White.copy(alpha = 0.12f)
                    )

                    Text(
                        "واصل رحلتك، فكل إنجاز يقربك من الارتقاء.",
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )
                }
            }
        }

        // المنطقة اليمنى: بيانات اللاعب والخدمات
        Column(
            modifier = Modifier
                .width(205.dp)
                .fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(
                    containerColor = panel
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(15.dp),
                    verticalArrangement = Arrangement.spacedBy(9.dp)
                ) {
                    Text(
                        "ملف اللاعب",
                        color = white,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        "المستوى العام",
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )

                    Text(
                        "LV. $overallLevel",
                        color = gold,
                        fontSize = 31.sp,
                        fontWeight = FontWeight.Black
                    )

                    HorizontalDivider(
                        color = Color.White.copy(alpha = 0.12f)
                    )

                    Text(
                        "الخبرة الكلية",
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )

                    Text(
                        "$totalExperience XP",
                        color = cyan,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Text(
                "الاتصال والخدمات",
                color = gold,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold
            )

            HomeQuickAction(
                symbol = "💬",
                title = "الدردشة العالمية",
                subtitle = "تواصل مع اللاعبين",
                accent = cyan,
                onClick = onChatClick
            )

            HomeQuickAction(
                symbol = "🔗",
                title = "ربط الحسابات",
                subtitle = "Google و Facebook",
                accent = gold,
                onClick = onAccountLinkClick
            )

            Spacer(Modifier.weight(1f))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = panel
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        "SYSTEM WORLD",
                        color = gold,
                        fontWeight = FontWeight.Black,
                        fontSize = 15.sp
                    )

                    Text(
                        "رحلتك تبدأ من هنا",
                        color = Color.LightGray,
                        fontSize = 11.sp,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
private fun HomeWorldCard(
    title: String,
    subtitle: String,
    symbol: String,
    accent: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(17.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xE6192940)
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 5.dp
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 10.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(9.dp)
        ) {
            Text(
                symbol,
                fontSize = 27.sp
            )

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    title,
                    color = accent,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Black
                )

                Text(
                    subtitle,
                    color = Color.LightGray,
                    fontSize = 10.sp,
                    maxLines = 2
                )
            }

            Text(
                "‹",
                color = accent,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun HomeQuickAction(
    symbol: String,
    title: String,
    subtitle: String,
    accent: Color,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(15.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xE6192940)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(11.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(9.dp)
        ) {
            Text(
                symbol,
                fontSize = 24.sp
            )

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    title,
                    color = accent,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    subtitle,
                    color = Color.LightGray,
                    fontSize = 10.sp
                )
            }
        }
    }
}
