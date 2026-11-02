package com.system.irtqaa

import android.os.Bundle
import android.content.Context
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val Dark = Color(0xFF080D18)
private val Panel = Color(0xFF151F32)
private val Gold = Color(0xFFFFC857)
private val White = Color(0xFFF4F6FA)
private val Muted = Color(0xFF9BA9BD)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val prefs = getSharedPreferences("system_data", Context.MODE_PRIVATE)
        val today = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())

        if (prefs.getString("day", "") != today) {
            prefs.edit().clear().putString("day", today).apply()
        }

        setContent {
            SystemApp(prefs)
        }
    }
}

@Composable
fun SystemApp(prefs: android.content.SharedPreferences) {
    var page by remember { mutableIntStateOf(0) }
    var xp by remember { mutableIntStateOf(prefs.getInt("xp", 0)) }

    val tasks = listOf(
        "استيقظ مبكراً",
        "اقرأ لمدة 20 دقيقة",
        "مارس التمارين الرياضية",
        "خصص وقتاً للتأمل",
        "راجع أهدافك اليومية"
    )

    val completed = remember {
        mutableStateListOf<Boolean>().apply {
            repeat(tasks.size) { index ->
                add(prefs.getBoolean("task_$index", false))
            }
        }
    }

    val level = (xp / 50) + 1
    val progress = (xp % 50) / 50f

    MaterialTheme {
        Scaffold(
            containerColor = Dark,
            bottomBar = {
                NavigationBar(containerColor = Panel) {
                    listOf("الرئيسية", "المهام", "المستويات").forEachIndexed { index, label ->
                        NavigationBarItem(
                            selected = page == index,
                            onClick = { page = index },
                            icon = {
                                Text(
                                    listOf("⌂", "✓", "★")[index],
                                    fontSize = 20.sp
                                )
                            },
                            label = { Text(label, color = White) },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = Gold,
                                indicatorColor = Color(0xFF34425B)
                            )
                        )
                    }
                }
            }
        ) { padding ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Dark)
                    .padding(padding)
                    .padding(18.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Text(
                        "SYSTEM",
                        color = Gold,
                        fontSize = 30.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "الإنسان نحو الارتقاء",
                        color = Muted,
                        fontSize = 15.sp
                    )
                }

                item {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = Panel),
                        shape = RoundedCornerShape(18.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(Modifier.padding(20.dp)) {
                            Text("مستوى المستخدم", color = Muted)
                            Text(
                                "LEVEL $level",
                                color = Gold,
                                fontSize = 34.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Text("$xp XP", color = White)
                            Spacer(Modifier.height(12.dp))
                            LinearProgressIndicator(
                                progress = { progress },
                                modifier = Modifier.fillMaxWidth(),
                                color = Gold,
                                trackColor = Dark
                            )
                            Text(
                                "${xp % 50} / 50 XP للمستوى التالي",
                                color = Muted,
                                fontSize = 12.sp
                            )
                        }
                    }
                }

                item {
                    Text(
                        when (page) {
                            1 -> "المهام اليومية"
                            2 -> "مجالات التطور"
                            else -> "لوحة التحكم"
                        },
                        color = White,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (page == 2) {
                    val areas = listOf(
                        "الروح" to "التوازن والقيم",
                        "العقل" to "المعرفة والتعلم",
                        "الجسد" to "الصحة والقوة",
                        "الوعي" to "الفهم والتركيز",
                        "الانضباط" to "الالتزام والاستمرار"
                    )

                    items(areas.size) { index ->
                        AreaCard(areas[index].first, areas[index].second)
                    }
                } else {
                    items(tasks.size) { index ->
                        Card(
                            colors = CardDefaults.cardColors(containerColor = Panel),
                            shape = RoundedCornerShape(14.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier.padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Checkbox(
                                    checked = completed[index],
                                    onCheckedChange = { checked ->
                                        if (checked != completed[index]) {
                                            completed[index] = checked
                                            xp += if (checked) 10 else -10
                                            prefs.edit()
                                                .putBoolean("task_$index", checked)
                                                .putInt("xp", xp)
                                                .apply()
                                        }
                                    },
                                    colors = CheckboxDefaults.colors(
                                        checkedColor = Gold
                                    )
                                )
                                Column(Modifier.weight(1f)) {
                                    Text(
                                        tasks[index],
                                        color = White,
                                        fontWeight = FontWeight.Medium
                                    )
                                    Text("+10 XP", color = Gold, fontSize = 12.sp)
                                }
                            }
                        }
                    }
                }

                item {
                    Spacer(Modifier.height(10.dp))
                    Text(
                        "كل يوم فرصة جديدة لتصبح أفضل.",
                        color = Muted,
                        modifier = Modifier.fillMaxWidth(),
                        fontSize = 14.sp
                    )
                }
            }
        }
    }
}

@Composable
fun AreaCard(name: String, description: String) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Panel),
        shape = RoundedCornerShape(14.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(18.dp)) {
            Text(name, color = Gold, fontSize = 19.sp, fontWeight = FontWeight.Bold)
            Text(description, color = Muted, fontSize = 13.sp)
        }
    }
}
