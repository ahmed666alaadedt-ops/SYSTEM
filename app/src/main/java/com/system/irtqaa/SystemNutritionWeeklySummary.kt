package com.system.irtqaa

import java.time.DayOfWeek
import java.time.LocalDate

data class SystemNutritionHabitWeeklyStats(
    val habit: SystemNutritionHabit,
    val completedDays: Int,
    val totalDays: Int,
    val completionPercentage: Int
)

data class SystemNutritionWeeklySummary(
    val startDate: String,
    val endDate: String,
    val totalDays: Int,
    val daysWithCompletedHabits: Int,
    val totalCompletedHabits: Int,
    val possibleHabitCompletions: Int,
    val completionPercentage: Int,
    val habitStatistics: List<SystemNutritionHabitWeeklyStats>,
    val dailyPercentages: Map<String, Int>
) {
    val bestHabit: SystemNutritionHabitWeeklyStats?
        get() = habitStatistics
            .filter { it.completedDays > 0 }
            .maxByOrNull { it.completedDays }

    val leastCompletedHabit: SystemNutritionHabitWeeklyStats?
        get() = habitStatistics
            .filter { it.completedDays < totalDays }
            .minByOrNull { it.completedDays }

    val fullyCompletedDays: Int
        get() = dailyPercentages.values.count { it == 100 }
}

class SystemNutritionWeeklySummaryEngine(
    private val tracker: SystemNutritionHabitTracker
) {

    fun buildWeeklySummary(
        referenceDate: LocalDate = LocalDate.now()
    ): SystemNutritionWeeklySummary {

        val startDate = referenceDate.with(
            DayOfWeek.MONDAY
        )

        val endDate = startDate.plusDays(6)

        val dates = (0L..6L).map {
            startDate.plusDays(it)
        }

        val dailyRecords = dates.map { date ->
            tracker.getDailyRecord(date)
        }

        val totalDays = dates.size
        val totalHabits = SystemNutritionHabit.values().size

        val completedCount = dailyRecords.sumOf {
            it.completedCount
        }

        val possibleCompletions = totalDays * totalHabits

        val overallPercentage = if (
            possibleCompletions > 0
        ) {
            (completedCount * 100) / possibleCompletions
        } else {
            0
        }

        val daysWithCompletedHabits = dailyRecords.count {
            it.completedCount > 0
        }

        val habitStatistics = SystemNutritionHabit.values()
            .map { habit ->

                val completedDays = dailyRecords.count {
                    habit in it.completedHabits
                }

                val percentage = if (totalDays > 0) {
                    (completedDays * 100) / totalDays
                } else {
                    0
                }

                SystemNutritionHabitWeeklyStats(
                    habit = habit,
                    completedDays = completedDays,
                    totalDays = totalDays,
                    completionPercentage = percentage
                )
            }

        val dailyPercentages = dailyRecords.associate {
            record ->
            record.date to record.completionPercentage
        }

        return SystemNutritionWeeklySummary(
            startDate = startDate.toString(),
            endDate = endDate.toString(),
            totalDays = totalDays,
            daysWithCompletedHabits = daysWithCompletedHabits,
            totalCompletedHabits = completedCount,
            possibleHabitCompletions = possibleCompletions,
            completionPercentage = overallPercentage,
            habitStatistics = habitStatistics,
            dailyPercentages = dailyPercentages
        )
    }

    fun getWeeklyProgressMessage(
        summary: SystemNutritionWeeklySummary
    ): String {

        return when {
            summary.completionPercentage >= 90 ->
                "التزام غذائي ممتاز! حافظ على هذا المستوى."

            summary.completionPercentage >= 70 ->
                "أداؤك جيد جداً، استمر بالتقدم."

            summary.completionPercentage >= 40 ->
                "أنت تتقدم، حاول تثبيت عاداتك اليومية."

            summary.completionPercentage > 0 ->
                "بداية جيدة، خطوة صغيرة كل يوم تصنع فرقاً."

            else ->
                "ابدأ اليوم بعادة صحية واحدة، ثم أضف غيرها."
        }
    }

    fun getHabitProgress(
        habit: SystemNutritionHabit,
        referenceDate: LocalDate = LocalDate.now()
    ): SystemNutritionHabitWeeklyStats {

        return buildWeeklySummary(referenceDate)
            .habitStatistics
            .first { it.habit == habit }
    }
}
