package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.util.UUID

enum class SystemFitnessAchievementType {
    FIRST_ACTIVITY,
    FIRST_HOUR,
    FIVE_ACTIVE_DAYS,
    WEEKLY_TARGET,
    TOTAL_TEN_HOURS,
    CONSISTENCY
}

data class SystemFitnessAchievement(
    val achievementId: String,
    val type: SystemFitnessAchievementType,
    val title: String,
    val description: String,
    val unlockedDate: String,
    val rewardXP: Int
)

class SystemFitnessAchievements(
    context: Context,
    private val userId: String
) {

    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_fitness_achievements",
            Context.MODE_PRIVATE
        )

    private val storageKey = "achievements_$userId"

    init {
        require(userId.isNotBlank())
    }

    @Synchronized
    fun getAchievements(): List<SystemFitnessAchievement> {
        val saved = preferences.getString(storageKey, null)
            ?: return emptyList()

        return try {
            val array = JSONArray(saved)
            val result = mutableListOf<SystemFitnessAchievement>()

            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue

                try {
                    result.add(
                        SystemFitnessAchievement(
                            achievementId = item.getString("id"),
                            type = SystemFitnessAchievementType.valueOf(
                                item.getString("type")
                            ),
                            title = item.getString("title"),
                            description = item.getString("description"),
                            unlockedDate = item.getString("date"),
                            rewardXP = item.getInt("xp")
                        )
                    )
                } catch (exception: Exception) {
                    continue
                }
            }

            result
        } catch (exception: Exception) {
            emptyList()
        }
    }

    @Synchronized
    fun evaluateAchievements(
        activityLog: SystemFitnessActivityLog,
        date: LocalDate = LocalDate.now(),
        weeklyTargetDays: Int = 3
    ): List<SystemFitnessAchievement> {

        require(weeklyTargetDays in 1..7)

        val existing = getAchievements().toMutableList()
        val unlockedTypes = existing.map { it.type }.toSet()

        val activities = activityLog.getAllActivities()

        val totalMinutes = activities.sumOf {
            it.durationMinutes
        }

        val activeDays = activities
            .map { it.date }
            .distinct()
            .size

        val weekStart = date.minusDays(
            (date.dayOfWeek.value - 1).toLong()
        )

        val weekEnd = weekStart.plusDays(6)

        val weeklyDays = activities
            .filter {
                val activityDate = LocalDate.parse(it.date)

                !activityDate.isBefore(weekStart) &&
                    !activityDate.isAfter(weekEnd)
            }
            .map { it.date }
            .distinct()
            .size

        val definitions = listOf(
            AchievementDefinition(
                SystemFitnessAchievementType.FIRST_ACTIVITY,
                "البداية الأولى",
                "سجلت أول نشاط رياضي",
                20,
                activities.isNotEmpty()
            ),
            AchievementDefinition(
                SystemFitnessAchievementType.FIRST_HOUR,
                "الساعة الأولى",
                "أكملت 60 دقيقة من النشاط",
                30,
                totalMinutes >= 60
            ),
            AchievementDefinition(
                SystemFitnessAchievementType.FIVE_ACTIVE_DAYS,
                "خمسة أيام نشاط",
                "مارست نشاطاً في خمسة أيام مختلفة",
                50,
                activeDays >= 5
            ),
            AchievementDefinition(
                SystemFitnessAchievementType.WEEKLY_TARGET,
                "هدف الأسبوع",
                "حققت هدف أيام النشاط الأسبوعي",
                40,
                weeklyDays >= weeklyTargetDays
            ),
            AchievementDefinition(
                SystemFitnessAchievementType.TOTAL_TEN_HOURS,
                "عشر ساعات",
                "جمعت 600 دقيقة من النشاط",
                100,
                totalMinutes >= 600
            ),
            AchievementDefinition(
                SystemFitnessAchievementType.CONSISTENCY,
                "الاستمرارية",
                "سجلت نشاطاً خلال أربعة أسابيع مختلفة",
                100,
                activities.map {
                    LocalDate.parse(it.date)
                        .with(java.time.DayOfWeek.MONDAY)
                        .toString()
                }.distinct().size >= 4
            )
        )

        val newlyUnlocked = definitions
            .filter {
                it.isAchieved && it.type !in unlockedTypes
            }
            .map { definition ->
                SystemFitnessAchievement(
                    achievementId = UUID.randomUUID().toString(),
                    type = definition.type,
                    title = definition.title,
                    description = definition.description,
                    unlockedDate = date.toString(),
                    rewardXP = definition.rewardXP
                )
            }

        if (newlyUnlocked.isNotEmpty()) {
            existing.addAll(newlyUnlocked)
            saveAchievements(existing)
        }

        return newlyUnlocked
    }

    fun getTotalAchievementXP(): Int {
        return getAchievements().sumOf {
            it.rewardXP
        }
    }

    @Synchronized
    fun clearAchievements() {
        preferences.edit()
            .remove(storageKey)
            .apply()
    }

    private fun saveAchievements(
        achievements: List<SystemFitnessAchievement>
    ) {
        val array = JSONArray()

        achievements.forEach { achievement ->
            val item = JSONObject()

            item.put("id", achievement.achievementId)
            item.put("type", achievement.type.name)
            item.put("title", achievement.title)
            item.put("description", achievement.description)
            item.put("date", achievement.unlockedDate)
            item.put("xp", achievement.rewardXP)

            array.put(item)
        }

        preferences.edit()
            .putString(storageKey, array.toString())
            .apply()
    }

    private data class AchievementDefinition(
        val type: SystemFitnessAchievementType,
        val title: String,
        val description: String,
        val rewardXP: Int,
        val isAchieved: Boolean
    )
}
