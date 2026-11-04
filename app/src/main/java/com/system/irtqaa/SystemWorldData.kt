package com.system.irtqaa

object SystemWorldData {

    val locations = listOf(
        WorldLocation(
            id = "ancient_kingdom",
            name = "المملكة القديمة",
            description = "مملكة تاريخية تضم القلاع والغابات والقرى.",
            era = WorldLocationEra.ANCIENT,
            type = WorldLocationType.CITY,
            requiredLevel = 1,
            isUnlocked = true
        ),
        WorldLocation(
            id = "modern_city",
            name = "المدينة الحديثة",
            description = "مدينة متطورة تضم الأبراج والأسواق والمقاهي.",
            era = WorldLocationEra.MODERN,
            type = WorldLocationType.CITY,
            requiredLevel = 3
        ),
        WorldLocation(
            id = "future_city",
            name = "مدينة المستقبل",
            description = "مدينة تكنولوجية متقدمة.",
            era = WorldLocationEra.FUTURE,
            type = WorldLocationType.CITY,
            requiredLevel = 10
        ),
        WorldLocation(
            id = "cosmic_world",
            name = "العالم الكوني",
            description = "منطقة غامضة لاستكشاف الفضاء والعوالم البعيدة.",
            era = WorldLocationEra.COSMIC,
            type = WorldLocationType.STAR_GATE,
            requiredLevel = 20
        )
    )

    val starGates = listOf(
        StarGate(
            id = "gate_ancient",
            name = "بوابة المملكة القديمة",
            destinationLocationId = "ancient_kingdom",
            requiredLevel = 1,
            isUnlocked = true
        ),
        StarGate(
            id = "gate_future",
            name = "بوابة المستقبل",
            destinationLocationId = "future_city",
            requiredLevel = 10
        ),
        StarGate(
            id = "gate_cosmic",
            name = "البوابة الكونية",
            destinationLocationId = "cosmic_world",
            requiredLevel = 20
        )
    )

    val missions = listOf(
        WorldMission(
            id = "explore_ancient",
            title = "استكشاف المملكة",
            description = "اكتشف أسرار المملكة القديمة.",
            type = MissionType.EXPLORATION,
            requiredLevel = 1,
            xpReward = 50
        ),
        WorldMission(
            id = "daily_challenge",
            title = "التحدي اليومي",
            description = "أكمل تحدياً يومياً داخل العالم.",
            type = MissionType.DAILY,
            requiredLevel = 1,
            xpReward = 30
        ),
        WorldMission(
            id = "solve_puzzle",
            title = "لغز البوابة",
            description = "حل اللغز لفتح الطريق.",
            type = MissionType.PUZZLE,
            requiredLevel = 3,
            xpReward = 100
        )
    )

    val monsters = listOf(
        WorldMonster(
            monsterId = "forest_monster",
            name = "وحش الغابة",
            description = "وحش يعيش في أعماق الغابة.",
            type = MonsterType.BEAST,
            level = 1,
            rank = WorldRank.F,
            health = 100L,
            attackPower = 10L,
            defense = 5L,
            experienceReward = 40L,
            coinReward = 20L
        ),
        WorldMonster(
            monsterId = "dungeon_guardian",
            name = "حارس الزنزانة",
            description = "حارس قوي يحمي أسرار الزنزانة.",
            type = MonsterType.ANCIENT,
            level = 5,
            rank = WorldRank.D,
            health = 500L,
            attackPower = 50L,
            defense = 30L,
            experienceReward = 200L,
            coinReward = 100L
        ),
        WorldMonster(
            monsterId = "cosmic_boss",
            name = "سيد الظلام الكوني",
            description = "زعيم كوني نادر يمتلك قوة هائلة.",
            type = MonsterType.DEMON,
            level = 20,
            rank = WorldRank.S,
            health = 5000L,
            attackPower = 300L,
            defense = 200L,
            experienceReward = 1000L,
            coinReward = 500L,
            isBoss = true,
            isRare = true
        )
    )
}
