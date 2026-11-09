
package com.system.irtqaa

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
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
    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = false,
            dismissOnClickOutside = false
        )
    ) {
        BoxWithConstraints(
            modifier = Modifier.fillMaxSize()
        ) {
            val screenWidth = maxWidth
            val screenHeight = maxHeight

            // صورة الواجهة الأصلية: خلفية واحدة فقط.
            Image(
                painter = painterResource(
                    id = R.drawable.system_home_background
                ),
                contentDescription = "واجهة SYSTEM WORLD الرئيسية",
                modifier = Modifier.fillMaxSize(),
                contentScale = androidx.compose.ui.layout.ContentScale.FillBounds
            )

            // بوابات العوالم الأربعة.
            HomeHotspot(
                description = "العالم المستقبلي",
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset(
                        x = screenWidth * 0.012f,
                        y = screenHeight * 0.225f
                    )
                    .size(
                        width = screenWidth * 0.112f,
                        height = screenHeight * 0.475f
                    ),
                onClick = { onSelectWorld("real") }
            )

            HomeHotspot(
                description = "العالم التاريخي",
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset(
                        x = screenWidth * 0.128f,
                        y = screenHeight * 0.255f
                    )
                    .size(
                        width = screenWidth * 0.105f,
                        height = screenHeight * 0.445f
                    ),
                onClick = { onSelectWorld("mythology") }
            )

            HomeHotspot(
                description = "العالم الخيالي",
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset(
                        x = screenWidth * 0.235f,
                        y = screenHeight * 0.255f
                    )
                    .size(
                        width = screenWidth * 0.105f,
                        height = screenHeight * 0.445f
                    ),
                onClick = { onSelectWorld("fantasy") }
            )

            HomeHotspot(
                description = "جزيرة الطمع",
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset(
                        x = screenWidth * 0.342f,
                        y = screenHeight * 0.285f
                    )
                    .size(
                        width = screenWidth * 0.065f,
                        height = screenHeight * 0.405f
                    ),
                onClick = { onSelectWorld("greed") }
            )

            // صور العوالم المصغرة أسفل اليسار.
            HomeHotspot(
                description = "معاينة العالم المستقبلي",
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .offset(
                        x = screenWidth * 0.005f,
                        y = -(screenHeight * 0.018f)
                    )
                    .size(
                        width = screenWidth * 0.083f,
                        height = screenHeight * 0.105f
                    ),
                onClick = { onSelectWorld("real") }
            )

            HomeHotspot(
                description = "معاينة العالم التاريخي",
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .offset(
                        x = screenWidth * 0.092f,
                        y = -(screenHeight * 0.018f)
                    )
                    .size(
                        width = screenWidth * 0.080f,
                        height = screenHeight * 0.105f
                    ),
                onClick = { onSelectWorld("mythology") }
            )

            HomeHotspot(
                description = "معاينة العالم الخيالي",
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .offset(
                        x = screenWidth * 0.178f,
                        y = -(screenHeight * 0.018f)
                    )
                    .size(
                        width = screenWidth * 0.080f,
                        height = screenHeight * 0.105f
                    ),
                onClick = { onSelectWorld("fantasy") }
            )

            HomeHotspot(
                description = "معاينة جزيرة الطمع",
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .offset(
                        x = screenWidth * 0.264f,
                        y = -(screenHeight * 0.018f)
                    )
                    .size(
                        width = screenWidth * 0.060f,
                        height = screenHeight * 0.105f
                    ),
                onClick = { onSelectWorld("greed") }
            )

            // ملف اللاعب في أعلى اليمين.
            HomeHotspot(
                description = "ملف اللاعب والحساب",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.075f
                    )
                    .size(
                        width = screenWidth * 0.155f,
                        height = screenHeight * 0.155f
                    ),
                onClick = onAccountLinkClick
            )

            // إعدادات التطبيق أعلى اليمين.
            HomeHotspot(
                description = "الإعدادات",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.005f),
                        y = screenHeight * 0.005f
                    )
                    .size(
                        width = screenWidth * 0.045f,
                        height = screenHeight * 0.085f
                    ),
                onClick = onSettingsClick
            )

            // الدردشة العالمية.
            HomeHotspot(
                description = "الدردشة العالمية",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.285f
                    )
                    .size(
                        width = screenWidth * 0.130f,
                        height = screenHeight * 0.075f
                    ),
                onClick = onChatClick
            )

            // الأصدقاء.
            HomeHotspot(
                description = "الأصدقاء",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.360f
                    )
                    .size(
                        width = screenWidth * 0.130f,
                        height = screenHeight * 0.070f
                    ),
                onClick = onChatClick
            )

            // البريد.
            HomeHotspot(
                description = "البريد",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.435f
                    )
                    .size(
                        width = screenWidth * 0.130f,
                        height = screenHeight * 0.070f
                    ),
                onClick = onChatClick
            )

            // الإنجازات.
            HomeHotspot(
                description = "الإنجازات",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.510f
                    )
                    .size(
                        width = screenWidth * 0.130f,
                        height = screenHeight * 0.070f
                    ),
                onClick = onSettingsClick
            )

            // الحقيبة.
            HomeHotspot(
                description = "الحقيبة",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.585f
                    )
                    .size(
                        width = screenWidth * 0.130f,
                        height = screenHeight * 0.070f
                    ),
                onClick = onSettingsClick
            )

            // الخريطة.
            HomeHotspot(
                description = "الخريطة",
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(
                        x = -(screenWidth * 0.012f),
                        y = screenHeight * 0.660f
                    )
                    .size(
                        width = screenWidth * 0.130f,
                        height = screenHeight * 0.070f
                    ),
                onClick = onSettingsClick
            )

            // نافذة حوار ميار في أسفل الوسط.
            HomeHotspot(
                description = "التحدث مع ميار",
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .offset(
                        x = screenWidth * 0.015f,
                        y = -(screenHeight * 0.075f)
                    )
                    .size(
                        width = screenWidth * 0.365f,
                        height = screenHeight * 0.145f
                    ),
                onClick = onTalkClick
            )

            // أدوات الصوت والموسيقى والجودة والحفظ.
            HomeHotspot(
                description = "إعدادات الصوت والجودة والحفظ",
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .offset(
                        x = -(screenWidth * 0.010f),
                        y = -(screenHeight * 0.145f)
                    )
                    .size(
                        width = screenWidth * 0.195f,
                        height = screenHeight * 0.090f
                    ),
                onClick = onSettingsClick
            )

            // زر بدء المغامرة.
            HomeHotspot(
                description = "ابدأ المغامرة",
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .offset(
                        x = -(screenWidth * 0.008f),
                        y = -(screenHeight * 0.018f)
                    )
                    .size(
                        width = screenWidth * 0.205f,
                        height = screenHeight * 0.115f
                    ),
                onClick = onStartGameClick
            )
        }
    }
}

@Composable
private fun HomeHotspot(
    description: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .semantics {
                contentDescription = description
            }
            .clickable(
                onClick = onClick
            )
    )
}
