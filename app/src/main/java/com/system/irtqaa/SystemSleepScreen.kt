package com.system.irtqaa

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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun SystemSleepScreen() {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val controller = remember {
        SystemSleepFeatureController(context)
    }

    var dashboard by remember {
        mutableStateOf<SystemSleepDashboardProgressViewData?>(null)
    }

    var loading by remember {
        mutableStateOf(true)
    }

    var error by remember {
        mutableStateOf<String?>(null)
    }

    fun refreshDashboard() {
        scope.launch {
            loading = true
            error = null

            val result = withContext(Dispatchers.IO) {
                runCatching {
                    controller.getDashboard()
                }
            }

            result.onSuccess {
                dashboard = it
            }.onFailure {
                error = "تعذر تحميل بيانات النوم"
            }

            loading = false
        }
    }

    LaunchedEffect(controller) {
        refreshDashboard()
    }

    val background = Color(0xFF080D18)
    val panel = Color(0xFF131D30)
    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(background)
            .padding(18.dp)
    ) {
        Text(
            "SYSTEM",
            color = gold,
            fontSize = 30.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            "نظام النوم والتعافي",
            color = Color.LightGray,
            fontSize = 17.sp
        )

        Spacer(Modifier.height(20.dp))

        when {
            loading -> {
                CircularProgressIndicator(color = gold)
                Text(
                    "جاري تحميل بياناتك...",
                    color = Color.White
                )
            }

            error != null -> {
                Text(
                    error ?: "",
                    color = Color.Red
                )

                Button(onClick = { refreshDashboard() }) {
                    Text("إعادة المحاولة")
                }
            }

            dashboard != null -> {
                val data = dashboard!!

                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = panel
                    ),
                    shape = RoundedCornerShape(18.dp)
                ) {
                    Column(
                        Modifier.padding(18.dp)
                    ) {
                        Text(
                            "تقدم التوصيات",
                            color = Color.White,
                            fontSize = 19.sp
                        )

                        Text(
                            "${data.completionPercentage}%",
                            color = gold,
                            fontSize = 30.sp,
                            fontWeight = FontWeight.Bold
                        )

                        LinearProgressIndicator(
                            progress = {
                                data.completionPercentage / 100f
                            },
                            modifier = Modifier.fillMaxWidth(),
                            color = gold
                        )

                        Spacer(Modifier.height(8.dp))

                        Text(
                            "المكتمل: ${data.completedCount}",
                            color = cyan
                        )

                        Text(
                            "المتبقي: ${data.remainingCount}",
                            color = Color.LightGray
                        )

                        Text(
                            "المستوى: ${data.progressLevel}",
                            color = Color.White
                        )
                    }
                }

                Spacer(Modifier.height(18.dp))

                Text(
                    "توصيات النظام",
                    color = gold,
                    fontSize = 22.sp
                )

                Spacer(Modifier.height(10.dp))

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(data.recommendations) { item ->
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = panel
                            ),
                            shape = RoundedCornerShape(14.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(14.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(
                                        item.text,
                                        color = Color.White
                                    )

                                    Text(
                                        "الأولوية: ${item.priority}",
                                        color = cyan,
                                        fontSize = 13.sp
                                    )
                                }

                                Checkbox(
                                    checked = item.isCompleted,
                                    onCheckedChange = { checked ->
                                        scope.launch {
                                            val result =
                                                withContext(Dispatchers.IO) {
                                                    runCatching {
                                                        controller.updateRecommendation(
                                                            recommendation = item.text,
                                                            completed = checked
                                                        )
                                                    }
                                                }

                                            result.onSuccess {
                                                dashboard = it
                                            }.onFailure {
                                                error = "تعذر تحديث التوصية"
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
