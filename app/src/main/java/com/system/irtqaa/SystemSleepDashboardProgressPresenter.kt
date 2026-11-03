
package com.system.irtqaa

class SystemSleepDashboardProgressPresenter(
    private val progressController: SystemSleepDashboardProgressController
) {

    fun present(
        dashboard: SystemSleepDashboardComplete
    ): SystemSleepDashboardProgressViewData {

        return SystemSleepDashboardProgressViewDataBuilder.build(
            dashboard
        )
    }

    fun updateAndPresent(
        dashboard: SystemSleepDashboardComplete,
        recommendation: String,
        completed: Boolean
    ): SystemSleepDashboardProgressViewData {

        val updatedProgress =
            progressController.updateRecommendation(
                dashboard = dashboard.progressDashboard,
                recommendation = recommendation,
                completed = completed
            )

        val updatedSummary =
            SystemSleepProgressSummaryBuilder.build(updatedProgress)

        val updatedDashboard = dashboard.copy(
            progressDashboard = updatedProgress,
            progressSummary = updatedSummary
        )

        return SystemSleepDashboardProgressViewDataBuilder.build(
            updatedDashboard
        )
    }
}
