package com.system.irtqaa

object SystemWorldData {

    val locations = listOf(
        WorldLocation(
            id = "ancient_kingdom",
            name = "المملكة القديمة",
            description = "مملكة تاريخية تضم القلاع والغابات والقرى.",
            era = WorldEra.ANCIENT,
            type = WorldLocationType.CITY,
            requiredLevel = 1,
            isUnlocked = true
        ),
        WorldLocation(
            id = "modern_city",
            name = "المدينة الحديثة",
            description = "مدينة متطورة تضم الأبراج والأسواق والمقاهي.",
            era = WorldEra.MODERN,
            type = WorldLocationType.CITY,
            requiredLevel = 3
        ),
        WorldLocation(
            id = "future_city",
            name = "مدينة المستقبل",
            description = "مدينة تكنولوجية متقدمة.",
            era = WorldEra.FUTURE,
            type = WorldLocationType.CITY,
            requiredLevel = 10
        ),
        WorldLocation(
            id = "cosmic_world",
            name = "العالم الكوني",
            description = "منطقة غامضة لاستكشاف الفضاء والعوالم البعيدة.",
            era = WorldEra.COSMIC,
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
            id = "forest_monster",
            name = "وحش الغابة",
            level = 1,
            health = 100,
            xpReward = 40
        ),
        WorldMonster(
            id = "dungeon_guardian",
            name = "حارس الزنزانة",
            level = 5,
            health = 500,
            xpReward = 200
        ),
        WorldMonster(
            id = "cosmic_boss",
            name = "سيد الظلام الكوني",
            level = 20,
            health = 5000,
            xpReward = 1000
        )
    )
}
