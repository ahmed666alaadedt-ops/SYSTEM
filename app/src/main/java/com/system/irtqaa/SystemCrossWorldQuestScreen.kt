
package com.system.irtqaa

import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private fun loadArtifactProgress(
    context: Context,
    playerId: String
): SystemPlayerQuestProgress {
    val prefs = context.getSharedPreferences(
        "system_world_quest_${playerId.hashCode()}",
        Context.MODE_PRIVATE
    )

    return SystemPlayerQuestProgress(
        playerId = playerId,
        chainId = SystemWorldQuestNetwork.artifactQuest.id,
        completedStageIds = prefs.getStringSet(
            "completed",
            emptySet()
        )?.toSet() ?: emptySet(),
        discoveredClues = prefs.getStringSet(
            "clues",
            emptySet()
        )?.toSet() ?: emptySet(),
        artifactFound = prefs.getBoolean("artifact_found", false),
        islandAccessUnlocked = prefs.getBoolean("island_unlocked", false)
    )
}

private fun saveArtifactProgress(
    context: Context,
    progress: SystemPlayerQuestProgress
) {
    val prefs = context.getSharedPreferences(
        "system_world_quest_${progress.playerId.hashCode()}",
        Context.MODE_PRIVATE
    )

    prefs.edit()
        .putStringSet("completed", progress.completedStageIds)
        .putStringSet("clues", progress.discoveredClues)
        .putBoolean("artifact_found", progress.artifactFound)
        .putBoolean("island_unlocked", progress.islandAccessUnlocked)
        .apply()
}

