
package com.system.irtqaa

import android.content.Context

/**
 * Coordinates the fitness engine with local persistence.
 */
class SystemFitnessManager(
    context: Context,
    private val userId: String,
    private val engine: SystemFitnessEngine = SystemFitnessEngine()
) {
    private val storage = SystemFitnessStorage(context.applicationContext)

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be blank"
        }

        val savedProfile = storage.loadProfile(userId)
        if (savedProfile != null) {
            engine.saveProfile(savedProfile)

            storage.loadMeasurements(userId).forEach { measurement ->
                engine.addMeasurement(measurement)
            }
        }
    }

    fun saveProfile(profile: SystemFitnessProfile): Boolean {
        if (profile.userId != userId) return false
        if (!profile.hasUserConsentToStore) return false

        if (!storage.saveProfile(profile)) return false
        return engine.saveProfile(profile)
    }

    fun getProfile(): SystemFitnessProfile? {
        return engine.getProfile(userId)
    }

    fun addMeasurement(measurement: SystemFitnessMeasurement): Boolean {
        if (measurement.userId != userId) return false
        if (!engine.addMeasurement(measurement)) return false

        val saved = storage.saveMeasurements(
            userId,
            engine.getMeasurements(userId)
        )

        if (!saved) {
            engine.deleteMeasurement(userId, measurement.measurementId)
        }

        return saved
    }

    fun getMeasurements(): List<SystemFitnessMeasurement> {
        return engine.getMeasurements(userId)
    }

    fun getProgressSummary(): SystemFitnessProgressSummary {
        return engine.getProgressSummary(userId)
    }

    fun deleteMeasurement(measurementId: String): Boolean {
        val current = engine.getMeasurements(userId)
        if (current.none { it.measurementId == measurementId }) return false

        val updated = current.filterNot {
            it.measurementId == measurementId
        }

        if (!storage.saveMeasurements(userId, updated)) return false

        return engine.deleteMeasurement(userId, measurementId)
    }

    fun revokeConsent(): Boolean {
        val removed = storage.revokeConsent(userId)
        engine.revokeStorageConsent(userId)
        return removed
    }
}
