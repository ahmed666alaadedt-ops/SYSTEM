package com.system.irtqaa

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            SystemStartupGate {
                SystemAccountGate { account ->
                    SystemApp(account)
                }
            }
        }
    }
}

@Composable
fun SystemApp(account: SystemFirebaseAccount) {
    val context = LocalContext.current.applicationContext
    val userId = account.userId
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
        val generatedTasks = SystemTaskCatalog.buildDailyTasks(today)

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
        mutableStateOf(progressEngine.getProgress(userId))
    }

    var selectedTab by remember {
        mutableIntStateOf(0)
    }

    var worldProgress by remember {
        mutableStateOf(PlayerWorldProgress())
    }

    var showWorldSelection by remember {
        mutableStateOf(false)
    }

    var selectedWorld by remember {
        mutableStateOf("")
    }

    var miyarDialog by remember {
        mutableStateOf<String?>(null)
    }

    val completedCount = tasks.count { it.isCompleted }
    val totalExperience = progressSnapshot.totalExperience

    val activeStyle = when (selectedWorld) {
        "real" -> SystemWorldVisualStyles.modern
        "mythology" -> SystemWorldVisualStyles.mythology
        "fantasy" -> SystemWorldVisualStyles.fantasy
        "greed" -> SystemWorldVisualStyles.greedIsland
        else -> null
    }

    val panel = activeStyle?.surface ?: Color(0xFF131D30)
    val gold = activeStyle?.accent ?: Color(0xFFFFC857)
    val cyan = activeStyle?.secondary ?: Color(0xFF45D6E8)

    SystemWorldAudioHost(
        selectedWorld = selectedWorld,
        selectedTab = selectedTab
    )

    SystemHologramBackground(
        modifier = Modifier.fillMaxSize()
    ) {
        SystemTheme {
            Box(modifier = Modifier.fillMaxSize()) {

                // الواجهة الأفقية الرئيسية
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(12.dp)
                ) {

                    if (
                        (selectedTab != 0 && selectedTab != 3) ||
                        (selectedTab == 0 &&
                            (showWorldSelection || selectedWorld.isBlank()))
                    ) {
                        // اللوحة الجانبية الثابتة
                        Column(
                            modifier = Modifier
                                .width(260.dp)
                                .fillMaxHeight()
                                .verticalScroll(rememberScrollState())
                                .padding(end = 12.dp)
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

                            Spacer(Modifier.height(16.dp))

                            Card(
                                colors = CardDefaults.cardColors(
                                    containerColor = panel.copy(alpha = 0.92f)
                                ),
                                shape = RoundedCornerShape(18.dp)
                            ) {
                                Column(Modifier.padding(16.dp)) {
                                    Text("المستوى العام", color = Color.White)

                                    Text(
                                        "LV. ${progressSnapshot.overallLevel}",
                                        color = gold,
                                        fontSize = 28.sp,
                                        fontWeight = FontWeight.Bold
                                    )

                                    Text("$totalExperience XP", color = cyan)

                                    LinearProgressIndicator(
                                        progress = {
                                            (totalExperience % 100) / 100f
                                        },
                                        modifier = Modifier.fillMaxWidth(),
                                        color = gold
                                    )
                                }
                            }

                            Spacer(Modifier.height(16.dp))

                            // أزرار التنقل العمودية
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                val tabs = listOf(
                                    "الرئيسية",
                                    "المهام",
                                    "المستويات",
                                    "جزيرة الطمع",
                                    "المهمات العالمية"
                                )

                                tabs.forEachIndexed { index, title ->
                                    Button(
                                        onClick = {
                                            selectedTab = index
                                            showWorldSelection = false
                                            if (index != 0) selectedWorld = ""
                                        },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor =
                                                if (selectedTab == index) gold else panel,
                                            contentColor =
                                                if (selectedTab == index)
                                                    Color.Black
                                                else
                                                    Color.White
                                        ),
                                        modifier = Modifier.fillMaxWidth(),
                                        shape = RoundedCornerShape(12.dp)
                                    ) {
                                        Text(title, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }

                            Spacer(Modifier.height(16.dp))
                        }

                    }

                    // مساحة المحتوى الرئيسية
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .padding(start = 8.dp)
                    ) {
                        when (selectedTab) {

                            0 -> {
                                if (showWorldSelection) {
                                    WorldSelectionScreen(
                                        onBack = {
                                            showWorldSelection = false
                                        },
                                        onSelectWorld = { world ->
                                            selectedWorld = world
                                            showWorldSelection = false
                                        }
                                    )
                                } else if (selectedWorld == "mythology") {
                                    SystemHistoricalWorldScreen(
                                        onBack = {
                                            selectedWorld = ""
                                            showWorldSelection = true
                                        }
                                    )
                                } else if (selectedWorld == "real") {
                                    Column {
                                        Button(
                                            onClick = {
                                                selectedWorld = ""
                                                showWorldSelection = true
                                            }
                                        ) {
                                            Text("العودة إلى العوالم")
                                        }

                                        SystemWorldScreen(
                                            progress = worldProgress,
                                            onProgressChange = {
                                                worldProgress = it
                                            }
                                        )
                                    }
                                } else if (selectedWorld == "fantasy") {
                                    SystemFantasyWorldScreen(
                                        onBack = {
                                            selectedWorld = ""
                                            showWorldSelection = true
                                        }
                                    )
                                } else if (selectedWorld == "greed") {
                                    SystemGreedIslandScreen(
                                        playerId = userId,
                                        playerLevel = progressSnapshot.overallLevel,
                                        onBack = {
                                            selectedWorld = ""
                                            showWorldSelection = true
                                        }
                                    )
                                } else {
                                    Column(
                                        modifier = Modifier.fillMaxWidth()
                                    ) {
                                        SystemMiyarWelcomeCard(
                                            onExplainClick = {
                                                miyarDialog = "explain"
                                            },
                                            onTalkClick = {
                                                miyarDialog = "chat"
                                            }
                                        )

                                        Spacer(Modifier.height(18.dp))

                                        Text(
                                            "مرحباً بك أيها المقاتل",
                                            color = Color.White,
                                            fontSize = 21.sp,
                                            fontWeight = FontWeight.Bold
                                        )

                                        Spacer(Modifier.height(8.dp))

                                        Text(
                                            "إنجازات اليوم: $completedCount / ${tasks.size}",
                                            color = cyan
                                        )

                                        Text(
                                            "مجموع الخبرة: $totalExperience XP",
                                            color = gold
                                        )

                                        Spacer(Modifier.height(18.dp))

                                        Text(
                                            "عوالم SYSTEM",
                                            color = gold,
                                            fontSize = 20.sp,
                                            fontWeight = FontWeight.Bold
                                        )

                                        Spacer(Modifier.height(10.dp))

                                        SystemWorldBanner(
                                            onClick = {
                                                showWorldSelection = true
                                            }
                                        )
                                    }
                                }
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
                                                    modifier = Modifier.fillMaxWidth(),
                                                    color = gold
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            3 -> {
                                SystemGreedIslandScreen(
                                    playerId = userId,
                                    playerLevel = progressSnapshot.overallLevel,
                                    onBack = {
                                        selectedTab = 0
                                        selectedWorld = ""
                                        showWorldSelection = true
                                    }
                                )
                            }

                            4 -> {
                                SystemCrossWorldQuestScreen(
                                    playerId = userId,
                                    onBack = { selectedTab = 0 }
                                )
                            }
                        }
                    }
                }

                if (miyarDialog != null) {
                    val dialogTitle =
                        if (miyarDialog == "explain") {
                            "مرحباً، أنا ميار"
                        } else {
                            "التحدث مع ميار"
                        }

                    val dialogMessage =
                        if (miyarDialog == "explain") {
                            "أنا مرشدتك داخل SYSTEM. سأساعدك على فهم نظام التطور، والمهام، والمستويات، والعوالم، وكيفية استخدام التطبيق. سيتم توسيع الشرح وربطه بأقسام النظام تباعاً."
                        } else {
                            "واجهة المحادثة مع ميار ضمن مراحل التطوير. سيجري ربط المحادثة النصية والصوتية عندما تكتمل مكوناتها."
                        }

                    AlertDialog(
                        onDismissRequest = {
                            miyarDialog = null
                        },
                        title = {
                            Text(
                                dialogTitle,
                                color = gold,
                                fontWeight = FontWeight.Bold
                            )
                        },
                        text = {
                            Text(dialogMessage, color = Color.White)
                        },
                        confirmButton = {
                            TextButton(
                                onClick = {
                                    miyarDialog = null
                                }
                            ) {
                                Text("حسناً", color = cyan)
                            }
                        },
                        containerColor = Color(0xFF131D30)
                    )
                }
            }
        }
    }
}

