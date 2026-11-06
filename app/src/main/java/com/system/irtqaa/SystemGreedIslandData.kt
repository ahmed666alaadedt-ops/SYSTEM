
package com.system.irtqaa

data class GreedIslandRegion(
    val id: String,
    val name: String,
    val description: String,
    val dangerLevel: Int,
    val reward: Int,
    val isUnlocked: Boolean = false
)

data class GreedIslandCard(
    val id: String,
    val name: String,
    val category: String,
    val description: String,
    val rarity: String,
    val quantity: Int = 0
)

data class GreedIslandQuest(
    val id: String,
    val title: String,
    val description: String,
    val regionId: String,
    val requiredLevel: Int,
    val experienceReward: Int,
    val cardReward: String,
    val isSeasonal: Boolean = false
)

data class GreedIslandLoreStone(
    val id: String,
    val name: String,
    val worldId: String,
    val inscription: String,
    val clueId: String,
    val nextHint: String
)

data class GreedIslandTreasureChest(
    val id: String,
    val name: String,
    val regionId: String,
    val rarity: String,
    val requiredLevel: Int,
    val rewardCardId: String,
    val description: String
)

data class GreedIslandGuardian(
    val id: String,
    val name: String,
    val title: String,
    val description: String,
    val level: Int,
    val regionId: String,
    val rewardCardId: String
)

data class GreedIslandSeason(
    val name: String,
    val entryPriceUsd: Double,
    val durationDays: Int,
    val tournamentEnabled: Boolean,
    val prizeWinnerCount: Int,
    val prizePercentages: List<Int>
)

object SystemGreedIslandData {

    const val SEASON_NAME = "موسم جزيرة الطمع"
    const val ENTRY_LEVEL = 25

    const val CREATOR_TITLE = "صانع العالم"
    const val CREATOR_REALM = "مملكة صانع SYSTEM"

    const val SEASON_ENTRY_PRICE_USD = 5.0
    const val REAL_PAYMENT_ENABLED = false

    val season = GreedIslandSeason(
        name = SEASON_NAME,
        entryPriceUsd = SEASON_ENTRY_PRICE_USD,
        durationDays = 30,
        tournamentEnabled = true,
        prizeWinnerCount = 5,
        prizePercentages = listOf(50, 25, 12, 8, 5)
    )

    // خريطة الجزيرة ومناطقها

    val regions = listOf(

        GreedIslandRegion(
            "arrival_port",
            "ميناء الوصول",
            "ميناء عظيم لاستقبال المغامرين الذين حصلوا على حق دخول الجزيرة.",
            1, 100, true
        ),

        GreedIslandRegion(
            "beginner_village",
            "قرية البداية",
            "قرية آمنة تضم التجار والمرشدين ومعلومات الجزيرة.",
            1, 150, true
        ),

        GreedIslandRegion(
            "emerald_forest",
            "غابة الزمرد",
            "غابة هائلة تسكنها كائنات غريبة ووحوش نادرة.",
            4, 450
        ),

        GreedIslandRegion(
            "forgotten_ruins",
            "الأطلال المنسية",
            "آثار حضارات قديمة تخفي نقوشاً وأسراراً عن تاريخ الجزيرة.",
            6, 700
        ),

        GreedIslandRegion(
            "giant_mountains",
            "جبال العمالقة",
            "جبال شاهقة يعيش فيها عمالقة وحراس أقوياء.",
            8, 1200
        ),

        GreedIslandRegion(
            "army_fortress",
            "حصن الجيش الأسطوري",
            "مقر قادة جيش الجزيرة وحراسها ومخلوقاتها الأسطورية.",
            9, 1800
        ),

        GreedIslandRegion(
            "hunter_arena",
            "ساحة الصيادين",
            "ساحة تحديات وقتال ومواجهات بين اللاعبين.",
            7, 900
        ),

        GreedIslandRegion(
            "ancient_library",
            "مكتبة العهد القديم",
            "مكتبة أثرية تحفظ تاريخ الجزيرة وأسرار صانع العالم.",
            8, 1600
        ),

        GreedIslandRegion(
            "treasure_vault",
            "خزائن الكنوز",
            "ممرات سرية وصناديق تحتوي على مهارات وأسلحة نادرة.",
            9, 2200
        ),

        GreedIslandRegion(
            "forbidden_castle",
            "القلعة المحرمة",
            "قلعة محروسة بأقوى حراس الجزيرة.",
            10, 3000
        ),

        GreedIslandRegion(
            "seasonal_colosseum",
            "مدرج البطولة الموسمية",
            "ساحة المعارك الموسمية بين اللاعبين.",
            10, 3500
        ),

        GreedIslandRegion(
            "creator_palace",
            "قصر صانع العالم",
            "القصر المهيب ومقر صاحب الجزيرة. تحكمه صلاحيات خاصة.",
            10, 5000
        ),

        GreedIslandRegion(
            "throne_hall",
            "قاعة العرش",
            "قاعة العرش الملكي ومجلس قادة المملكة.",
            10, 6000
        ),

        GreedIslandRegion(
            "island_core",
            "قلب الجزيرة",
            "أعمق أسرار الجزيرة ومصدر طاقتها القديمة.",
            10, 8000
        )
    )

