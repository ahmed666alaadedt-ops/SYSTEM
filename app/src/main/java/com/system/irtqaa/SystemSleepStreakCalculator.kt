package com.system.irtqaa

import java.time.LocalDate
import java.time.temporal.ChronoUnit

data class SystemSleepStreakCalculation(
    val currentStreak: Int,
    val longestStreak: Int,
    val recordedDays: Int
)

object SystemSleepStreakCalculator {

    fun calculate(
        records: List<SystemSleepRecord>,
        today: LocalDate = LocalDate.now()
    ): SystemSleepStreakCalculation {

        val dates = records
            .filter { it.isValid }
            .map { it.date }
            .distinct()
            .sorted()

        if (dates.isEmpty()) {
            return SystemSleepStreakCalculation(0, 0, 0)
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

        val lastDate = dates.last()

        val activeStreak = if (
            ChronoUnit.DAYS.between(lastDate, today) in 0L..1L
        ) current else 0

        return SystemSleepStreakCalculation(
            currentStreak = activeStreak,
            longestStreak = longest,
            recordedDays = dates.size
        )
    }
}
