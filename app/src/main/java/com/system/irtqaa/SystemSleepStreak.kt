package com.system.irtqaa

import java.time.LocalDate
import java.time.temporal.ChronoUnit

data class SystemSleepStreakResult(
    val currentStreak: Int,
    val longestStreak: Int,
    val recordedDays: Int
)

object SystemSleepStreak {

    fun calculate(
        records: List<SystemSleepRecord>
    ): SystemSleepStreakResult {

        val dates = records
            .filter { it.isValid }
            .map { it.date.toLocalDate() }
            .distinct()
            .sorted()

        if (dates.isEmpty()) {
            return SystemSleepStreakResult(0, 0, 0)
        }

        var longest = 1
        var current = 1

        for (index in 1 until dates.size) {
            val difference = ChronoUnit.DAYS.between(
                dates[index - 1],
                dates[index]
            )

            if (difference == 1L) {
                current++
            } else {
                current = 1
            }

            if (current > longest) {
                longest = current
            }
        }

        val today = LocalDate.now()
        val lastDate = dates.last()

        val activeStreak = if (
            ChronoUnit.DAYS.between(lastDate, today) <= 1
        ) current else 0

        return SystemSleepStreakResult(
            currentStreak = activeStreak,
            longestStreak = longest,
            recordedDays = dates.size
        )
    }
}
