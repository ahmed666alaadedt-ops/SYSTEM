package com.system.irtqaa

import java.time.LocalDate

enum class SystemFitnessReadinessLevel {
    HIGH,
    MODERATE,
    LOW,
    INSUFFICIENT_DATA
}

data class SystemFitnessReadinessResult(
    val score: Int?,
    val level: SystemFitnessReadinessLevel,
    val recommendation: String,
    val sleepHours: Double?,
    val energyLevel: Int?,
    val sorenessLevel: Int?
)

class SystemFitnessReadiness(
    private val recoveryTracker: SystemFitnessRecoveryTracker,
    private val activityLog: SystemFitnessActivityLog
) {

    fun calculateReadiness(
        date: LocalDate = LocalDate.now()
    ): SystemFitnessReadinessResult {

        val recovery = recoveryTracker.getCheckIn(date)

        if (recovery == null) {
            return SystemFitnessReadinessResult(
                score = null,
                level = SystemFitnessReadinessLevel.INSUFFICIENT_DATA,
                recommendation = "سجل نومك وطاقتك ومستوى إجهادك أولاً",
                sleepHours = null,
                energyLevel = null,
                sorenessLevel = null
            )
        }

        val todayMinutes = activityLog
            .getActivitiesForDate(date)
            .sumOf { it.durationMinutes }

        val sleepScore = when {
            recovery.sleepHours >= 8.0 -> 100
            recovery.sleepHours >= 7.0 -> 85
            recovery.sleepHours >= 6.0 -> 65
            recovery.sleepHours >= 5.0 -> 40
            else -> 20
        }

        val energyScore = recovery.energyLevel * 20

        val sorenessScore = (6 - recovery.sorenessLevel) * 20

        val activityScore = when {
            todayMinutes >= 90 -> 40
            todayMinutes >= 60 -> 60
            todayMinutes >= 30 -> 80
            todayMinutes > 0 -> 90
            else -> 100
        }

        val score = (
            sleepScore * 0.35 +
                energyScore * 0.30 +
                sorenessScore * 0.25 +
                activityScore * 0.10
            ).toInt().coerceIn(0, 100)

        val level = when {
            score >= 80 -> SystemFitnessReadinessLevel.HIGH
            score >= 60 -> SystemFitnessReadinessLevel.MODERATE
            else -> SystemFitnessReadinessLevel.LOW
        }

        val recommendation = when (level) {
            SystemFitnessReadinessLevel.HIGH ->
                "مؤشراتك جيدة، اختر تمريناً مناسباً لقدرتك"

            SystemFitnessReadinessLevel.MODERATE ->
                "خفف شدة التمرين وراقب استجابة جسمك"

            SystemFitnessReadinessLevel.LOW ->
                "يفضل الراحة أو نشاط خفيف حسب شعورك"

            SystemFitnessReadinessLevel.INSUFFICIENT_DATA ->
                "تحتاج إلى تسجيل بيانات إضافية"
        }

        return SystemFitnessReadinessResult(
            score = score,
            level = level,
            recommendation = recommendation,
            sleepHours = recovery.sleepHours,
            energyLevel = recovery.energyLevel,
            sorenessLevel = recovery.sorenessLevel
        )
    }
}
