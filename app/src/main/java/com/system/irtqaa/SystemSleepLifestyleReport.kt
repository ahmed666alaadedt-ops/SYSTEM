package com.system.irtqaa

data class SystemSleepLifestyleReport(
    val environment: SystemSleepEnvironmentResult,
    val habits: SystemSleepHabitsResult,
    val consistency: SystemSleepConsistencyResult,
    val overallScore: Int,
    val overallLevel: String,
    val recommendations: List<String>
)

object SystemSleepLifestyleReportBuilder {

    fun build(
        records: List<SystemSleepRecord>,
        environmentInput: SystemSleepEnvironmentInput,
        habitsInput: SystemSleepHabitsInput
    ): SystemSleepLifestyleReport {

        val environment =
            SystemSleepEnvironment.evaluate(environmentInput)

        val habits =
            SystemSleepHabits.evaluate(habitsInput)

        val consistency =
            SystemSleepConsistency.calculate(records)

        val overallScore = (
            environment.score * 0.30 +
            habits.score * 0.30 +
            consistency.consistencyScore * 0.40
        ).toInt().coerceIn(0, 100)

        val level = when {
            overallScore >= 90 -> "EXCELLENT"
            overallScore >= 75 -> "GOOD"
            overallScore >= 50 -> "MODERATE"
            else -> "NEEDS_IMPROVEMENT"
        }

        val recommendations = (
            environment.recommendations +
            habits.feedback
        ).distinct()

        return SystemSleepLifestyleReport(
            environment = environment,
            habits = habits,
            consistency = consistency,
            overallScore = overallScore,
            overallLevel = level,
            recommendations = recommendations
        )
    }
}