@Composable
fun SystemCrossWorldQuestScreen(
    playerId: String,
    onBack: () -> Unit
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF55DDF0)
    val purple = Color(0xFFB58CFF)
    val panel = Color(0xFF171C30)

    var progress by remember(playerId) {
        mutableStateOf(
            loadArtifactProgress(context, playerId)
        )
    }

    var message by remember {
        mutableStateOf(
            "ابدأ البحث عن قطعة العوالم الأزلية. الأدلة موزعة بين العوالم."
        )
    }

    val chain = SystemWorldQuestNetwork.artifactQuest
    val nextStage = SystemWorldQuestNetwork.getNextStage(progress)
    val stages = chain.stages

    fun updateProgress(updated: SystemPlayerQuestProgress) {
        progress = updated
        saveArtifactProgress(context, updated)
    }

    fun registerCurrentClue(stage: SystemWorldQuestStage) {
        if (stage.id == "artifact_discovery" &&
            !SystemWorldQuestNetwork.hasAllArtifactClues(progress)
        ) {
            message = "يجب جمع أدلة العالم الحديث والتاريخي والخيالي أولاً."
            return
        }

        val updated = SystemWorldQuestNetwork.discoverClue(
            progress,
            stage.requiredClue
        )

        updateProgress(updated)
        message = "تم تسجيل الدليل: ${stage.title}"
    }

    fun finishCurrentStage(stage: SystemWorldQuestStage) {
        var updated = SystemWorldQuestNetwork.completeStage(
            progress,
            stage.id
        )

        if (updated == progress) {
            message = "لم تكتمل شروط هذه المرحلة بعد."
            return
        }

        if (stage.id == "artifact_discovery") {
            updated = SystemWorldQuestNetwork.discoverClue(
                updated,
                "greed_island_access"
            )
        }

        updateProgress(updated)

        message = when (stage.id) {
            "artifact_discovery" ->
                "اكتشفت قطعة العوالم الأزلية! أصبح طريق جزيرة الطمع متاحاً بعد إكمال شرط البوابة."

            "greed_island_entry" ->
                "اكتملت سلسلة البحث وفتح الوصول إلى جزيرة الطمع."

            else ->
                "أحسنت! أكملت مرحلة ${stage.title}."
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFF080D1B),
                        Color(0xFF17142D),
                        Color(0xFF080D1B)
                    )
                )
            )
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Button(
            onClick = onBack,
            colors = ButtonDefaults.buttonColors(
                containerColor = panel
            )
        ) {
            Text("العودة")
        }

        Text(
            "SYSTEM WORLD",
            color = cyan,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )

        Text(
            "المهمات العابرة للعوالم",
            color = Color.White,
            fontSize = 25.sp,
            fontWeight = FontWeight.Black
        )

        Card(
            colors = CardDefaults.cardColors(
                containerColor = panel
            ),
            shape = RoundedCornerShape(20.dp)
        ) {
            Column(
                Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(9.dp)
            ) {
                Text(
                    "البحث العالمي عن القطعة النادرة",
                    color = gold,
                    fontSize = 19.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    "قطعة العوالم الأزلية",
                    color = Color.White,
                    fontSize = 23.sp,
                    fontWeight = FontWeight.Black
                )

                Text(
                    "يشارك اللاعبون في البحث عن القطعة عبر العوالم. لكل لاعب تقدم وأدلة محفوظة في حسابه.",
                    color = Color.LightGray
                )

                Text(
                    "الأدلة المسجلة: ${progress.discoveredClues.size} / 4",
                    color = cyan
                )

                LinearProgressIndicator(
                    progress = {
                        (progress.discoveredClues.size / 4f)
                            .coerceIn(0f, 1f)
                    },
                    modifier = Modifier.fillMaxWidth(),
                    color = gold
                )

                if (progress.artifactFound) {
                    Text(
                        "تم اكتشاف القطعة النادرة",
                        color = gold,
                        fontWeight = FontWeight.Bold
                    )
                }

                if (SystemWorldQuestNetwork.canEnterGreedIsland(progress)) {
                    Text(
                        "تم فتح الوصول إلى جزيرة الطمع",
                        color = cyan,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        Text(
            "مراحل البحث",
            color = gold,
            fontSize = 21.sp,
            fontWeight = FontWeight.Bold
        )

        stages.forEachIndexed { index, stage ->
            val isCurrent = nextStage?.id == stage.id
            val completed = stage.id in progress.completedStageIds
            val clueFound = stage.requiredClue in progress.discoveredClues

            val canDiscover = when (stage.id) {
                "artifact_discovery" ->
                    SystemWorldQuestNetwork.hasAllArtifactClues(progress)

                else -> true
            }

            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                ),
                shape = RoundedCornerShape(17.dp)
            ) {
                Column(
                    Modifier.padding(14.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        "المرحلة ${index + 1}",
                        color = purple,
                        fontSize = 12.sp
                    )

                    Text(
                        stage.title,
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        stage.description,
                        color = Color.LightGray,
                        fontSize = 13.sp
                    )

                    Text(
                        "العالم: ${when (stage.worldId) {
                            "real" -> "العالم الحديث"
                            "mythology" -> "العالم التاريخي"
                            "fantasy" -> "العالم الخيالي"
                            "greed" -> "جزيرة الطمع"
                            else -> stage.worldId
                        }}",
                        color = cyan
                    )

                    Text(
                        when {
                            completed -> "مكتملة"
                            clueFound -> "تم تسجيل الدليل"
                            isCurrent -> "المرحلة الحالية"
                            else -> "بانتظار المراحل السابقة"
                        },
                        color = when {
                            completed -> Color(0xFF65D6A5)
                            isCurrent -> gold
                            else -> Color.Gray
                        }
                    )

                    if (isCurrent && !completed) {
                        if (!clueFound) {
                            OutlinedButton(
                                onClick = {
                                    registerCurrentClue(stage)
                                },
                                enabled = canDiscover,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    if (canDiscover)
                                        "تسجيل العثور على الدليل"
                                    else
                                        "اجمع الأدلة الثلاثة أولاً"
                                )
                            }
                        } else {
                            Button(
                                onClick = {
                                    finishCurrentStage(stage)
                                },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = gold,
                                    contentColor = Color.Black
                                )
                            ) {
                                Text("إكمال المرحلة")
                            }
                        }
                    }
                }
            }
        }

        Card(
            colors = CardDefaults.cardColors(
                containerColor = Color(0xFF20213B)
            ),
            shape = RoundedCornerShape(15.dp)
        ) {
            Text(
                message,
                color = Color.White,
                modifier = Modifier.padding(14.dp)
            )
        }

        Text(
            "قصص أخرى قادمة",
            color = gold,
            fontSize = 19.sp,
            fontWeight = FontWeight.Bold
        )

        SystemWorldQuestNetwork.crossWorldStories.forEach { story ->
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = panel
                )
            ) {
                Column(Modifier.padding(13.dp)) {
                    Text(
                        story.title,
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        story.description,
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}
