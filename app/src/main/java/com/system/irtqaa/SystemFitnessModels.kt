
package com.system.irtqaa

import java.time.LocalDate

enum class SystemFitnessActivityLevel {
    BEGINNER,
    LIGHT,
    MODERATE,
    ACTIVE
}

data class SystemFitnessProfile(
    val userId: String,
    val goal: SystemFitnessGoal = SystemFitnessGoal.GENERAL_HEALTH,
    val heightCm: Double? = null,
    val currentWeightKg: Double? = null,
    val targetWeightKg: Double? = null,
    val activityLevel: SystemFitnessActivityLevel =
        SystemFitnessActivityLevel.BEGINNER,
    val healthNotes: String = "",
    val hasUserConsentToStore: Boolean = false,
    val updatedAt: Long = System.currentTimeMillis()
) {
    init {
        require(userId.isNotBlank())
        require(heightCm == null || heightCm in 80.0..250.0)
        require(currentWeightKg == null || currentWeightKg in 20.0..500.0)
        require(targetWeightKg == null || targetWeightKg in 20.0..500.0)
    }

    val hasEnoughDataForProgressTracking: Boolean
        get() = hasUserConsentToStore &&
            currentWeightKg != null &&
            targetWeightKg != null
}

data class SystemFitnessMeasurement(
    val measurementId: String,
    val userId: String,
    val recordedOn: LocalDate,
    val weightKg: Double? = null,
    val waistCm: Double? = null,
    val note: String = ""
) {
    init {
        require(measurementId.isNotBlank())
        require(userId.isNotBlank())
        require(weightKg == null || weightKg in 20.0..500.0)
        require(waistCm == null || waistCm in 30.0..250.0)
        require(
            weightKg != null ||
            waistCm != null ||
            note.isNotBlank()
        )
    }
}

data class SystemFitnessProgressSummary(
    val firstRecordedWeightKg: Double?,
    val latestRecordedWeightKg: Double?,
    val targetWeightKg: Double?,
    val totalMeasurements: Int,
    val lastRecordedOn: LocalDate?
) {
    val weightChangeKg: Double?
        get() = if (
            firstRecordedWeightKg == null ||
            latestRecordedWeightKg == null
        ) null else latestRecordedWeightKg - firstRecordedWeightKg
}
