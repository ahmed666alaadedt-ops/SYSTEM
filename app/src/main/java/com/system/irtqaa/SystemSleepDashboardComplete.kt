
package com.system.irtqaa

data class SystemSleepDashboardComplete(
    val progressDashboard: SystemSleepDashboardProgress,
    val progressSummary: SystemSleepProgressSummary
)

object SystemSleepDashboardCompleteBuilder {

    fun build(
        prioritizedGuidance: SystemSleepDashboardPrioritizedGuidance,
        progressManager: SystemSleepRecommendationProgressManager
    ): SystemSleepDashboardComplete {

        val progressDashboard =
            SystemSleepDashboardProgressBuilder.build(
                prioritizedGuidance = prioritizedGuidance,
                progressManager = progressManager
            )

        val progressSummary =
            SystemSleepProgressSummaryBuilder.build(
                dashboard = progressDashboard
            )

        return SystemSleepDashboardComplete(
            progressDashboard = progressDashboard,
            progressSummary = progressSummary
        )
    }
}
