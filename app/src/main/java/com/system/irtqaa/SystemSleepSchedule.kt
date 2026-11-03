package com.system.irtqaa

import java.time.Duration
import java.time.LocalTime

data class SystemSleepSchedule(
    val bedtime: LocalTime,
    val wakeUpTime: LocalTime,
    val targetHours: Int = 8,
    val enabled: Boolean = true
) {
    fun plannedSleepMinutes(): Long {
        var duration = Duration.between(bedtime, wakeUpTime)

        if (duration.isNegative || duration.isZero) {
            duration = duration.plusDays(1)
        }

        return duration.toMinutes()
    }

    fun targetSleepMinutes(): Int {
        return targetHours.coerceIn(1, 24) * 60
    }

    fun isTargetAchieved(): Boolean {
        return plannedSleepMinutes() >= targetSleepMinutes()
    }

    fun isValid(): Boolean {
        return targetHours in 1..24 &&
            bedtime != wakeUpTime
    }
}