    // بطاقات المهارات والقطع النادرة

    val cards = listOf(

        GreedIslandCard(
            "healing_potion",
            "جرعة الشفاء",
            "استهلاكية",
            "تساعد على استعادة الصحة.",
            "شائعة"
        ),

        GreedIslandCard(
            "hunter_compass",
            "بوصلة الصياد",
            "أداة",
            "تساعد على اكتشاف المواقع المخفية.",
            "غير شائعة"
        ),

        GreedIslandCard(
            "magic_cloak",
            "عباءة الغموض",
            "معدات",
            "عباءة تمنح خصائص دفاعية خاصة.",
            "نادرة"
        ),

        GreedIslandCard(
            "dragon_egg",
            "بيضة التنين",
            "كائنات",
            "قطعة مرتبطة بكائن أسطوري.",
            "ملحمية"
        ),

        GreedIslandCard(
            "island_key",
            "مفتاح قلب الجزيرة",
            "مهمة",
            "يفتح طريقاً إلى أسرار قلب الجزيرة.",
            "أسطورية"
        ),

        GreedIslandCard(
            "golden_ticket",
            "تذكرة الموسم",
            "موسمية",
            "تذكرة مرتبطة بفعاليات الموسم.",
            "أسطورية"
        ),

        GreedIslandCard(
            "giant_strength",
            "قوة العمالقة",
            "مهارة",
            "قدرة أسطورية تزيد قوة الضربات.",
            "أسطورية"
        ),

        GreedIslandCard(
            "ancient_wisdom",
            "حكمة العهد القديم",
            "مهارة",
            "معرفة نادرة تكشف أسرار الآثار.",
            "أسطورية"
        ),

        GreedIslandCard(
            "phoenix_wings",
            "أجنحة العنقاء",
            "قدرة",
            "قدرة أسطورية للطيران.",
            "أسطورية"
        ),

        GreedIslandCard(
            "divine_aura",
            "هالة السيادة",
            "قدرة",
            "هالة طاقة نادرة تحيط بالمقاتل.",
            "خرافية"
        ),

        GreedIslandCard(
            "shadow_army",
            "ختم جيش الظلال",
            "استدعاء",
            "قطعة نادرة مرتبطة بقدرات الاستدعاء.",
            "خرافية"
        ),

        GreedIslandCard(
            "creator_relic",
            "أثر صانع العالم",
            "قطعة أثرية",
            "أثر قديم مرتبط بتاريخ الجزيرة.",
            "فريدة"
        )
    )

    // مهمات الجزيرة

    val quests = listOf(

        GreedIslandQuest(
            "arrival",
            "الوصول إلى الجزيرة",
            "اكتشف ميناء الوصول وتعرف على قوانين الجزيرة.",
            "arrival_port",
            25, 150, "healing_potion"
        ),

        GreedIslandQuest(
            "village_secret",
            "سر قرية البداية",
            "تحدث مع السكان واكتشف أول أسرار الجزيرة.",
            "beginner_village",
            25, 250, "hunter_compass"
        ),

        GreedIslandQuest(
            "forest_exploration",
            "غابة الزمرد",
            "استكشف الغابة وابحث عن الكائنات النادرة.",
            "emerald_forest",
            30, 500, "magic_cloak"
        ),

        GreedIslandQuest(
            "ruins_puzzle",
            "لغز الأطلال القديمة",
            "حل النقوش القديمة وافتح الطريق السري.",
            "forgotten_ruins",
            35, 800, "ancient_wisdom"
        ),

        GreedIslandQuest(
            "giant_trial",
            "اختبار العمالقة",
            "واجه حارس الجبال واكتسب احترام العمالقة.",
            "giant_mountains",
            40, 1200, "giant_strength"
        ),

        GreedIslandQuest(
            "army_trial",
            "اختبار الجيش الأسطوري",
            "اجتز اختبار قادة الجيش.",
            "army_fortress",
            45, 1600, "shadow_army"
        ),

        GreedIslandQuest(
            "ancient_library_secret",
            "سر مكتبة العهد",
            "اكتشف المخطوطات التي تحكي تاريخ الجزيرة.",
            "ancient_library",
            45, 1800, "creator_relic"
        ),

        GreedIslandQuest(
            "treasure_vault",
            "خزائن الكنوز",
            "اكتشف أحد الصناديق الأسطورية.",
            "treasure_vault",
            50, 2200, "phoenix_wings"
        ),

        GreedIslandQuest(
            "forbidden_castle",
            "اقتحام القلعة المحرمة",
            "واجه حراس القلعة واكتشف أسرارها.",
            "forbidden_castle",
            55, 3000, "divine_aura"
        ),

        GreedIslandQuest(
            "hunter_challenge",
            "بطولة الصيادين",
            "شارك في تحديات الموسم.",
            "seasonal_colosseum",
            55, 3500, "golden_ticket", true
        ),

        GreedIslandQuest(
            "creator_palace_trial",
            "اختبار قصر صانع العالم",
            "اكتشف أسرار القصر واجتز الاختبار المخصص للزوار.",
            "creator_palace",
            60, 5000, "creator_relic"
        ),

        GreedIslandQuest(
            "island_final",
            "سر قلب الجزيرة",
            "اكتشف أعمق أسرار الجزيرة.",
            "island_core",
            70, 8000, "island_key", true
        )
    )

