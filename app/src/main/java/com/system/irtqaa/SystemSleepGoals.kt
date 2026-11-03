package com.system.irtqaa

data class SystemSleepGoal(
    val targetMinutes: Long = 480L,
    val targetQuality: Double = 4.0,
    val consistencyDays: Int = 7
)

data class SystemSleepGoalProgress(
    val sleepTargetReached: Boolean,
    val qualityTargetReached: Boolean,
    val consistencyTargetReached: Boolean,
    val completedGoals: Int,
    val totalGoals: Int
)

object SystemSleepGoals {

    fun evaluate(
        analysis: SystemSleepAnalysis,
        goal: SystemSleepGoal = SystemSleepGoal()
    ): SystemSleepGoalProgress {

        val sleepReached =
            analysis.averageSleepMinutes >= goal.targetMinutes

        val qualityReached =
            analysis.averageQuality >= goal.targetQuality

        val consistencyReached =
            analysis.analyzedDays >= goal.consistencyDays

        val completed = listOf(
            sleepReached,
            qualityReached,
            consistencyReached
        ).count { it }

        return SystemSleepGoalProgress(
            sleepTargetReached = sleepReached,
            qualityTargetReached = qualityReached,
            consistencyTargetReached = consistencyReached,
            completedGoals = completed,
            totalGoals = 3
        )
    }
}
