
package com.system.irtqaa

class SystemSleepDashboardProgressController(
    private val progressManager: SystemSleepRecommendationProgressManager
) {

    fun updateRecommendation(
        dashboard: SystemSleepDashboardProgress,
        recommendation: String,
        completed: Boolean
    ): SystemSleepDashboardProgress {

        val recommendations =
            dashboard.prioritizedGuidance.guidance.recommendations

        val updatedProgress =
            progressManager.updateCompletion(
                recommendations = recommendations,
                recommendation = recommendation,
                completed = completed
            )

        return dashboard.copy(
            progress = updatedProgress,
            completedCount =
                SystemSleepRecommendationProgressEngine.completedCount(
                    updatedProgress
                ),
            remainingCount =
                SystemSleepRecommendationProgressEngine.remainingCount(
                    updatedProgress
                ),
            completionPercentage =
                SystemSleepRecommendationProgressEngine.completionPercentage(
                    updatedProgress
                )
        )
    }
}
