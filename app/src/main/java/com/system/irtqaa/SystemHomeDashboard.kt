
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
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

@Composable
fun SystemHomeDashboard(
    overallLevel: Int,
    totalExperience: Int,
    completedCount: Int,
    totalTasks: Int,
    onSelectWorld: (String) -> Unit,
    onStartGameClick: () -> Unit,
    onExplainClick: () -> Unit,
    onTalkClick: () -> Unit,
    onChatClick: () -> Unit,
    onAccountLinkClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)
    val panel = Color(0xE6132035)
    val white = Color.White

    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = false,
            dismissOnClickOutside = false
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            Color(0xFF06111F),
                            Color(0xFF10283A),
                            Color(0xFF071522),
                            Color(0xFF030912)
                        )
                    )
                )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {

                // العوالم الأربعة
                Column(
                    modifier = Modifier
                        .width(205.dp)
                        .fillMaxHeight(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        "عوالم SYSTEM",
                        color = gold,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Black
                    )

                    HomeWorldCard(
                        title = "العالم الحديث",
                        subtitle = "المدن والحياة الواقعية",
                        symbol = "🌆",
                        accent = cyan,
                        modifier = Modifier.weight(1f),
                        onClick = { onSelectWorld("real") }
                    )

                    HomeWorldCard(
                        title = "عالم التاريخ",
                        subtitle = "الحضارات والعصور",
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
                        subtitle = "العالم الموسمي",
                        symbol = "🏝️",
                        accent = Color(0xFF65E6A6),
                        modifier = Modifier.weight(1f),
                        onClick = { onSelectWorld("greed") }
                    )
                }

                // الوسط: ميار وبدء الرحلة
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        "SYSTEM",
                        color = gold,
                        fontSize = 30.sp,
                        fontWeight = FontWeight.Black
                    )

                    Text(
                        "نظام البشرية نحو الارتقاء",
                        color = white,
                        fontSize = 13.sp,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(12.dp))

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
                                .padding(12.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(7.dp)
                        ) {
                            Text(
                                "مرحباً بك في SYSTEM",
                                color = white,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )

                            Text(
                                "أنا ميار، مرشدتك في رحلتك.",
                                color = cyan,
                                fontSize = 13.sp
                            )

                            Text(
                                "إنجازات اليوم: $completedCount / $totalTasks",
                                color = white,
                                fontSize = 13.sp
                            )

                            LinearProgressIndicator(
                                progress = {
                                    if (totalTasks > 0) {
                                        (completedCount.toFloat() / totalTasks)
                                            .coerceIn(0f, 1f)
                                    } else {
                                        0f
                                    }
                                },
                                modifier = Modifier.fillMaxWidth(),
                                color = gold,
                                trackColor = Color.White.copy(alpha = 0.16f)
                            )

                            Button(
                                onClick = onStartGameClick,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(49.dp),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = gold,
                                    contentColor = Color(0xFF101522)
                                ),
                                shape = RoundedCornerShape(14.dp)
                            ) {
                                Text(
                                    "▶  بدء اللعب",
                                    fontSize = 17.sp,
                                    fontWeight = FontWeight.Black
                                )
                            }

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                OutlinedButton(
                                    onClick = onExplainClick,
                                    modifier = Modifier.weight(1f),
                                    colors = ButtonDefaults.outlinedButtonColors(
                                        contentColor = cyan
                                    )
                                ) {
                                    Text("شرح النظام")
                                }

                                OutlinedButton(
                                    onClick = onTalkClick,
                                    modifier = Modifier.weight(1f),
                                    colors = ButtonDefaults.outlinedButtonColors(
                                        contentColor = gold
                                    )
                                ) {
                                    Text("تحدث مع ميار")
                                }
                            }
                        }
                    }
                }

                // ملف اللاعب والخدمات
                Column(
                    modifier = Modifier
                        .width(195.dp)
                        .fillMaxHeight(),
                    verticalArrangement = Arrangement.spacedBy(9.dp)
                ) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(17.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = panel
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(13.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                "ملف اللاعب",
                                color = white,
                                fontSize = 16.sp,
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
                                fontSize = 29.sp,
                                fontWeight = FontWeight.Black
                            )

                            HorizontalDivider(
                                color = Color.White.copy(alpha = 0.15f)
                            )

                            Text(
                                "الخبرة الكلية",
                                color = Color.LightGray,
                                fontSize = 12.sp
                            )

                            Text(
                                "$totalExperience XP",
                                color = cyan,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    Text(
                        "الخدمات",
                        color = gold,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )

                    HomeQuickAction(
                        symbol = "💬",
                        title = "الدردشة العالمية",
                        subtitle = "فتح المحادثة",
                        accent = cyan,
                        onClick = onChatClick
                    )

                    HomeQuickAction(
                        symbol = "🔗",
                        title = "ربط الحسابات",
                        subtitle = "إدارة الحساب",
                        accent = gold,
                        onClick = onAccountLinkClick
                    )

                    HomeQuickAction(
                        symbol = "⚙️",
                        title = "الإعدادات",
                        subtitle = "إعدادات التطبيق",
                        accent = Color(0xFFB69BFF),
                        onClick = onSettingsClick
                    )

                    Spacer(Modifier.weight(1f))

                    Text(
                        "SYSTEM WORLD",
                        color = gold,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Black,
                        modifier = Modifier.align(Alignment.CenterHorizontally)
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
        shape = RoundedCornerShape(15.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xE6192940)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 9.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(symbol, fontSize = 25.sp)

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    title,
                    color = accent,
                    fontSize = 13.sp,
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
                fontSize = 23.sp,
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
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xE6192940)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(symbol, fontSize = 22.sp)

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    title,
                    color = accent,
                    fontSize = 12.sp,
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
