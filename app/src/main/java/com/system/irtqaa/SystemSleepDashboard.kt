package com.system.irtqaa

data class SystemSleepDashboard(
    val analysis: SystemSleepAnalysis,
    val weeklyReport: SystemSleepWeeklyReport,
    val score: SystemSleepScore,
    val recovery: SystemSleepRecoveryResult,
    val streak: SystemSleepStreakCalculation,
    val recommendations: List<String>
)

class SystemSleepDashboardBuilder(
    private val manager: SystemSleepManager,
    private val streakService: SystemSleepStreakService
) {

    fun build(userId: String): SystemSleepDashboard {

        return SystemSleepDashboard(
            analysis = manager.getAnalysis(userId),
            weeklyReport = manager.getWeeklyReport(userId),
            score = manager.getSleepScore(userId),
            recovery = manager.getRecovery(userId),
            streak = streakService.getStreak(userId),
            recommendations = manager.getRecommendations(userId)
        )
    }
}
