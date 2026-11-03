package com.system.irtqaa

data class SystemSleepHabitsInput(
    val exercisedToday: Boolean,
    val hadLateMeal: Boolean,
    val usedRelaxation: Boolean,
    val followedSleepSchedule: Boolean,
    val tookDaytimeNap: Boolean
)

data class SystemSleepHabitsResult(
    val score: Int,
    val level: String,
    val feedback: List<String>
)

object SystemSleepHabits {

    fun evaluate(
        input: SystemSleepHabitsInput
    ): SystemSleepHabitsResult {

        var score = 0
        val feedback = mutableListOf<String>()

        if (input.exercisedToday) score += 20

        if (input.hadLateMeal) {
            feedback.add("حاول تجنب الوجبات الثقيلة قرب النوم")
        } else {
            score += 20
        }

        if (input.usedRelaxation) score += 20

        if (input.followedSleepSchedule) {
            score += 20
        } else {
            feedback.add("حاول الالتزام بموعد نوم ثابت")
        }

        if (input.tookDaytimeNap) {
            feedback.add("راقب تأثير القيلولة على نوم الليل")
        } else {
            score += 20
        }

        val level = when {
            score >= 80 -> "EXCELLENT"
            score >= 60 -> "GOOD"
            score >= 40 -> "MODERATE"
            else -> "NEEDS_IMPROVEMENT"
        }

        return SystemSleepHabitsResult(
            score = score,
            level = level,
            feedback = feedback
        )
    }
}
