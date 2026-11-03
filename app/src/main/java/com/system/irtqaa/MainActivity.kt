package com.system.irtqaa

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontWeight

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            SystemApp()
        }
    }
}

data class Mission(
    val title: String,
    val category: String,
    var completed: Boolean = false
)

@Composable
fun SystemApp() {

    val categories = listOf(
        "الروح",
        "العقل",
        "الجسد",
        "الوعي",
        "الانضباط"
    )

    val missions = remember {
        mutableStateListOf(
            Mission("الصلاة والمحافظة عليها", "الروح"),
            Mission("قراءة 10 صفحات", "العقل"),
            Mission("ممارسة الرياضة", "الجسد"),
            Mission("التأمل والتركيز", "الوعي"),
            Mission("إنجاز مهمة مؤجلة", "الانضباط")
        )
    }

    var selectedTab by remember {
        mutableIntStateOf(0)
    }

    val xp = missions.count { it.completed } * 10

    val panel = Color(0xFF131D30)
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    SystemHologramBackground(
        modifier = Modifier.fillMaxSize()
    ) {

        MaterialTheme {

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(18.dp)
            ) {

                Text(
                    "SYSTEM",
                    color = gold,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Black
                )

                Text(
                    "الإنسان نحو الارتقاء",
                    color = Color.LightGray,
                    fontSize = 15.sp
                )

                Spacer(Modifier.height(20.dp))

                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = panel.copy(alpha = 0.92f)
                    ),
                    shape = RoundedCornerShape(18.dp)
                ) {

                    Column(
                        Modifier.padding(18.dp)
                    ) {

                        Text(
                            "المستوى العام",
                            color = Color.White
                        )

                        Text(
                            "LV. ${1 + xp / 100}",
                            color = gold,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            "$xp XP",
                            color = cyan
                        )

                        LinearProgressIndicator(
                            progress = { (xp % 100) / 100f },
                            modifier = Modifier.fillMaxWidth(),
                            color = gold
                        )
                    }
                }

                Spacer(Modifier.height(20.dp))

                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {

                    listOf(
                        "الرئيسية",
                        "المهام",
                        "المستويات"
                    ).forEachIndexed { index, title ->

                        Button(
                            onClick = {
                                selectedTab = index
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor =
                                    if (selectedTab == index) gold else panel,
                                contentColor =
                                    if (selectedTab == index) Color.Black else Color.White
                            )
                        ) {
                            Text(title)
                        }
                    }
                }

                Spacer(Modifier.height(18.dp))

                when (selectedTab) {

                    0 -> {

                        Text(
                            "مرحباً بك أيها المقاتل",
                            color = Color.White,
                            fontSize = 21.sp
                        )

                        Spacer(Modifier.height(12.dp))

                        Text(
                            "إنجازات اليوم: ${missions.count { it.completed }} / 5",
                            color = cyan
                        )

                        Text(
                            "كل مهمة مكتملة تمنحك 10 XP",
                            color = Color.LightGray
                        )
                    }

                    1 -> {

                        Text(
                            "المهام اليومية",
                            color = gold,
                            fontSize = 22.sp
                        )

                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {

                            items(missions) { mission ->

                                Card(
                                    colors = CardDefaults.cardColors(
                                        containerColor = panel.copy(alpha = 0.92f)
                                    )
                                ) {

                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(12.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {

                                        Column(
                                            Modifier.weight(1f)
                                        ) {

                                            Text(
                                                mission.title,
                                                color = Color.White
                                            )

                                            Text(
                                                mission.category,
                                                color = cyan
                                            )
                                        }

                                        Checkbox(
                                            checked = mission.completed,
                                            onCheckedChange = {
                                                val index =
                                                    missions.indexOf(mission)

                                                if (index >= 0) {
                                                    missions[index] =
                                                        mission.copy(completed = it)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    2 -> {

                        Text(
                            "مجالات التطور",
                            color = gold,
                            fontSize = 22.sp
                        )

                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(10.dp)
                        ) {

                            items(categories) { category ->

                                val points = missions.count {
                                    it.category == category && it.completed
                                } * 10

                                Card(
                                    colors = CardDefaults.cardColors(
                                        containerColor = panel.copy(alpha = 0.92f)
                                    )
                                ) {

                                    Column(
                                        Modifier.padding(16.dp)
                                    ) {

                                        Text(
                                            category,
                                            color = Color.White,
                                            fontSize = 19.sp
                                        )

                                        Text(
                                            "$points XP",
                                            color = cyan
                                        )

                                        LinearProgressIndicator(
                                            progress = {
                                                (points % 100) / 100f
                                            },
                                            modifier = Modifier.fillMaxWidth(),
                                            color = gold
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
