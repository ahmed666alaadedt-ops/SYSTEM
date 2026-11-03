package com.system.irtqaa

import android.content.Context

data class SystemSleepDashboardWithLifestyle(
    val sleepDashboard: SystemSleepDashboard,
    val lifestyleReport: SystemSleepLifestyleReport?
)

class SystemSleepDashboardLifestyleBuilder(context: Context) {

    private val sleepDashboardBuilder =
        SystemSleepDashboardBuilder(
            manager = SystemSleepManager(context),
            streakService = SystemSleepStreakService(context)
        )

    private val lifestyleManager =
        SystemSleepLifestyleManager(context)

    fun build(userId: String): SystemSleepDashboardWithLifestyle {

        require(userId.isNotBlank()) {
            "User ID cannot be blank"
        }

        val sleepDashboard =
            sleepDashboardBuilder.build(userId)

        val lifestyleReport =
            lifestyleManager.getReport(userId)

        return SystemSleepDashboardWithLifestyle(
            sleepDashboard = sleepDashboard,
            lifestyleReport = lifestyleReport
        )
    }
}
