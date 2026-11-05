package com.system.irtqaa

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale
import java.util.concurrent.atomic.AtomicReference

private data class MiyarGuidePage(
    val icon: String,
    val title: String,
    val description: String,
    val speech: String
)

private val miyarGuidePages = listOf(
    MiyarGuidePage(
        "🌌",
        "أهلاً بك في SYSTEM WORLD",
        "أنا ميار، مرشدتك داخل هذا العالم. سأعرّفك على التطبيق واللعبة والأنظمة والمغامرات.",
        "أهلاً بك في سيستم وورلد. أنا ميار، مرشدتك داخل هذا العالم. سأرافقك وأشرح لك التطبيق واللعبة والأنظمة المختلفة."
    ),
    MiyarGuidePage(
        "🌍",
        "العوالم الأربعة",
        "أربعة عوالم مستقلة، لكل عالم بيئته وقوانينه ومغامراته الخاصة.",
        "لدينا أربعة عوالم رئيسية: العالم الواقعي الحديث، وعالم الأساطير والتاريخ، والعالم الخيالي، وجزيرة الطمع الغامضة."
    ),
    MiyarGuidePage(
        "🏙️",
        "العالم الواقعي الحديث",
        "دول ومدن حقيقية، ومؤسسات وحكومات واقتصاد ومواصلات وحياة يومية.",
        "في العالم الواقعي ستجد دولاً ومدناً حقيقية بمواقعها الجغرافية وهويتها المحلية. تستطيع استكشاف المدن والعمل والتفاعل مع المؤسسات والأسواق والمواصلات."
    ),
    MiyarGuidePage(
        "🏛️",
        "عالم الأساطير والتاريخ",
        "حضارات قديمة وعصور تاريخية وأساطير وممالك وأماكن غامضة.",
        "عالم الأساطير والتاريخ يأخذك إلى حضارات وعصور مختلفة وممالك قديمة وأماكن مليئة بالأسرار والتحديات."
    ),
    MiyarGuidePage(
        "🧙",
        "العالم الخيالي",
        "ممالك سحرية وكائنات وقدرات ومغامرات ومهام خاصة.",
        "أما العالم الخيالي فهو عالم الممالك والسحر والكائنات والقدرات. ستكتشف مناطق جديدة وتطور شخصيتك."
    ),
    MiyarGuidePage(
        "🏝️",
        "جزيرة الطمع",
        "جزيرة غامضة مليئة بالأسرار والتحديات والأشياء النادرة.",
        "جزيرة الطمع عالم غامض يحمل أسراراً وتحديات وأشياء نادرة. ستكتشف أسرار الجزيرة خلال رحلتك."
    ),
    MiyarGuidePage(
        "🧭",
        "البوابات والانتقال",
        "بوابات نجمية تربط العوالم والمناطق والعصور، وبوابات وحوش مستقلة للاستكشاف والقتال.",
        "البوابات النجمية تربط العوالم والمناطق والعصور، أما بوابات الوحوش فتقودك إلى مناطق مليئة بالوحوش والزعماء والموارد. وهناك أيضاً قدرات انتقال سريع ووسائل نقل طبيعية."
    ),
    MiyarGuidePage(
        "⚔️",
        "الصيادون والقتال",
        "اختبارات ورتب ومهام ومكافآت، وتطوير للقدرات والمعدات ومواجهات مع الخصوم والوحوش.",
        "يمكنك اختيار طريق الصياد وخوض الاختبارات والترقي في الرتب وتنفيذ المهام. كما توجد مواجهات وقتالات ضد الخصوم والوحوش والزعماء."
    ),
    MiyarGuidePage(
        "🛡️",
        "الشرطة والأدوار الأمنية",
        "يمكنك اختيار العمل شرطياً وتنفيذ المهام الأمنية والتدرج في الرتب.",
        "يمكنك اختيار العمل في الشرطة والأمن، وتنفيذ المهام والتدرج في الرتب والمشاركة في أحداث العالم."
    ),
    MiyarGuidePage(
        "🎒",
        "المهام والمخزون والتطوير",
        "تابع مهامك واجمع المكافآت وأدر أموالك ومعداتك وطوّر شخصيتك.",
        "خلال رحلتك ستجد مهاماً ومكافآت وأموالاً ومعدات وأشياء قابلة للجمع. تابع مخزونك ومستواك وخبرتك."
    ),
    MiyarGuidePage(
        "🤝",
        "أنا ميار، وسأرافقك",
        "يمكنك الرجوع إليّ لطلب شرح الأنظمة ومعرفة طريقة استخدام الأقسام وإعادة هذا الدليل متى احتجت.",
        "وهكذا تعرفت على أهم أقسام سيستم وورلد. أنا ميار وسأكون معك لمساعدتك وشرح الأنظمة والإجابة عن أسئلتك. يمكنك الآن بدء رحلتك."
    )
)

