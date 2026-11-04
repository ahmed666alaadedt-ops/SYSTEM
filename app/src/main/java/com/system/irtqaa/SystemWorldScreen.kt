package com.system.irtqaa

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SystemWorldScreen(
    progress: PlayerWorldProgress,
    onProgressChange: (PlayerWorldProgress) -> Unit
) {
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)
    val panel = Color(0xFF131D30)

    val locations = SystemWorldEngine.getAvailableLocations(progress)
    val missions = SystemWorldEngine.getAvailableMissions(progress)

    var selectedLocation by remember {
        mutableStateOf("ancient_kingdom")
    }

    var battleMessage by remember {
        mutableStateOf("")
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            Text(
                "SYSTEM WORLD",
                color = gold,
                fontSize = 25.sp
            )

            Text(
                "عالمك الافتراضي يبدأ من هنا",
                color = Color.LightGray
            )
        }

        item {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(Modifier.padding(16.dp)) {
                    Text("شخصيتك داخل العالم", color = Color.White)
                    Text("المستوى: ${progress.playerLevel}", color = gold)
                    Text("الخبرة: ${progress.experience} XP", color = cyan)
                    Text("العملات: ${progress.coins}", color = gold)
                }
            }
        }

        item {
            Text("المدن والمناطق", color = gold, fontSize = 21.sp)
        }

        items(locations) { location ->
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text(location.name, color = Color.White, fontSize = 18.sp)
                    Text(location.description, color = Color.LightGray)

                    Text(
                        "المستوى المطلوب: ${location.requiredLevel}",
                        color = cyan
                    )

                    Button(
                        onClick = {
                            selectedLocation = location.id
                        },
                        enabled = location.isUnlocked
                    ) {
                        Text(
                            if (selectedLocation == location.id)
                                "أنت هنا"
                            else
                                "دخول المنطقة"
                        )
                    }
                }
            }
        }

        item {
            Text("بوابات العالم", color = gold, fontSize = 21.sp)
        }

        items(SystemWorldEngine.getAvailableGates(progress)) { gate ->
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text(gate.name, color = Color.White)
                    Text(
                        "المستوى المطلوب: ${gate.requiredLevel}",
                        color = cyan
                    )
                    Text(
                        if (gate.isUnlocked) "البوابة مفتوحة"
                        else "البوابة مغلقة",
                        color = Color.LightGray
                    )
                }
            }
        }

        item {
            Text("مهام العالم", color = gold, fontSize = 21.sp)
        }

        items(missions) { mission ->
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text(mission.title, color = Color.White)
                    Text(mission.description, color = Color.LightGray)
                    Text("+${mission.xpReward} XP", color = cyan)

                    Button(
                        onClick = {
                            onProgressChange(
                                SystemWorldEngine.completeMission(
                                    progress,
                                    mission.id
                                )
                            )
                        },
                        enabled = !mission.isCompleted
                    ) {
                        Text(
                            if (mission.isCompleted)
                                "مكتملة"
                            else
                                "إنجاز المهمة"
                        )
                    }
                }
            }
        }

        item {
            Text("الكائنات والوحوش", color = gold, fontSize = 21.sp)
        }

        items(SystemWorldData.monsters) { monster ->
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(Modifier.padding(14.dp)) {
                    Text(monster.name, color = Color.White, fontSize = 18.sp)
                    Text(monster.description, color = Color.LightGray)
                    Text("المستوى: ${monster.level}", color = cyan)
                    Text(
                        "المكافأة: ${monster.experienceReward} XP",
                        color = gold
                    )

                    Button(
                        onClick = {
                            val result = SystemWorldCombat.fightMonster(
                                progress = progress,
                                monsterId = monster.monsterId,
                                playerPower = progress.playerLevel * 10
                            )

                            onProgressChange(result.updatedProgress)
                            battleMessage = result.message
                        },
                        enabled = progress.playerLevel >= monster.level
                    ) {
                        Text("مواجهة الوحش")
                    }
                }
            }
        }

        if (battleMessage.isNotBlank()) {
            item {
                Text(
                    battleMessage,
                    color = cyan,
                    fontSize = 18.sp
                )
            }
        }

        item {
            Spacer(Modifier.height(24.dp))
            Text(
                "هذا العالم قابل للتوسع والاستكشاف.",
                color = Color.LightGray
            )
        }
    }
}
