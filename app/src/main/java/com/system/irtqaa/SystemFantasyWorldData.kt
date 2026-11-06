
package com.system.irtqaa

data class FantasyZone(
    val id: String,
    val name: String,
    val description: String,
    val requiredLevel: Int,
    val atmosphere: String
)

data class FantasyQuest(
    val id: String,
    val title: String,
    val description: String,
    val requiredLevel: Int,
    val xpReward: Int,
    val coinReward: Int
)

data class FantasyMonster(
    val id: String,
    val name: String,
    val description: String,
    val level: Int,
    val power: Int,
    val xpReward: Int,
    val coinReward: Int,
    val isBoss: Boolean = false
)

object SystemFantasyWorldData {

    val zones = listOf(
        FantasyZone(
            id = "whisper_forest",
            name = "غابة الهمس",
            description = "غابة سحرية تتكلم أشجارها وتختبئ بين جذورها مخلوقات غامضة.",
            requiredLevel = 1,
            atmosphere = "غابة مسحورة"
        ),
        FantasyZone(
            id = "dragon_mountains",
            name = "جبال التنانين",
            description = "قمم بركانية تسكنها التنانين القديمة وحراس النار.",
            requiredLevel = 3,
            atmosphere = "جبال بركانية"
        ),
        FantasyZone(
            id = "crystal_kingdom",
            name = "مملكة الكريستال",
            description = "مملكة مضيئة تحكمها أسرار البلورات والطاقة السحرية.",
            requiredLevel = 5,
            atmosphere = "مملكة سحرية"
        ),
        FantasyZone(
            id = "shadow_dungeon",
            name = "زنزانة الظلال",
            description = "متاهة عميقة مليئة بالفخاخ والوحوش والكنوز المحرمة.",
            requiredLevel = 8,
            atmosphere = "زنزانة خطرة"
        ),
        FantasyZone(
            id = "sky_citadel",
            name = "قلعة السماء",
            description = "قلعة عائمة فوق الغيوم لا يصل إليها إلا أصحاب القوة العالية.",
            requiredLevel = 12,
            atmosphere = "قلعة عائمة"
        ),
        FantasyZone(
            id = "dragon_throne",
            name = "عرش التنين الأزلي",
            description = "أرض الزعيم الأسطوري الأخير وحارس أسرار العالم.",
            requiredLevel = 20,
            atmosphere = "منطقة زعيم أسطوري"
        )
    )

    val quests = listOf(
        FantasyQuest(
            id = "first_magic",
            title = "أول اتصال بالسحر",
            description = "اكتشف مصدر الطاقة السحرية في غابة الهمس.",
            requiredLevel = 1,
            xpReward = 50,
            coinReward = 20
        ),
        FantasyQuest(
            id = "forest_secret",
            title = "سر الغابة القديمة",
            description = "اكتشف آثار الحضارة السحرية المفقودة.",
            requiredLevel = 1,
            xpReward = 70,
            coinReward = 30
        ),
        FantasyQuest(
            id = "dragon_egg",
            title = "بيضة التنين",
            description = "اعثر على أثر التنين في الجبال البركانية.",
            requiredLevel = 3,
            xpReward = 120,
            coinReward = 60
        ),
        FantasyQuest(
            id = "crystal_power",
            title = "قوة البلورة",
            description = "اجمع الطاقة من قلب مملكة الكريستال.",
            requiredLevel = 5,
            xpReward = 180,
            coinReward = 90
        ),
        FantasyQuest(
            id = "shadow_trial",
            title = "اختبار الظلال",
            description = "اعبر متاهة الظلال وواجه مخاوفك.",
            requiredLevel = 8,
            xpReward = 250,
            coinReward = 130
        ),
        FantasyQuest(
            id = "sky_secret",
            title = "سر قلعة السماء",
            description = "اكتشف السر المدفون فوق الغيوم.",
            requiredLevel = 12,
            xpReward = 350,
            coinReward = 200
        ),
        FantasyQuest(
            id = "eternal_dragon",
            title = "التنين الأزلي",
            description = "واجه التحدي الأعظم عند عرش التنين.",
            requiredLevel = 20,
            xpReward = 1000,
            coinReward = 700
        )
    )

    val monsters = listOf(
        FantasyMonster(
            id = "forest_wolf",
            name = "ذئب الغابة السحري",
            description = "مخلوق سريع تحيط به هالة خضراء.",
            level = 1,
            power = 20,
            xpReward = 40,
            coinReward = 15
        ),
        FantasyMonster(
            id = "shadow_goblin",
            name = "غول الظلال",
            description = "مقاتل ماكر يختبئ في المناطق المظلمة.",
            level = 2,
            power = 45,
            xpReward = 65,
            coinReward = 25
        ),
        FantasyMonster(
            id = "fire_drake",
            name = "تنين النار الصغير",
            description = "تنين يطلق لهباً حارقاً من فمه.",
            level = 3,
            power = 75,
            xpReward = 120,
            coinReward = 55
        ),
        FantasyMonster(
            id = "crystal_guardian",
            name = "حارس الكريستال",
            description = "عملاق مصنوع من البلورات السحرية.",
            level = 5,
            power = 125,
            xpReward = 200,
            coinReward = 100
        ),
        FantasyMonster(
            id = "abyss_knight",
            name = "فارس الهاوية",
            description = "محارب مظلم يحرس أعماق الزنزانة.",
            level = 8,
            power = 200,
            xpReward = 300,
            coinReward = 150
        ),
        FantasyMonster(
            id = "sky_dragon",
            name = "تنين السماء",
            description = "تنين ضخم يحلق حول القلعة العائمة.",
            level = 12,
            power = 300,
            xpReward = 450,
            coinReward = 250,
            isBoss = true
        ),
        FantasyMonster(
            id = "eternal_dragon_boss",
            name = "التنين الأزلي",
            description = "أحد أقدم الكائنات الأسطورية وأقواها.",
            level = 20,
            power = 500,
            xpReward = 1200,
            coinReward = 800,
            isBoss = true
        )
    )
}
