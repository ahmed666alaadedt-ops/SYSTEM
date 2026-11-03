package com.system.irtqaa

// ========================================
// SYSTEM WORLD - CORE
// الإصدار الأول: الأساس الرئيسي للعالم
// ========================================

enum class WorldEra {
    PRESENT,
    PAST,
    FUTURE
}

enum class WorldRank {
    F, E, D, C, B, A, S, SS, SSS
}

enum class SkillType {
    SPEED,
    STRENGTH,
    MAGIC,
    FIRE,
    ICE,
    LIGHTNING,
    SHADOW,
    DEFENSE,
    HEALING,
    STEALTH,
    SWORD,
    ARCHERY,
    ENERGY,
    INTELLIGENCE,
    SENSING,
    SUMMONING
}

enum class SkillRarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY,
    MYTHICAL,
    UNIQUE,
    SECRET
}

enum class MonsterType {
    GHOST,
    DRAGON,
    DEMON,
    BEAST,
    UNDEAD,
    MYTHICAL,
    ANCIENT,
    UNKNOWN
}

enum class QuestType {
    STORY,
    DAILY,
    EXPLORATION,
    COMBAT,
    PUZZLE,
    HIDDEN,
    SEASONAL,
    CITY_EVENT
}

// ========================================
// اللاعب
// ========================================

data class WorldPlayer(
    val playerId: String,
    val characterName: String,
    val level: Int = 1,
    val rank: WorldRank = WorldRank.F,
    val experience: Long = 0,
    val health: Int = 100,
    val energy: Int = 100,
    val strength: Int = 5,
    val speed: Int = 5,
    val defense: Int = 5,
    val intelligence: Int = 5,
    val skills: List<WorldSkill> = emptyList(),
    val coins: Long = 0,
    val currentEra: WorldEra = WorldEra.PRESENT
)

// ========================================
// المهارات والقدرات
// ========================================

data class WorldSkill(
    val skillId: String,
    val name: String,
    val description: String,
    val type: SkillType,
    val rarity: SkillRarity,
    val level: Int = 1,
    val maxLevel: Int = 100,
    val experience: Long = 0,
    val unlocked: Boolean = false
)

// ========================================
// الوحوش والكائنات الأسطورية
// ========================================

data class WorldMonster(
    val monsterId: String,
    val name: String,
    val description: String,
    val type: MonsterType,
    val level: Int,
    val rank: WorldRank,
    val health: Long,
    val attackPower: Long,
    val defense: Long,
    val experienceReward: Long,
    val coinReward: Long,
    val isBoss: Boolean = false,
    val isRare: Boolean = false
)

// ========================================
// المهام والألغاز
// ========================================

data class WorldQuest(
    val questId: String,
    val title: String,
    val description: String,
    val type: QuestType,
    val requiredLevel: Int = 1,
    val experienceReward: Long = 0,
    val coinReward: Long = 0,
    val isCompleted: Boolean = false,
    val isHidden: Boolean = false
)

// ========================================
// الجزر والمواسم
// ========================================

data class WorldIsland(
    val islandId: String,
    val name: String,
    val description: String,
    val requiredLevel: Int,
    val isSeasonal: Boolean,
    val isUnlocked: Boolean = false,
    val quests: List<WorldQuest> = emptyList(),
    val monsters: List<WorldMonster> = emptyList()
)

// ========================================
// الألغاز
// ========================================

data class WorldPuzzle(
    val puzzleId: String,
    val title: String,
    val description: String,
    val difficulty: Int,
    val experienceReward: Long,
    val coinReward: Long,
    val isSolved: Boolean = false
)

// ========================================
// الأحداث داخل المدن
// ========================================

data class WorldCityEvent(
    val eventId: String,
    val title: String,
    val description: String,
    val monsterIds: List<String> = emptyList(),
    val questId: String? = null,
    val isActive: Boolean = false
)

// ========================================
// المكافآت
// ========================================

data class WorldReward(
    val experience: Long = 0,
    val coins: Long = 0,
    val unlockedSkills: List<String> = emptyList(),
    val specialItems: List<String> = emptyList()
)

// ========================================
// النظام الأساسي للعالم
// ========================================

object SystemWorldCore {

    const val WORLD_NAME = "SYSTEM WORLD"

    const val INITIAL_PLAYER_LEVEL = 1

    const val MAX_SKILL_LEVEL = 100

    const val INITIAL_HEALTH = 100

    const val INITIAL_ENERGY = 100

    fun createPlayer(
        playerId: String,
        characterName: String
    ): WorldPlayer {
        return WorldPlayer(
            playerId = playerId,
            characterName = characterName
        )
    }

    fun calculateLevel(experience: Long): Int {
        if (experience <= 0) return 1

        return (experience / 1000).toInt() + 1
    }

    fun calculateSkillLevel(experience: Long): Int {
        if (experience <= 0) return 1

        return ((experience / 100).toInt() + 1)
            .coerceAtMost(MAX_SKILL_LEVEL)
    }
}
