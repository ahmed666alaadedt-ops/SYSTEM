package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate

class SystemFitnessStorage(context: Context) {

    private val preferences = context.getSharedPreferences(
        "system_fitness_storage",
        Context.MODE_PRIVATE
    )

    fun saveProfile(profile: SystemFitnessProfile): Boolean {
        if (!profile.hasUserConsentToStore) return false

        val json = JSONObject().apply {
            put("userId", profile.userId)
            put("goal", profile.goal.name)
            put("heightCm", profile.heightCm ?: JSONObject.NULL)
            put("currentWeightKg", profile.currentWeightKg ?: JSONObject.NULL)
            put("targetWeightKg", profile.targetWeightKg ?: JSONObject.NULL)
            put("activityLevel", profile.activityLevel.name)
            put("consent", true)
            put("updatedAt", profile.updatedAt)
        }

        return preferences.edit()
            .putString(profileKey(profile.userId), json.toString())
            .commit()
    }

    fun loadProfile(userId: String): SystemFitnessProfile? {
        val raw = preferences.getString(profileKey(userId), null)
            ?: return null

        return try {
            val json = JSONObject(raw)
            if (!json.optBoolean("consent", false)) return null

            SystemFitnessProfile(
                userId = json.getString("userId"),
                goal = SystemFitnessGoal.valueOf(json.getString("goal")),
                heightCm = json.optionalDouble("heightCm"),
                currentWeightKg = json.optionalDouble("currentWeightKg"),
                targetWeightKg = json.optionalDouble("targetWeightKg"),
                activityLevel = SystemFitnessActivityLevel.valueOf(
                    json.getString("activityLevel")
                ),
                healthNotes = "",
                hasUserConsentToStore = true,
                updatedAt = json.optLong("updatedAt")
            )
        } catch (_: Exception) {
            null
        }
    }

    fun saveMeasurements(
        userId: String,
        measurements: List<SystemFitnessMeasurement>
    ): Boolean {
        val profile = loadProfile(userId) ?: return false

        if (!profile.hasUserConsentToStore) return false

        val array = JSONArray()

        measurements.forEach { measurement ->
            if (measurement.userId != userId) return false

            val item = JSONObject().apply {
                put("measurementId", measurement.measurementId)
                put("recordedOn", measurement.recordedOn.toString())
                put("weightKg", measurement.weightKg ?: JSONObject.NULL)
                put("waistCm", measurement.waistCm ?: JSONObject.NULL)
            }
            array.put(item)
        }

        return preferences.edit()
            .putString(measurementsKey(userId), array.toString())
            .commit()
    }

    fun loadMeasurements(
        userId: String
    ): List<SystemFitnessMeasurement> {
        if (loadProfile(userId) == null) return emptyList()

        val raw = preferences.getString(measurementsKey(userId), null)
            ?: return emptyList()

        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.getJSONObject(index)

                    add(
                        SystemFitnessMeasurement(
                            measurementId = item.getString("measurementId"),
                            userId = userId,
                            recordedOn = LocalDate.parse(
                                item.getString("recordedOn")
                            ),
                            weightKg = item.optionalDouble("weightKg"),
                            waistCm = item.optionalDouble("waistCm"),
                            note = ""
                        )
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun revokeConsent(userId: String): Boolean {
        return preferences.edit()
            .remove(profileKey(userId))
            .remove(measurementsKey(userId))
            .commit()
    }

    private fun profileKey(userId: String) =
        "profile_$userId"

    private fun measurementsKey(userId: String) =
        "measurements_$userId"

    private fun JSONObject.optionalDouble(key: String): Double? {
        return if (isNull(key) || !has(key)) null else optDouble(key)
    }
}