// بطاقة العالم الافتراضي مع الكرة الأرضية المتحركة
@Composable
fun SystemWorldBanner(onClick: () -> Unit) {
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(205.dp)
            .clickable(onClick = onClick)
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color(0xFF101B35),
                        Color(0xFF163C59),
                        Color(0xFF241B43)
                    )
                ),
                shape = RoundedCornerShape(22.dp)
            )
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            drawCircle(
                color = cyan.copy(alpha = 0.13f),
                radius = size.minDimension * 0.42f,
                center = Offset(size.width * 0.78f, size.height * 0.43f)
            )

            drawCircle(
                color = gold.copy(alpha = 0.12f),
                radius = size.minDimension * 0.27f,
                center = Offset(size.width * 0.83f, size.height * 0.44f)
            )

            drawCircle(
                color = cyan.copy(alpha = 0.30f),
                radius = 5.dp.toPx(),
                center = Offset(size.width * 0.15f, size.height * 0.22f)
            )

            drawCircle(
                color = gold.copy(alpha = 0.35f),
                radius = 4.dp.toPx(),
                center = Offset(size.width * 0.55f, size.height * 0.75f)
            )
        }

        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    "SYSTEM WORLD",
                    color = gold,
                    fontSize = 23.sp,
                    fontWeight = FontWeight.Black
                )

                Spacer(Modifier.height(8.dp))

                Text(
                    "العالم الافتراضي",
                    color = Color.White,
                    fontSize = 21.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(Modifier.height(8.dp))

                Text(
                    "اكتشف عوالم جديدة وابدأ رحلتك.",
                    color = Color.LightGray,
                    fontSize = 13.sp
                )

                Spacer(Modifier.height(12.dp))

                Text(
                    "اضغط للدخول  ←",
                    color = cyan,
                    fontWeight = FontWeight.Bold
                )
            }

            SystemAnimatedGlobe(
                modifier = Modifier.padding(start = 4.dp),
                globeSize = 112.dp
            )
        }
    }
}

