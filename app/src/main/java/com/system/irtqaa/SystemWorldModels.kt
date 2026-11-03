
package com.system.irtqaa

enum class WorldEra {
    ANCIENT,
    MODERN,
    FUTURE,
    COSMIC
}

enum class WorldLocationType {
    CITY,
    RESTAURANT,
    FOREST,
    DUNGEON,
    ARENA,
    RACING_TRACK,
    GUILD_HALL,
    STAR_GATE
}

enum class MissionType {
    EXPLORATION,
    COMBAT,
    RACING,
    PUZZLE,
    SOCIAL,
    DAILY
}

data class WorldLocation(
    val id: String,
    val name: String,
    val description: String,
    val era: WorldEra,
    val type: WorldLocationType,
    val requiredLevel: Int,
    val isUnlocked: Boolean = false
)

data class StarGate(
    val id: String,
    val name: String,
    val destinationLocationId: String,
    val requiredLevel: Int,
    val isUnlocked: Boolean = false
)

data class WorldMission(
    val id: String,
    val title: String,
    val description: String,
    val type: MissionType,
    val requiredLevel: Int,
    val xpReward: Int,
    val isCompleted: Boolean = false
)

data class WorldMonster(
    val id: String,
    val name: String,
    val level: Int,
    val health: Int,
    val xpReward: Int
)

data class WorldReward(
    val id: String,
    val name: String,
    val description: String,
    val xp: Int,
    val coins: Int
)

data class PlayerWorldProgress(
    val playerLevel: Int = 1,
    val experience: Int = 0,
    val coins: Int = 0,
    val unlockedLocations: Set<String> = emptySet(),
    val completedMissions: Set<String> = emptySet()
)
