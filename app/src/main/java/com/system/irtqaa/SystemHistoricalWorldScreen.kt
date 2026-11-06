package com.system.irtqaa

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
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

data class HistoricalCivilization(
    val id: String,
    val name: String,
    val region: String,
    val description: String,
    val symbol: String,
    val accent: Color,
    val locations: List<String>,
    val missions: List<String>
)

object SystemHistoricalWorldData {

    val civilizations = listOf(

        HistoricalCivilization(
            id = "sumer",
            name = "حضارة سومر",
            region = "جنوب بلاد الرافدين",
            description = "أرض المدن الأولى والكتابة المسمارية والمعابد القديمة.",
            symbol = "𒀭",
            accent = Color(0xFFE8B85C),
            locations = listOf(
                "أوروك",
                "أور",
                "إريدو",
                "لگش"
            ),
            missions = listOf(
                "اكتشف ألواح الكتابة المسمارية",
                "استكشف معابد أوروك",
                "ابحث عن أسرار مدينة أور"
            )
        ),

        HistoricalCivilization(
            id = "babylon",
            name = "حضارة بابل",
            region = "وسط بلاد الرافدين",
            description = "مدينة الأسوار العظيمة والبوابات الملكية وحدائق الأساطير.",
            symbol = "𒆍",
            accent = Color(0xFFE6A34A),
            locations = listOf(
                "مدينة بابل",
                "بوابة عشتار",
                "الزقورة",
                "ضفاف الفرات"
            ),
            missions = listOf(
                "اعبر بوابة عشتار",
                "اكتشف أسرار المدينة القديمة",
                "استكشف آثار الملوك البابليين"
            )
        ),

        HistoricalCivilization(
            id = "assyrian",
            name = "الحضارة الآشورية",
            region = "شمال بلاد الرافدين",
            description = "ممالك قوية وقصور ملكية ونقوش ومعارك تاريخية.",
            symbol = "𒀸",
            accent = Color(0xFFC58A52),
            locations = listOf(
                "نينوى",
                "نمرود",
                "آشور",
                "خورسباد"
            ),
            missions = listOf(
                "استكشف قصر نينوى",
                "اكتشف النقوش الملكية",
                "ابحث عن المكتبة القديمة"
            )
        ),

        HistoricalCivilization(
            id = "egypt",
            name = "مصر القديمة",
            region = "وادي النيل",
            description = "الأهرامات والمعابد والملوك والأسرار الفرعونية.",
            symbol = "𓂀",
            accent = Color(0xFFE7C66A),
            locations = listOf(
                "الجيزة",
                "الأقصر",
                "وادي الملوك",
                "الكرنك"
            ),
            missions = listOf(
                "استكشف الأهرامات",
                "اكتشف أسرار المعابد",
                "ابحث عن المقابر الملكية"
            )
        ),

        HistoricalCivilization(
            id = "greece",
            name = "اليونان القديمة",
            region = "بحر إيجة",
            description = "المدن الإغريقية والفلسفة والأسواق والملاعب القديمة.",
            symbol = "Ω",
            accent = Color(0xFF75BCE8),
            locations = listOf(
                "أثينا",
                "إسبرطة",
                "دلفي",
                "أولمبيا"
            ),
            missions = listOf(
                "اكتشف أكروبوليس أثينا",
                "استكشف مدينة إسبرطة",
                "ابحث عن أسرار دلفي"
            )
        ),

        HistoricalCivilization(
            id = "china",
            name = "الصين القديمة",
            region = "شرق آسيا",
            description = "الإمبراطوريات القديمة والأسوار العظيمة والقصور.",
            symbol = "龍",
            accent = Color(0xFFE66D62),
            locations = listOf(
                "شيان",
                "بكين القديمة",
                "سور الصين",
                "المدينة الإمبراطورية"
            ),
            missions = listOf(
                "استكشف سور الصين",
                "اكتشف جيش التيراكوتا",
                "ابحث عن أسرار القصر الإمبراطوري"
            )
        )
    )
}

