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

object SystemGreedIslandData {

    const val SEASON_NAME = "موسم جزيرة الطمع"
    const val ENTRY_LEVEL = 10

    val regions = listOf(
        GreedIslandRegion(
            id = "arrival_port",
            name = "ميناء الوصول",
            description = "نقطة وصول اللاعبين واستقبالهم على الجزيرة العائمة.",
            dangerLevel = 1,
            reward = 100,
            isUnlocked = true
        ),
        GreedIslandRegion(
            id = "beginner_village",
            name = "قرية البداية",
            description = "قرية آمنة للتعرف على قوانين الجزيرة والتجار.",
            dangerLevel = 1,
            reward = 150,
            isUnlocked = true
        ),
        GreedIslandRegion(
            id = "emerald_forest",
            name = "غابة الزمرد",
            description = "غابة مليئة بالكائنات والموارد والبطاقات النادرة.",
            dangerLevel = 3,
            reward = 350
        ),
        GreedIslandRegion(
            id = "forgotten_ruins",
            name = "الأطلال المنسية",
            description = "أطلال قديمة تحتوي على ألغاز وأسرار ومكافآت.",
            dangerLevel = 5,
            reward = 600
        ),
        GreedIslandRegion(
            id = "hunter_arena",
            name = "ساحة الصيادين",
            description = "منطقة تحديات ومواجهات بين اللاعبين.",
            dangerLevel = 7,
            reward = 900
        ),
        GreedIslandRegion(
            id = "forbidden_castle",
            name = "القلعة المحرمة",
            description = "منطقة عالية الخطورة لحراس الجزيرة وأسرارها.",
            dangerLevel = 9,
            reward = 1500
        ),
        GreedIslandRegion(
            id = "island_core",
            name = "قلب الجزيرة",
            description = "الموقع النهائي الذي يخفي أسرار الموسم وجوائزه.",
            dangerLevel = 10,
            reward = 3000
        )
    )

    val cards = listOf(
        GreedIslandCard(
            id = "healing_potion",
            name = "جرعة الشفاء",
            category = "استهلاكية",
            description = "بطاقة تمنح اللاعب جرعة علاج.",
            rarity = "شائعة"
        ),
        GreedIslandCard(
            id = "hunter_compass",
            name = "بوصلة الصياد",
            category = "أداة",
            description = "تساعد على اكتشاف المواقع المخفية.",
            rarity = "غير شائعة"
        ),
        GreedIslandCard(
            id = "magic_cloak",
            name = "عباءة الغموض",
            category = "معدات",
            description = "عباءة ذات خصائص خاصة.",
            rarity = "نادرة"
        ),
        GreedIslandCard(
            id = "dragon_egg",
            name = "بيضة التنين",
            category = "كائنات",
            description = "بطاقة نادرة مرتبطة بكائن أسطوري.",
            rarity = "ملحمية"
        ),
        GreedIslandCard(
            id = "island_key",
            name = "مفتاح قلب الجزيرة",
            category = "مهمة",
            description = "مفتاح مطلوب للوصول إلى المنطقة النهائية.",
            rarity = "أسطورية"
        ),
        GreedIslandCard(
            id = "golden_ticket",
            name = "تذكرة الكنز الذهبي",
            category = "موسمية",
            description = "تذكرة خاصة للمشاركة في تحديات الموسم.",
            rarity = "أسطورية"
        )
    )

    val quests = listOf(
        GreedIslandQuest(
            id = "arrival",
            title = "الوصول إلى الجزيرة",
            description = "اكتشف ميناء الوصول وتعرّف على قوانين الجزيرة.",
            regionId = "arrival_port",
            requiredLevel = 10,
            experienceReward = 150,
            cardReward = "healing_potion"
        ),
        GreedIslandQuest(
            id = "village_secret",
            title = "سر قرية البداية",
            description = "تحدث مع سكان القرية واكتشف أول أسرارها.",
            regionId = "beginner_village",
            requiredLevel = 10,
            experienceReward = 250,
            cardReward = "hunter_compass"
        ),
        GreedIslandQuest(
            id = "forest_exploration",
            title = "استكشاف غابة الزمرد",
            description = "استكشف الغابة واجمع الموارد النادرة.",
            regionId = "emerald_forest",
            requiredLevel = 15,
            experienceReward = 400,
            cardReward = "magic_cloak"
        ),
        GreedIslandQuest(
            id = "ruins_puzzle",
            title = "لغز الأطلال",
            description = "حل اللغز القديم وافتح طريق الأطلال.",
            regionId = "forgotten_ruins",
            requiredLevel = 20,
            experienceReward = 650,
            cardReward = "dragon_egg"
        ),
        GreedIslandQuest(
            id = "hunter_challenge",
            title = "اختبار الصيادين",
            description = "اجتز تحدي ساحة الصيادين.",
            regionId = "hunter_arena",
            requiredLevel = 25,
            experienceReward = 900,
            cardReward = "golden_ticket",
            isSeasonal = true
        ),
        GreedIslandQuest(
            id = "forbidden_castle",
            title = "اقتحام القلعة المحرمة",
            description = "واجه حراس القلعة واكتشف أسرارها.",
            regionId = "forbidden_castle",
            requiredLevel = 35,
            experienceReward = 1500,
            cardReward = "island_key"
        ),
        GreedIslandQuest(
            id = "island_final",
            title = "سر قلب الجزيرة",
            description = "افتح قلب الجزيرة واكتشف الكنز النهائي.",
            regionId = "island_core",
            requiredLevel = 50,
            experienceReward = 3000,
            cardReward = "island_key",
            isSeasonal = true
        )
    )
}