@Composable
fun WorldSelectionScreen(
    onBack: () -> Unit,
    onSelectWorld: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(bottom = 18.dp)
    ) {
        Button(onClick = onBack) {
            Text("رجوع")
        }

        Spacer(Modifier.height(10.dp))

        SystemNestedWorldHub(
            onWorldSelected = { world ->
                val destination = when (world) {
                    SystemWorldKind.MODERN_REALISTIC -> "real"
                    SystemWorldKind.MYTHOLOGY_HISTORY -> "mythology"
                    SystemWorldKind.FANTASY -> "fantasy"
                    SystemWorldKind.GREED_ISLAND -> "greed"
                }

                onSelectWorld(destination)
            }
        )
    }
}

@Composable
fun WorldComingSoonScreen(
    worldName: String,
    onBack: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Button(onClick = onBack) {
            Text("العودة إلى العوالم")
        }

        Spacer(Modifier.height(30.dp))

        Text(
            worldName,
            color = Color(0xFFFFC857),
            fontSize = 25.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(Modifier.height(15.dp))

        Text(
            "هذا العالم ضمن خطة SYSTEM، وتجري تهيئة أنظمته بصورة مستقلة.",
            color = Color.White,
            fontSize = 15.sp
        )

        Spacer(Modifier.height(10.dp))

        Text(
            "سيتم تطويره وربطه بمحتواه الخاص في مرحلة لاحقة.",
            color = Color.LightGray,
            fontSize = 13.sp
        )
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

@Composable
fun SystemGreedIslandScreen(
    playerId: String,
    playerLevel: Int,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val prefs = remember(playerId) {
        context.getSharedPreferences(
            "system_world_quest_${playerId.hashCode()}",
            android.content.Context.MODE_PRIVATE
        )
    }
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF55DDF0)
    val panel = Color(0xFF171C30)
    var selectedRegionId by remember {
        mutableStateOf(SystemGreedIslandData.regions.first().id)
    }
    val progress = remember(playerId) {
        SystemPlayerQuestProgress(
            playerId = playerId,
            chainId = SystemWorldQuestNetwork.artifactQuest.id,
            completedStageIds = prefs.getStringSet("completed", emptySet())?.toSet() ?: emptySet(),
            discoveredClues = prefs.getStringSet("clues", emptySet())?.toSet() ?: emptySet(),
            artifactFound = prefs.getBoolean("artifact_found", false),
            islandAccessUnlocked = prefs.getBoolean("island_unlocked", false)
        )
    }
    val accessReady = SystemWorldQuestNetwork.canEnterGreedIsland(progress)
    val region = SystemGreedIslandData.regions.first { it.id == selectedRegionId }
    val quests = SystemGreedIslandData.quests.filter { it.regionId == selectedRegionId }

    Column(
        Modifier.fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color(0xFF080D1B), Color(0xFF17142D), Color(0xFF080D1B))))
            .verticalScroll(rememberScrollState())
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Button(onClick = onBack, colors = ButtonDefaults.buttonColors(containerColor = panel)) {
            Text("رجوع")
        }
        Text("SYSTEM WORLD • SEASON", color = cyan, fontSize = 13.sp, fontWeight = FontWeight.Bold)
        Text("جزيرة الطمع", color = gold, fontSize = 29.sp, fontWeight = FontWeight.Black)
        Text("جزيرة عائمة تضم مناطق الاستكشاف والأسرار والبطاقات والمهمات الموسمية.", color = Color.LightGray)

        Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = panel)) {
            Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                Text(SystemGreedIslandData.SEASON_NAME, color = gold, fontWeight = FontWeight.Bold, fontSize = 19.sp)
                Text("مستواك: $playerLevel  •  المطلوب: ${SystemGreedIslandData.ENTRY_LEVEL}", color = cyan)
                Text(
                    when {
                        playerLevel < SystemGreedIslandData.ENTRY_LEVEL -> "ارفع مستواك أولاً لتحقيق شرط المستوى."
                        !accessReady -> "اجمع أدلة العوالم الثلاثة واكتشف القطعة النادرة من تبويب المهمات العالمية."
                        else -> "اكتملت متطلبات القطعة. دخول الموسم الفعلي ينتظر تفعيل الموسم."
                    },
                    color = Color.White
                )
                Text(
                    if (accessReady) "شرط القطعة مكتمل" else "الوصول لم يُفتح بعد",
                    color = if (accessReady) gold else Color(0xFFFF8A80)
                )
            }
        }

        Text("مناطق الجزيرة", color = gold, fontSize = 20.sp, fontWeight = FontWeight.Bold)

        SystemGreedIslandData.regions.forEach { item ->
            val isStartArea = item.isUnlocked &&
                playerLevel >= SystemGreedIslandData.ENTRY_LEVEL

            Card(
                Modifier.fillMaxWidth().clickable {
                    selectedRegionId = item.id
                    SystemAudioEvents.discovery()
                },
                colors = CardDefaults.cardColors(
                    containerColor = if (item.id == selectedRegionId)
                        Color(0xFF26334D) else panel
                )
            ) {
                Column(
                    Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            item.name,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f)
                        )
                        Text(
                            if (isStartArea) "منطقة بداية" else "مقفلة",
                            color = if (isStartArea) cyan else Color.Gray,
                            fontSize = 11.sp
                        )
                    }
                    Text(item.description, color = Color.LightGray, fontSize = 12.sp)
                    Text(
                        "الخطورة ${item.dangerLevel}/10 • ${item.reward} XP",
                        color = gold,
                        fontSize = 12.sp
                    )
                }
            }
        }

        Card(
            Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = panel)
        ) {
            Column(
                Modifier.padding(13.dp),
                verticalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                Text(region.name, color = gold, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                Text("مهمات المنطقة", color = cyan, fontWeight = FontWeight.Bold)

                if (quests.isEmpty()) {
                    Text("لا توجد مهمات مسجلة لهذه المنطقة حالياً.", color = Color.LightGray)
                } else {
                    quests.forEach { quest ->
                        Divider(color = Color.White.copy(alpha = 0.12f))
                        Text(quest.title, color = Color.White, fontWeight = FontWeight.Bold)
                        Text(quest.description, color = Color.LightGray, fontSize = 12.sp)
                        Text(
                            "المستوى ${quest.requiredLevel} • المكافأة ${quest.experienceReward} XP",
                            color = gold,
                            fontSize = 12.sp
                        )
                        Text(
                            if (quest.isSeasonal) "مهمة موسمية" else "مهمة الجزيرة",
                            color = cyan,
                            fontSize = 11.sp
                        )
                    }
                }
            }
        }

        Text("بطاقات الجزيرة", color = gold, fontSize = 20.sp, fontWeight = FontWeight.Bold)

        SystemGreedIslandData.cards.forEach { card ->
            Card(
                Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = panel)
            ) {
                Column(
                    Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            card.name,
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f)
                        )
                        Text(card.rarity, color = gold, fontSize = 12.sp)
                    }
                    Text(
                        "${card.category} • ${card.description}",
                        color = Color.LightGray,
                        fontSize = 12.sp
                    )
                }
            }
        }

        Text(
            "ملاحظة: الواجهة تعرض بيانات الجزيرة وتقرأ حالة القطعة من الحفظ المحلي. اللعب الجماعي والموسم والمكافآت الفعلية لم تُفعّل أونلاين بعد.",
            color = Color.Gray,
            fontSize = 11.sp
        )
    }
}