@Composable
fun SystemHistoricalWorldScreen(
    onBack: () -> Unit
) {
    var selectedCivilization by remember {
        mutableStateOf<HistoricalCivilization?>(null)
    }

    var selectedLocation by remember {
        mutableStateOf<String?>(null)
    }

    var completedMissions by remember {
        mutableStateOf(setOf<String>())
    }

    var guideMessage by remember {
        mutableStateOf(
            "أهلاً بك في عالم الحضارات التاريخية. اختر حضارتك الأولى لنبدأ الاستكشاف."
        )
    }

    val gold = Color(0xFFE6B65C)
    val background = Color(0xFF100D0A)
    val panel = Color(0xFF292018)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(background)
    ) {

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 14.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
            contentPadding = PaddingValues(
                top = 12.dp,
                bottom = 28.dp
            )
        ) {

            item {
                Button(
                    onClick = {
                        if (selectedLocation != null) {
                            selectedLocation = null
                        } else if (selectedCivilization != null) {
                            selectedCivilization = null
                        } else {
                            onBack()
                        }
                    }
                ) {
                    Text("رجوع")
                }
            }

            item {
                Column {
                    Text(
                        "SYSTEM WORLD",
                        color = gold,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        "عالم الحضارات التاريخية",
                        color = Color.White,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Black
                    )

                    Text(
                        "رحلة بين حضارات العالم القديم",
                        color = Color.LightGray,
                        fontSize = 14.sp
                    )
                }
            }

            item {
                HistoricalGuideCard(
                    message = guideMessage,
                    accent = gold
                )
            }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = panel
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            "سجل المستكشف",
                            color = gold,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            "المهام المكتملة: ${completedMissions.size}",
                            color = Color.White,
                            fontSize = 18.sp
                        )

                        Text(
                            "الحضارات المتاحة: ${SystemHistoricalWorldData.civilizations.size}",
                            color = Color.LightGray
                        )
                    }
                }
            }

            if (selectedCivilization == null) {

                item {
                    Text(
                        "اختر حضارتك",
                        color = gold,
                        fontSize = 21.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                items(
                    SystemHistoricalWorldData.civilizations,
                    key = { it.id }
                ) { civilization ->

                    HistoricalCivilizationCard(
                        civilization = civilization,
                        onClick = {
                            selectedCivilization = civilization
                            selectedLocation = null

                            guideMessage =
                                "مرحباً بك في ${civilization.name}. " +
                                "ابدأ بزيارة إحدى المناطق واكتشف أسرار هذه الحضارة."
                        }
                    )
                }

            } else {

                val civilization = selectedCivilization!!

                item {
                    HistoricalSectionTitle(
                        title = civilization.name,
                        subtitle = civilization.region,
                        accent = civilization.accent
                    )
                }

                item {
                    Text(
                        civilization.description,
                        color = Color.White,
                        fontSize = 15.sp
                    )
                }

                item {
                    Text(
                        "المناطق التاريخية",
                        color = civilization.accent,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                items(civilization.locations) { location ->

                    HistoricalLocationCard(
                        location = location,
                        accent = civilization.accent,
                        selected = selectedLocation == location,
                        onClick = {
                            selectedLocation = location

                            guideMessage =
                                "وصلت إلى $location. " +
                                "استكشف المكان وابحث عن آثاره وأسراره."
                        }
                    )
                }

                item {
                    Text(
                        "مهام الاستكشاف",
                        color = civilization.accent,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                items(civilization.missions) { mission ->

                    val missionId =
                        "${civilization.id}_$mission"

                    val completed =
                        missionId in completedMissions

                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = panel
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {

                            Text(
                                mission,
                                color = Color.White,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )

                            Text(
                                if (completed) "تم إنجاز المهمة"
                                else "مهمة استكشاف تاريخية",
                                color = if (completed) Color(0xFF65E6A6)
                                else Color.LightGray
                            )

                            Button(
                                onClick = {
                                    completedMissions =
                                        completedMissions + missionId

                                    guideMessage =
                                        "أحسنت! أنجزت مهمة: $mission"
                                },
                                enabled = !completed,
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = civilization.accent,
                                    contentColor = Color.Black
                                )
                            ) {
                                Text(
                                    if (completed) "مكتملة"
                                    else "تسجيل الإنجاز"
                                )
                            }
                        }
                    }
                }
            }

            item {
                Text(
                    "SYSTEM HISTORICAL WORLD",
                    color = gold.copy(alpha = 0.65f),
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
private fun HistoricalGuideCard(
    message: String,
    accent: Color
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                1.dp,
                accent.copy(alpha = 0.45f),
                RoundedCornerShape(18.dp)
            ),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF211B15)
        )
    ) {
        Row(
            modifier = Modifier.padding(15.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "م",
                color = accent,
                fontSize = 34.sp,
                fontWeight = FontWeight.Black
            )

            Spacer(Modifier.width(12.dp))

            Column {
                Text(
                    "ميار | مرشدتك التاريخية",
                    color = accent,
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

@Composable
private fun HistoricalCivilizationCard(
    civilization: HistoricalCivilization,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 130.dp)
            .clickable(onClick = onClick)
            .border(
                1.dp,
                civilization.accent.copy(alpha = 0.55f),
                RoundedCornerShape(20.dp)
            ),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF292018)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {

            Box(
                modifier = Modifier
                    .size(66.dp)
                    .background(
                        civilization.accent.copy(alpha = 0.14f),
                        RoundedCornerShape(16.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    civilization.symbol,
                    color = civilization.accent,
                    fontSize = 30.sp,
                    fontWeight = FontWeight.Black
                )
            }

            Spacer(Modifier.width(14.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    civilization.name,
                    color = civilization.accent,
                    fontSize = 19.sp,
                    fontWeight = FontWeight.Black
                )

                Text(
                    civilization.region,
                    color = Color.LightGray,
                    fontSize = 12.sp
                )

                Spacer(Modifier.height(5.dp))

                Text(
                    civilization.description,
                    color = Color.White,
                    fontSize = 13.sp
                )

                Spacer(Modifier.height(7.dp))

                Text(
                    "استكشف الحضارة ←",
                    color = civilization.accent,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun HistoricalSectionTitle(
    title: String,
    subtitle: String,
    accent: Color
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.horizontalGradient(
                    listOf(
                        accent.copy(alpha = 0.24f),
                        Color.Transparent
                    )
                )
            )
            .padding(14.dp)
    ) {
        Text(
            title,
            color = accent,
            fontSize = 25.sp,
            fontWeight = FontWeight.Black
        )

        Text(
            subtitle,
            color = Color.LightGray,
            fontSize = 13.sp
        )
    }
}

@Composable
private fun HistoricalLocationCard(
    location: String,
    accent: Color,
    selected: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .border(
                1.dp,
                accent.copy(
                    alpha = if (selected) 0.9f else 0.25f
                ),
                RoundedCornerShape(15.dp)
            ),
        shape = RoundedCornerShape(15.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (selected)
                Color(0xFF45331F)
            else
                Color(0xFF211B15)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(15.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "⌖",
                color = accent,
                fontSize = 25.sp
            )

            Spacer(Modifier.width(12.dp))

            Text(
                location,
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )

            Spacer(Modifier.weight(1f))

            Text(
                if (selected) "أنت هنا" else "استكشاف",
                color = accent,
                fontSize = 12.sp
            )
        }
    }
}
