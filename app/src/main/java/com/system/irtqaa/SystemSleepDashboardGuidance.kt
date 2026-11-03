package com.system.irtqaa

data class SystemSleepDashboardGuidance(
    val dashboard: SystemSleepDashboardWithLifestyle,
    val recommendations: List<String>
)

object SystemSleepDashboardGuidanceBuilder {

    fun build(
        dashboard: SystemSleepDashboardWithLifestyle
    ): SystemSleepDashboardGuidance {

        val sleepRecommendations =
            dashboard.sleepDashboard.recommendations

        val lifestyleRecommendations =
            dashboard.lifestyleReport?.recommendations
                ?: emptyList()

        val combinedRecommendations =
            (sleepRecommendations + lifestyleRecommendations)
                .filter { it.isNotBlank() }
                .distinct()

        return SystemSleepDashboardGuidance(
            dashboard = dashboard,
            recommendations = combinedRecommendations
        )
    }
}
