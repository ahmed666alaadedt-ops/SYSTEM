
package com.system.irtqaa

data class SystemSleepDashboardPrioritizedGuidance(
    val guidance: SystemSleepDashboardGuidance,
    val prioritizedRecommendations: List<SystemPrioritizedRecommendation>
)

object SystemSleepDashboardPrioritizedGuidanceBuilder {

    fun build(
        guidance: SystemSleepDashboardGuidance
    ): SystemSleepDashboardPrioritizedGuidance {

        val prioritizedRecommendations =
            SystemSleepGuidancePriorityEngine.prioritize(
                guidance.recommendations
            )

        return SystemSleepDashboardPrioritizedGuidance(
            guidance = guidance,
            prioritizedRecommendations = prioritizedRecommendations
        )
    }
}
