package com.system.irtqaa

enum class SystemPlayerRank {
    BEGINNER,
    BRONZE,
    SILVER,
    GOLD,
    PLATINUM,
    DIAMOND,
    ELITE,
    LEGEND
}

data class SystemPlayerProfile(
    val playerId: String,
    val playerName: String,
    val membershipNumber: String,
    val rank: SystemPlayerRank = SystemPlayerRank.BEGINNER,
    val level: Int = 1,
    val experience: Int = 0,
    val avatarImage: String? = null,
    val title: String = "عضو جديد",
    val badges: List<String> = emptyList(),
    val achievements: List<String> = emptyList(),
    val joinedAt: Long = 0L
)

object SystemPlayerProfileEngine {

    fun calculateRank(level: Int): SystemPlayerRank {
        return when {
            level >= 100 -> SystemPlayerRank.LEGEND
            level >= 80 -> SystemPlayerRank.ELITE
            level >= 60 -> SystemPlayerRank.DIAMOND
            level >= 40 -> SystemPlayerRank.PLATINUM
            level >= 25 -> SystemPlayerRank.GOLD
            level >= 15 -> SystemPlayerRank.SILVER
            level >= 5 -> SystemPlayerRank.BRONZE
            else -> SystemPlayerRank.BEGINNER
        }
    }

    fun updateLevel(
        profile: SystemPlayerProfile,
        newLevel: Int,
        newExperience: Int
    ): SystemPlayerProfile {
        val safeLevel = newLevel.coerceAtLeast(1)

        return profile.copy(
            level = safeLevel,
            experience = newExperience.coerceAtLeast(0),
            rank = calculateRank(safeLevel)
        )
    }

    fun addBadge(
        profile: SystemPlayerProfile,
        badge: String
    ): SystemPlayerProfile {
        if (badge.isBlank() || badge in profile.badges) {
            return profile
        }

        return profile.copy(
            badges = profile.badges + badge
        )
    }

    fun addAchievement(
        profile: SystemPlayerProfile,
        achievement: String
    ): SystemPlayerProfile {
        if (
            achievement.isBlank() ||
            achievement in profile.achievements
        ) {
            return profile
        }

        return profile.copy(
            achievements = profile.achievements + achievement
        )
    }
}
