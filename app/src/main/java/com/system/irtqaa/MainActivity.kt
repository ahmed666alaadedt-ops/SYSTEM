package com.system.irtqaa

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontWeight
import java.time.LocalDate

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            SystemApp()
        }
    }
}

@Composable
fun SystemApp() {

    val context = LocalContext.current.applicationContext
    val userId = "system_local_player"
    val today = LocalDate.now()

    val progressEngine = remember(context) {
        SystemProgressEngine(context)
    }

    val taskManager = remember(context) {
        SystemTaskManager(
            context = context,
            userId = userId,
            progressEngine = progressEngine
        )
    }

    var tasks by remember(taskManager, today) {
        val generatedTasks =
            SystemTaskCatalog.buildDailyTasks(today)

        generatedTasks.forEach { task ->
            if (taskManager.getTask(task.taskId) == null) {
                taskManager.addTask(task)
            }
        }

        mutableStateOf(
            taskManager.getTasks().filter {
                it.taskId.startsWith("system_${today}_")
            }
        )
    }

    var progressSnapshot by remember(progressEngine, userId) {
        mutableStateOf(
            progressEngine.getProgress(userId)
        )
    }

    var selectedTab by remember {
        mutableIntStateOf(0)
    }

    var worldProgress by remember {
        mutableStateOf(PlayerWorldProgress())
    }

    val completedCount = tasks.count {
        it.isCompleted
    }

    val totalExperience = progressSnapshot.totalExperience

    val panel = Color(0xFF131D30)
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    SystemHologramBackground(
        modifier = Modifier.fillMaxSize()
    ) {

        SystemTheme {

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
                            "LV. ${progressSnapshot.overallLevel}",
                            color = gold,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            "$totalExperience XP",
                            color = cyan
                        )

                        LinearProgressIndicator(
                            progress = {
                                (totalExperience % 100) / 100f
                            },
                            modifier = Modifier.fillMaxWidth(),
                            color = gold
                        )
                    }
                }

                Spacer(Modifier.height(20.dp))

                Row(
                    modifier = Modifier.horizontalScroll(
                        rememberScrollState()
                    ),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {

                    val tabs = listOf(
                        "الرئيسية",
                        "المهام",
                        "المستويات",
                        "العالم الافتراضي"
                    )

                    tabs.forEachIndexed { index, title ->

                        Button(
                            onClick = {
                                selectedTab = index
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor =
                                    if (selectedTab == index) gold
                                    else panel,
                                contentColor =
                                    if (selectedTab == index)
                                        Color.Black
                                    else
                                        Color.White
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
                            "إنجازات اليوم: $completedCount / ${tasks.size}",
                            color = cyan
                        )

                        Text(
                            "مجموع الخبرة: $totalExperience XP",
                            color = gold
                        )

                        Text(
                            "المهام المكتملة محفوظة في النظام",
                            color = Color.LightGray
                        )
                    }

                    1 -> {

                        Text(
                            "المهام اليومية",
                            color = gold,
                            fontSize = 22.sp
                        )

                        Spacer(Modifier.height(10.dp))

                        LazyColumn(
                            verticalArrangement =
                                Arrangement.spacedBy(10.dp)
                        ) {

                            items(
                                items = tasks,
                                key = { it.taskId }
                            ) { task ->

                                Card(
                                    colors = CardDefaults.cardColors(
                                        containerColor =
                                            panel.copy(alpha = 0.92f)
                                    )
                                ) {

                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(12.dp),
                                        verticalAlignment =
                                            Alignment.CenterVertically
                                    ) {

                                        Column(
                                            Modifier.weight(1f)
                                        ) {

                                            Text(
                                                task.title,
                                                color = Color.White
                                            )

                                            Text(
                                                domainLabel(task.domain),
                                                color = cyan
                                            )

                                            if (task.description.isNotBlank()) {
                                                Text(
                                                    task.description,
                                                    color = Color.LightGray,
                                                    fontSize = 12.sp
                                                )
                                            }

                                            Text(
                                                "+${task.experienceReward} XP",
                                                color = gold
                                            )
                                        }

                                        Checkbox(
                                            checked = task.isCompleted,
                                            enabled =
                                                task.status !=
                                                    SystemTaskStatus.COMPLETED &&
                                                task.status !=
                                                    SystemTaskStatus.CANCELLED,
                                            onCheckedChange = { checked ->

                                                if (checked) {

                                                    taskManager.completeTask(
                                                        task.taskId
                                                    )

                                                    tasks =
                                                        taskManager.getTasks()
                                                            .filter {
                                                                it.taskId.startsWith(
                                                                    "system_${today}_"
                                                                )
                                                            }

                                                    progressSnapshot =
                                                        progressEngine.getProgress(
                                                            userId
                                                        )
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

                        Spacer(Modifier.height(10.dp))

                        LazyColumn(
                            verticalArrangement =
                                Arrangement.spacedBy(10.dp)
                        ) {

                            items(
                                progressSnapshot.domains,
                                key = { it.domain.name }
                            ) { domainProgress ->

                                Card(
                                    colors = CardDefaults.cardColors(
                                        containerColor =
                                            panel.copy(alpha = 0.92f)
                                    )
                                ) {

                                    Column(
                                        Modifier.padding(16.dp)
                                    ) {

                                        Text(
                                            domainLabel(domainProgress.domain),
                                            color = Color.White,
                                            fontSize = 19.sp
                                        )

                                        Text(
                                            "المستوى ${domainProgress.level}",
                                            color = gold
                                        )

                                        Text(
                                            "${domainProgress.experience} XP",
                                            color = cyan
                                        )

                                        Text(
                                            "المهام المكتملة: ${domainProgress.completedTasks}",
                                            color = Color.LightGray
                                        )

                                        LinearProgressIndicator(
                                            progress = {
                                                (domainProgress.experience % 100) /
                                                    100f
                                            },
                                            modifier =
                                                Modifier.fillMaxWidth(),
                                            color = gold
                                        )
                                    }
                                }
                            }
                        }
                    }

                    3 -> {

                        SystemWorldScreen(
                            progress = worldProgress,
                            onProgressChange = {
                                worldProgress = it
                            }
                        )
                    }
                }
            }
        }
    }
}

private fun domainLabel(
    domain: SystemDevelopmentDomain
): String {

    return when (domain) {
        SystemDevelopmentDomain.SPIRIT -> "الروح"
        SystemDevelopmentDomain.MIND -> "العقل"
        SystemDevelopmentDomain.BODY -> "الجسد"
        SystemDevelopmentDomain.AWARENESS -> "الوعي"
        SystemDevelopmentDomain.DISCIPLINE -> "الانضباط"
    }
}
