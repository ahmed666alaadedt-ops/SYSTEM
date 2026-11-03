package com.system.irtqaa

import java.time.DayOfWeek
import java.time.LocalDate

data class SystemFitnessConsistencySummary(
    val weekStart: String,
    val weekEnd: String,
    val activeDays: Int,
    val targetActiveDays: Int,
    val completedTargetDays: Int,
    val consistencyPercentage: Int,
    val totalActivities: Int,
    val totalMinutes: Int,
    val remainingDays: Int
)

class SystemFitnessWeeklyConsistency(
    private val activityLog: SystemFitnessActivityLog
) {

    fun calculateWeeklyConsistency(
        referenceDate: LocalDate = LocalDate.now(),
        targetActiveDays: Int = 3
    ): SystemFitnessConsistencySummary {

        require(targetActiveDays in 1..7) {
            "Target active days must be between 1 and 7"
        }

        val weekStart = referenceDate.with(
            DayOfWeek.MONDAY
        )

        val weekEnd = weekStart.plusDays(6)

        val weeklyActivities = activityLog.getAllActivities()
            .filter { activity ->
                val activityDate = LocalDate.parse(activity.date)

                !activityDate.isBefore(weekStart) &&
                    !activityDate.isAfter(weekEnd)
            }

        val activeDays = weeklyActivities
            .map { it.date }
            .distinct()
            .size

        val completedDays = minOf(
            activeDays,
            targetActiveDays
        )

        val percentage = (
            completedDays * 100.0 / targetActiveDays
        ).toInt()

        val remainingDays = maxOf(
            0,
            targetActiveDays - completedDays
        )

        return SystemFitnessConsistencySummary(
            weekStart = weekStart.toString(),
            weekEnd = weekEnd.toString(),
            activeDays = activeDays,
            targetActiveDays = targetActiveDays,
            completedTargetDays = completedDays,
            consistencyPercentage = percentage,
            totalActivities = weeklyActivities.size,
            totalMinutes = weeklyActivities.sumOf {
                it.durationMinutes
            },
            remainingDays = remainingDays
        )
    }
}
