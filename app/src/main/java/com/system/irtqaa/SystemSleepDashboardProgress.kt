
package com.system.irtqaa

data class SystemSleepDashboardProgress(
    val prioritizedGuidance: SystemSleepDashboardPrioritizedGuidance,
    val progress: List<SystemSleepRecommendationProgressItem>,
    val completedCount: Int,
    val remainingCount: Int,
    val completionPercentage: Int
)

object SystemSleepDashboardProgressBuilder {

    fun build(
        prioritizedGuidance: SystemSleepDashboardPrioritizedGuidance,
        progressManager: SystemSleepRecommendationProgressManager
    ): SystemSleepDashboardProgress {

        val recommendations =
            prioritizedGuidance.guidance.recommendations

        val progress =
            progressManager.getProgress(recommendations)

        return SystemSleepDashboardProgress(
            prioritizedGuidance = prioritizedGuidance,
            progress = progress,
            completedCount =
                SystemSleepRecommendationProgressEngine.completedCount(progress),
            remainingCount =
                SystemSleepRecommendationProgressEngine.remainingCount(progress),
            completionPercentage =
                SystemSleepRecommendationProgressEngine.completionPercentage(progress)
        )
    }
}