@Composable
fun SystemMiyarGuideGate(
    content: @Composable () -> Unit
) {
    val context = LocalContext.current

    var showGuide by remember {
        mutableStateOf(
            !context.getSharedPreferences(
                "system_miyar_guide",
                Context.MODE_PRIVATE
            ).getBoolean("completed", false)
        )
    }

    if (showGuide) {
        SystemMiyarGuideScreen(
            onFinish = {
                context.getSharedPreferences(
                    "system_miyar_guide",
                    Context.MODE_PRIVATE
                ).edit()
                    .putBoolean("completed", true)
                    .apply()

                showGuide = false
            }
        )
    } else {
        content()
    }
}

@Composable
private fun SystemMiyarGuideScreen(
    onFinish: () -> Unit
) {
    val context = LocalContext.current

    var currentPage by remember { mutableIntStateOf(0) }
    var ttsReady by remember { mutableStateOf(false) }
    var speechEnabled by remember { mutableStateOf(true) }

    var textToSpeech by remember {
        mutableStateOf<TextToSpeech?>(null)
    }

    val page = miyarGuidePages[currentPage]

    DisposableEffect(context) {
        val engineReference =
            AtomicReference<TextToSpeech?>(null)

        val mainHandler = Handler(Looper.getMainLooper())
        var disposed = false

        val engine = TextToSpeech(context) { status ->
            mainHandler.post {
                val activeEngine = engineReference.get()

                if (!disposed && activeEngine != null) {
                    ttsReady =
                        status == TextToSpeech.SUCCESS &&
                        engineLanguage(
                            activeEngine,
                            Locale("ar", "IQ")
                        )
                }
            }
        }

        engineReference.set(engine)
        textToSpeech = engine

        onDispose {
            disposed = true

            engineReference.set(null)

            engine.stop()
            engine.shutdown()

            textToSpeech = null
            ttsReady = false
        }
    }

    LaunchedEffect(
        currentPage,
        ttsReady,
        speechEnabled
    ) {
        if (ttsReady && speechEnabled) {
            textToSpeech?.speak(
                page.speech,
                TextToSpeech.QUEUE_FLUSH,
                null,
                "miyar_guide_$currentPage"
            )
        }
    }

    BackHandler {
        if (currentPage > 0) {
            currentPage--
        } else {
            onFinish()
        }
    }

    val gold = Color(0xFFFFC857)
    val cyan = Color(0xFF45D6E8)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFF050B17),
                        Color(0xFF101D32),
                        Color(0xFF17152D)
                    )
                )
            )
            .padding(18.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(12.dp))

            Text(
                "SYSTEM WORLD",
                color = gold,
                fontSize = 27.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 2.sp
            )

            Text(
                "دليلك الأول مع ميار",
                color = cyan,
                fontSize = 15.sp
            )

            Spacer(Modifier.height(25.dp))

            Box(
                modifier = Modifier
                    .size(112.dp)
                    .background(
                        Brush.radialGradient(
                            listOf(
                                cyan.copy(alpha = 0.35f),
                                gold.copy(alpha = 0.16f),
                                Color(0xFF101827)
                            )
                        ),
                        CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "م",
                    color = gold,
                    fontSize = 58.sp,
                    fontWeight = FontWeight.Black
                )
            }

            Spacer(Modifier.height(12.dp))

            Text(
                "أنا ميار",
                color = Color.White,
                fontSize = 25.sp,
                fontWeight = FontWeight.Bold
            )

            Text(
                "مرشدتك ومساعدتك داخل SYSTEM WORLD",
                color = Color.LightGray,
                fontSize = 13.sp,
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(25.dp))

            LinearProgressIndicator(
                progress = {
                    (currentPage + 1).toFloat() /
                        miyarGuidePages.size.toFloat()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(7.dp),
                color = gold,
                trackColor = Color(0xFF26354B)
            )

            Spacer(Modifier.height(8.dp))

            Text(
                "الشرح ${currentPage + 1} من ${miyarGuidePages.size}",
                color = cyan,
                fontSize = 12.sp
            )

            Spacer(Modifier.height(18.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(24.dp),
                colors = CardDefaults.cardColors(
                    containerColor = Color(0xE817263B)
                ),
                elevation = CardDefaults.cardElevation(8.dp)
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        page.icon,
                        fontSize = 45.sp
                    )

                    Spacer(Modifier.height(12.dp))

                    Text(
                        page.title,
                        color = gold,
                        fontSize = 21.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(14.dp))

                    Text(
                        page.description,
                        color = Color(0xFFE1EAF5),
                        fontSize = 16.sp,
                        lineHeight = 27.sp,
                        textAlign = TextAlign.Center
                    )
                }
            }

            Spacer(Modifier.height(20.dp))

            OutlinedButton(
                onClick = {
                    speechEnabled = !speechEnabled

                    if (!speechEnabled) {
                        textToSpeech?.stop()
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            ) {
                Text(
                    if (speechEnabled)
                        "إيقاف الشرح الصوتي"
                    else
                        "تشغيل الشرح الصوتي",
                    color = cyan
                )
            }

            Button(
                onClick = {
                    if (ttsReady) {
                        textToSpeech?.speak(
                            page.speech,
                            TextToSpeech.QUEUE_FLUSH,
                            null,
                            "miyar_replay_$currentPage"
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = ttsReady,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF183D55),
                    contentColor = Color.White
                )
            ) {
                Text("🔊 استمع إلى ميار مرة ثانية")
            }

            Spacer(Modifier.height(18.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                if (currentPage > 0) {
                    OutlinedButton(
                        onClick = {
                            currentPage--
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("السابق")
                    }
                }

                Button(
                    onClick = {
                        if (
                            currentPage <
                            miyarGuidePages.lastIndex
                        ) {
                            currentPage++
                        } else {
                            onFinish()
                        }
                    },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = gold,
                        contentColor = Color(0xFF101827)
                    )
                ) {
                    Text(
                        if (
                            currentPage ==
                            miyarGuidePages.lastIndex
                        ) {
                            "ابدأ رحلتك"
                        } else {
                            "التالي"
                        },
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(Modifier.height(10.dp))

            OutlinedButton(
                onClick = onFinish,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    "تخطي الشرح والدخول إلى التطبيق",
                    color = Color.LightGray
                )
            }

            Spacer(Modifier.height(12.dp))

            Text(
                "يمكنك الرجوع إلى ميار وطلب الشرح في أي وقت.",
                color = Color(0xFF9EACC0),
                fontSize = 12.sp,
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(12.dp))
        }
    }
}

private fun engineLanguage(
    engine: TextToSpeech,
    locale: Locale
): Boolean {
    val result = engine.setLanguage(locale)

    if (result >= TextToSpeech.LANG_AVAILABLE) {
        return true
    }

    val fallback = engine.setLanguage(Locale("ar"))

    return fallback >= TextToSpeech.LANG_AVAILABLE
}
