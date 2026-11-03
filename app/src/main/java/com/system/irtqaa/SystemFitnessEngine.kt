package com.system.irtqaa

import java.time.LocalDate

class SystemFitnessEngine {

    private val measurements =
        mutableMapOf<String, MutableList<SystemFitnessMeasurement>>()

    private val profiles =
        mutableMapOf<String, SystemFitnessProfile>()

    fun saveProfile(profile: SystemFitnessProfile): Boolean {
        if (!profile.hasUserConsentToStore) return false
        profiles[profile.userId] = profile
        return true
    }

    fun getProfile(userId: String): SystemFitnessProfile? {
        return profiles[userId]
    }

    fun revokeStorageConsent(userId: String) {
        profiles.remove(userId)
        measurements.remove(userId)
    }

    fun addMeasurement(
        measurement: SystemFitnessMeasurement
    ): Boolean {
        val profile = profiles[measurement.userId]
            ?: return false

        if (!profile.hasUserConsentToStore) return false

        val userMeasurements =
            measurements.getOrPut(measurement.userId) {
                mutableListOf()
            }

        if (userMeasurements.any {
                it.measurementId == measurement.measurementId
            }) return false

        userMeasurements.add(measurement)
        userMeasurements.sortBy { it.recordedOn }

        return true
    }

    fun getMeasurements(
        userId: String
    ): List<SystemFitnessMeasurement> {
        return measurements[userId]?.toList() ?: emptyList()
    }

    fun getProgressSummary(
        userId: String
    ): SystemFitnessProgressSummary {
        val profile = profiles[userId]
        val records = getMeasurements(userId)

        return SystemFitnessProgressSummary(
            firstRecordedWeightKg =
                records.firstOrNull { it.weightKg != null }?.weightKg,
            latestRecordedWeightKg =
                records.lastOrNull { it.weightKg != null }?.weightKg,
            targetWeightKg = profile?.targetWeightKg,
            totalMeasurements = records.size,
            lastRecordedOn = records.lastOrNull()?.recordedOn
        )
    }

    fun deleteMeasurement(
        userId: String,
        measurementId: String
    ): Boolean {
        return measurements[userId]?.removeAll {
            it.measurementId == measurementId
        } ?: false
    }
}
