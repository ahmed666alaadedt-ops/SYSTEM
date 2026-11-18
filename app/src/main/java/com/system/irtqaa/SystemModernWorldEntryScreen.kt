package com.system.irtqaa

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Dedicated modern-world destination. It deliberately does not fall back to
 * the legacy SystemWorldScreen while the embedded Godot host/AAR is absent.
 */
@Composable
fun SystemModernWorldEntryScreen(onBack: () -> Unit) {
    val accent = Color(0xFF42D9E8)
    val background = Color(0xFF071B2B)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(background, Color(0xFF102B3C), Color(0xFF080D18))
                )
            )
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            "SYSTEM WORLD",
            color = accent,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(12.dp))
        Text(
            "العالم الحديث",
            color = Color.White,
            fontSize = 30.sp,
            fontWeight = FontWeight.Black
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "وجهتك إلى المدن الحقيقية والاستكشاف والحياة المفتوحة.",
            color = Color(0xFFD4E4F0),
            fontSize = 16.sp,
            lineHeight = 25.sp
        )
        Spacer(Modifier.height(22.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(22.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color(0xE61A3042)
            )
        ) {
            Column(Modifier.padding(18.dp)) {
                Text(
                    "تشغيل العالم ثلاثي الأبعاد",
                    color = accent,
                    fontSize = 19.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(10.dp))
                Text(
                    "تم تصحيح مسار التنقل حتى لا يفتح التصميم القديم تلقائياً. لكن محرك Godot لم يُضمَّن داخل تطبيق Android بعد؛ لذلك لن أعرض لك شاشة قديمة على أنها العالم الجديد.",
                    color = Color.White,
                    fontSize = 14.sp,
                    lineHeight = 23.sp
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    "حالة الربط: بانتظار تصدير Godot Android AAR وإنشاء شاشة الاستضافة الأصلية.",
                    color = Color(0xFFFFD27A),
                    fontSize = 13.sp,
                    lineHeight = 21.sp
                )
            }
        }
        Spacer(Modifier.height(22.dp))
        OutlinedButton(
            onClick = onBack,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = accent)
        ) {
            Text("العودة إلى اختيار العوالم")
        }
    }
}
