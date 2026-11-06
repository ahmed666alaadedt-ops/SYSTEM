
package com.system.irtqaa

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SystemFantasyWorldScreen(
    onBack: () -> Unit
) {
    val gold = Color(0xFFFFC857)
    val purple = Color(0xFFB58CFF)
    val cyan = Color(0xFF55DDF0)
    val panel = Color(0xFF19142A)

    var level by remember { mutableIntStateOf(1) }
    var xp by remember { mutableIntStateOf(0) }
    var coins by remember { mutableIntStateOf(0) }
    var health by remember { mutableIntStateOf(100) }

    var selectedZone by remember {
        mutableStateOf("whisper_forest")
    }

    var completedQuests by remember {
        mutableStateOf(setOf<String>())
    }

    var defeatedMonsters by remember {
        mutableStateOf(setOf<String>())
    }

    var message by remember {
        mutableStateOf(
            "مرحباً بك في العالم الخيالي. أنا ميار، وسأرافقك في رحلتك بين السحر والتنانين."
        )
    }

    fun addExperience(amount: Int) {
        xp += amount

        while (xp >= 100) {
            xp -= 100
            level += 1
            SystemAudioEvents.levelUp()
            message = "ارتقيت إلى المستوى $level!"
        }
    }

    val currentZone = SystemFantasyWorldData.zones
        .first { it.id == selectedZone }

    val availableQuests = SystemFantasyWorldData.quests
        .filter { level >= it.requiredLevel }

    val availableMonsters = SystemFantasyWorldData.monsters
        .filter { level >= it.level }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFF100B20),
                        Color(0xFF17112B),
                        Color(0xFF080A16)
                    )
                )
            )
            .padding(horizontal = 14.dp),
        verticalArrangement = Arrangement.spacedBy(13.dp),
        contentPadding = PaddingValues(
            top = 12.dp,
            bottom = 30.dp
        )
    ) {
        item {
            Button(
                onClick = onBack,
                colors = ButtonDefaults.buttonColors(
                    containerColor = panel
                )
            ) {
                Text("العودة إلى العوالم")
            }
        }

        item {
            Column {
                Text(
                    "SYSTEM WORLD",
                    color = cyan,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    "العالم الخيالي",
                    color = Color.White,
                    fontSize = 29.sp,
                    fontWeight = FontWeight.Black
                )

                Text(
                    "ممالك السحر والتنانين والنقابات",
                    color = purple,
                    fontSize = 14.sp
                )
            }
        }

        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        1.dp,
                        purple.copy(alpha = 0.5f),
                        RoundedCornerShape(20.dp)
                    ),
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                shape = RoundedCornerShape(20.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(9.dp)
                ) {
                    Text(
                        "ملف المقاتل",
                        color = gold,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        "المستوى: $level",
                        color = Color.White,
                        fontSize = 18.sp
                    )

                    LinearProgressIndicator(
                        progress = { xp / 100f },
                        modifier = Modifier.fillMaxWidth(),
                        color = cyan,
                        trackColor = Color.DarkGray
                    )

                    Text(
                        "$xp / 100 XP",
                        color = cyan
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("العملات: $coins", color = gold)
                        Text("الصحة: $health / 100", color = Color(0xFFFF7777))
                    }
                }
            }
        }

        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = Color(0xFF211831)
                ),
                shape = RoundedCornerShape(18.dp)
            ) {
                Row(
                    modifier = Modifier.padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "م",
                        color = purple,
                        fontSize = 38.sp,
                        fontWeight = FontWeight.Black
                    )

                    Spacer(Modifier.width(12.dp))

                    Column {
                        Text(
                            "ميار | مرشدتك السحرية",
                            color = purple,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            message,
                            color = Color.White,
                            fontSize = 13.sp
                        )
                    }
                }
            }
        }

        item {
            Text(
                "ممالك العالم",
                color = gold,
                fontSize = 21.sp,
                fontWeight = FontWeight.Bold
            )
        }

        items(
            SystemFantasyWorldData.zones,
            key = { it.id }
        ) { zone ->
            val unlocked = level >= zone.requiredLevel
            val selected = selectedZone == zone.id

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        1.dp,
                        if (selected) purple
                        else purple.copy(alpha = 0.2f),
                        RoundedCornerShape(17.dp)
                    )
                    .clickable(
                        enabled = unlocked
                    ) {
                        selectedZone = zone.id
                        message = "وصلنا إلى ${zone.name}. ${zone.description}"
                        SystemAudioEvents.discovery()
                    },
                colors = CardDefaults.cardColors(
                    containerColor = if (selected)
                        Color(0xFF38234D)
                    else
                        panel
                ),
                shape = RoundedCornerShape(17.dp)
            ) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(5.dp)
                ) {
                    Text(
                        zone.name,
                        color = if (unlocked) purple else Color.Gray,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        zone.description,
                        color = Color.LightGray,
                        fontSize = 13.sp
                    )

                    Text(
                        if (unlocked) {
                            if (selected) "أنت داخل هذه المنطقة"
                            else "اضغط للاستكشاف"
                        } else {
                            "مغلقة - المستوى ${zone.requiredLevel} مطلوب"
                        },
                        color = if (unlocked) cyan else Color.Gray,
                        fontSize = 12.sp
                    )
                }
            }
        }

        item {
            Text(
                "مهام المنطقة",
                color = gold,
                fontSize = 21.sp,
                fontWeight = FontWeight.Bold
            )

            Text(
                "المهام المتاحة في هذه المرحلة من رحلتك",
                color = Color.LightGray,
                fontSize = 12.sp
            )
        }

        items(
            availableQuests.filter { quest ->
                when (currentZone.id) {
                    "whisper_forest" ->
                        quest.id == "first_magic" ||
                        quest.id == "forest_secret"

                    "dragon_mountains" ->
                        quest.id == "dragon_egg"

                    "crystal_kingdom" ->
                        quest.id == "crystal_power"

                    "shadow_dungeon" ->
                        quest.id == "shadow_trial"

                    "sky_citadel" ->
                        quest.id == "sky_secret"

                    "dragon_throne" ->
                        quest.id == "eternal_dragon"

                    else -> false
                }
            },
            key = { it.id }
        ) { quest ->
            val completed = quest.id in completedQuests

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(7.dp)
                ) {
                    Text(
                        quest.title,
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 17.sp
                    )

                    Text(
                        quest.description,
                        color = Color.LightGray,
                        fontSize = 13.sp
                    )

                    Text(
                        "+${quest.xpReward} XP  |  +${quest.coinReward} عملة",
                        color = cyan
                    )

                    Button(
                        onClick = {
                            if (quest.id !in completedQuests) {
                                completedQuests =
                                    completedQuests + quest.id

                                coins += quest.coinReward
                                addExperience(quest.xpReward)

                                SystemAudioEvents.questCompleted()

                                message =
                                    "أحسنت! أكملت ${quest.title}."
                            }
                        },
                        enabled = !completed,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = purple,
                            contentColor = Color.Black
                        )
                    ) {
                        Text(
                            if (completed) "مكتملة"
                            else "إنجاز المهمة"
                        )
                    }
                }
            }
        }

        item {
            Text(
                "وحوش وكائنات العالم",
                color = gold,
                fontSize = 21.sp,
                fontWeight = FontWeight.Bold
            )
        }

        items(
            availableMonsters.filter { monster ->
                when (currentZone.id) {
                    "whisper_forest" ->
                        monster.id == "forest_wolf" ||
                        monster.id == "shadow_goblin"

                    "dragon_mountains" ->
                        monster.id == "fire_drake"

                    "crystal_kingdom" ->
                        monster.id == "crystal_guardian"

                    "shadow_dungeon" ->
                        monster.id == "abyss_knight"

                    "sky_citadel" ->
                        monster.id == "sky_dragon"

                    "dragon_throne" ->
                        monster.id == "eternal_dragon_boss"

                    else -> false
                }
            },
            key = { it.id }
        ) { monster ->
            val defeated = monster.id in defeatedMonsters

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (monster.isBoss)
                        Color(0xFF351A2B)
                    else
                        panel
                ),
                shape = RoundedCornerShape(17.dp)
            ) {
                Column(
                    modifier = Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(7.dp)
                ) {
                    Text(
                        if (monster.isBoss) "زعيم أسطوري"
                        else "مخلوق معادٍ",
                        color = if (monster.isBoss)
                            Color(0xFFFF7777)
                        else purple,
                        fontSize = 12.sp
                    )

                    Text(
                        monster.name,
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        monster.description,
                        color = Color.LightGray
                    )

                    Text(
                        "المستوى ${monster.level} | قوة الوحش ${monster.power}",
                        color = cyan
                    )

                    Text(
                        "المكافأة: ${monster.xpReward} XP و ${monster.coinReward} عملة",
                        color = gold
                    )

                    Button(
                        onClick = {
                            val playerPower = level * 25 + xp / 4

                            if (playerPower >= monster.power) {
                                defeatedMonsters =
                                    defeatedMonsters + monster.id

                                coins += monster.coinReward
                                addExperience(monster.xpReward)

                                SystemAudioEvents.combatVictory()

                                message =
                                    "انتصرت على ${monster.name}! حصلت على المكافأة."
                            } else {
                                health = (health - 25).coerceAtLeast(0)

                                SystemAudioEvents.combatDefeat()

                                message =
                                    "لم تتمكن من هزيمة ${monster.name}. تحتاج إلى تطوير قوتك."

                                if (health == 0) {
                                    message += " صحتك وصلت للصفر، تحتاج إلى العلاج."
                                }
                            }
                        },
                        enabled = !defeated && health > 0,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (monster.isBoss)
                                Color(0xFFB83B58)
                            else
                                purple,
                            contentColor = Color.White
                        )
                    ) {
                        Text(
                            if (defeated) "تمت هزيمته"
                            else "ابدأ المعركة"
                        )
                    }
                }
            }
        }

        item {
            Button(
                onClick = {
                    health = 100
                    SystemAudioEvents.healing()
                    message = "تمت استعادة صحتك في نقطة العلاج."
                },
                enabled = health < 100,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF287C69)
                )
            ) {
                Text("استعادة الصحة")
            }
        }

        item {
            Text(
                "رحلتك في هذا العالم مستمرة...",
                color = purple,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
