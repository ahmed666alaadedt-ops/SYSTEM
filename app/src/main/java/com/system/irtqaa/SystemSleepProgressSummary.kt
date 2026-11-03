
package com.system.irtqaa

enum class SystemSleepProgressLevel {
    NOT_STARTED,
    BEGINNER,
    DEVELOPING,
    ADVANCED,
    COMPLETED
}

data class SystemSleepProgressSummary(
    val completedCount: Int,
    val remainingCount: Int,
    val totalCount: Int,
    val completionPercentage: Int,
    val level: SystemSleepProgressLevel
)

object SystemSleepProgressSummaryBuilder {

    fun build(
        dashboard: SystemSleepDashboardProgress
    ): SystemSleepProgressSummary {

        val completed = dashboard.completedCount
        val remaining = dashboard.remainingCount
        val total = dashboard.progress.size

        val percentage = if (total == 0) {
            0
        } else {
            (completed * 100f / total).toInt()
        }

        val level = when {
            total == 0 ->
                SystemSleepProgressLevel.NOT_STARTED

            percentage == 100 ->
                SystemSleepProgressLevel.COMPLETED

            percentage >= 75 ->
                SystemSleepProgressLevel.ADVANCED

            percentage >= 40 ->
                SystemSleepProgressLevel.DEVELOPING

            else ->
                SystemSleepProgressLevel.BEGINNER
        }

        return SystemSleepProgressSummary(
            completedCount = completed,
            remainingCount = remaining,
            totalCount = total,
            completionPercentage = percentage,
            level = level
        )
    }
}