    // ألواح التاريخ والتلميحات بين العوالم

    val loreStones = listOf(

        GreedIslandLoreStone(
            "modern_stone",
            "لوح المدينة المفقود",
            "real",
            "حين ظهرت الجزيرة فوق الغيوم، اختفى أثرها من خرائط البشر.",
            "modern_artifact_clue",
            "ابحث عن العلامة التي لا تظهر إلا عند الغروب."
        ),

        GreedIslandLoreStone(
            "history_stone",
            "لوح الحضارة الأولى",
            "mythology",
            "قبل قيام الممالك، كان هناك عهد يحرس بوابة السماء.",
            "ancient_inscription",
            "النقش الثاني مخفي تحت أطلال الحضارة القديمة."
        ),

        GreedIslandLoreStone(
            "fantasy_stone",
            "لوح الحارس الأسطوري",
            "fantasy",
            "لا يصل إلى الجزيرة إلا من فهم لغة الحارس.",
            "fantasy_guardian_secret",
            "ابحث عن الحارس الذي يحمل ختم العوالم."
        )
    )

    // صناديق الكنوز. جميع الكنوز الفعلية داخل الجزيرة.

    val treasureChests = listOf(

        GreedIslandTreasureChest(
            "emerald_chest",
            "صندوق غابة الزمرد",
            "emerald_forest",
            "نادر",
            30,
            "magic_cloak",
            "صندوق مخفي بين الأشجار القديمة."
        ),

        GreedIslandTreasureChest(
            "giant_chest",
            "صندوق العمالقة",
            "giant_mountains",
            "ملحمي",
            40,
            "giant_strength",
            "صندوق يحرسه أحد عمالقة الجبال."
        ),

        GreedIslandTreasureChest(
            "library_chest",
            "صندوق مكتبة العهد",
            "ancient_library",
            "أسطوري",
            45,
            "ancient_wisdom",
            "صندوق لا يفتح إلا بعد حل لغز المخطوطة."
        ),

        GreedIslandTreasureChest(
            "vault_chest",
            "الصندوق الأسطوري",
            "treasure_vault",
            "خرافي",
            55,
            "phoenix_wings",
            "كنز نادر داخل خزائن الجزيرة."
        ),

        GreedIslandTreasureChest(
            "core_chest",
            "صندوق قلب الجزيرة",
            "island_core",
            "فريد",
            70,
            "creator_relic",
            "أندر صندوق في الجزيرة."
        )
    )

    // حراس المملكة

    val guardians = listOf(

        GreedIslandGuardian(
            "emerald_beast",
            "وحش الزمرد",
            "حارس الغابة",
            "مخلوق ضخم يحرس الغابة وصناديقها.",
            35,
            "emerald_forest",
            "magic_cloak"
        ),

        GreedIslandGuardian(
            "mountain_titan",
            "تيتان الجبال",
            "قائد العمالقة",
            "عملاق أسطوري يحرس ممرات الجبال.",
            50,
            "giant_mountains",
            "giant_strength"
        ),

        GreedIslandGuardian(
            "shadow_commander",
            "قائد جيش الظلال",
            "قائد الحصن",
            "قائد مخيف يقود الحراس والوحوش.",
            65,
            "army_fortress",
            "shadow_army"
        ),

        GreedIslandGuardian(
            "ancient_dragon",
            "التنين العتيق",
            "حارس قلب الجزيرة",
            "تنين أسطوري يحرس الطريق إلى قلب الجزيرة.",
            80,
            "island_core",
            "divine_aura"
        )
    )
}
