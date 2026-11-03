
package com.system.irtqaa

data class SystemSleepRecommendationViewData(
    val text: String,
    val priority: SystemGuidancePriority,
    val isCompleted: Boolean
)

data class SystemSleepDashboardProgressViewData(
    val recommendations: List<SystemSleepRecommendationViewData>,
    val completedCount: Int,
    val remainingCount: Int,
    val totalCount: Int,
    val completionPercentage: Int,
    val progressLevel: SystemSleepProgressLevel
)

object SystemSleepDashboardProgressViewDataBuilder {

    fun build(
        dashboard: SystemSleepDashboardComplete
    ): SystemSleepDashboardProgressViewData {

        val prioritized =
            dashboard.progressDashboard.prioritizedGuidance
                .prioritizedRecommendations

        val progress =
            dashboard.progressDashboard.progress

        val recommendations = progress.map { item ->
            val priority = prioritized
                .firstOrNull { it.text == item.recommendation }
                ?.priority ?: SystemGuidancePriority.LOW

            SystemSleepRecommendationViewData(
                text = item.recommendation,
                priority = priority,
                isCompleted = item.isCompleted
            )
        }

        val summary = dashboard.progressSummary

        return SystemSleepDashboardProgressViewData(
            recommendations = recommendations,
            completedCount = summary.completedCount,
            remainingCount = summary.remainingCount,
            totalCount = summary.totalCount,
            completionPercentage = summary.completionPercentage,
            progressLevel = summary.level
        )
    }
}
