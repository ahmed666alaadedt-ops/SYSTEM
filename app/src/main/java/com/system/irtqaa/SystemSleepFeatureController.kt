package com.system.irtqaa

import android.content.Context
import java.time.LocalDateTime

class SystemSleepFeatureController(
    context: Context,
    private val userId: String = "local_user"
) {

    private val sleepManager =
        SystemSleepManager(context.applicationContext)

    private val dashboardBuilder =
        SystemSleepDashboardLifestyleBuilder(
            context.applicationContext
        )

    private val progressManager =
        SystemSleepRecommendationProgressManager(
            context.applicationContext
        )

    private val progressController =
        SystemSleepDashboardProgressController(
            progressManager
        )

    private val presenter =
        SystemSleepDashboardProgressPresenter(
            progressController
        )

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be blank"
        }
    }

    fun saveSleepRecord(
        bedtime: LocalDateTime,
        wakeUpTime: LocalDateTime,
        quality: Int,
        notes: String = ""
    ): Boolean {

        return sleepManager.saveSleepRecord(
            userId = userId,
            bedtime = bedtime,
            wakeUpTime = wakeUpTime,
            quality = quality,
            notes = notes
        )
    }

    fun getDashboard():
        SystemSleepDashboardProgressViewData {

        val dashboard =
            dashboardBuilder.build(userId)

        val guidance =
            SystemSleepDashboardGuidanceBuilder.build(
                dashboard
            )

        val prioritizedGuidance =
            SystemSleepDashboardPrioritizedGuidanceBuilder.build(
                guidance
            )

        val completeDashboard =
            SystemSleepDashboardCompleteBuilder.build(
                prioritizedGuidance = prioritizedGuidance,
                progressManager = progressManager
            )

        return presenter.present(completeDashboard)
    }

    fun updateRecommendation(
        recommendation: String,
        completed: Boolean
    ): SystemSleepDashboardProgressViewData {

        val dashboard =
            dashboardBuilder.build(userId)

        val guidance =
            SystemSleepDashboardGuidanceBuilder.build(
                dashboard
            )

        val prioritizedGuidance =
            SystemSleepDashboardPrioritizedGuidanceBuilder.build(
                guidance
            )

        val completeDashboard =
            SystemSleepDashboardCompleteBuilder.build(
                prioritizedGuidance = prioritizedGuidance,
                progressManager = progressManager
            )

        return presenter.updateAndPresent(
            dashboard = completeDashboard,
            recommendation = recommendation,
            completed = completed
        )
    }
}
