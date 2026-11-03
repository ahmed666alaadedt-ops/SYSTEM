package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate

data class SystemFitnessRecoveryRecord(
    val date: String,
    val sleepHours: Double,
    val energyLevel: Int,
    val sorenessLevel: Int
)

data class SystemFitnessRecoverySummary(
    val recordedDays: Int,
    val averageSleepHours: Double,
    val averageEnergyLevel: Double,
    val averageSorenessLevel: Double
)

class SystemFitnessRecoveryTracker(
    context: Context,
    private val userId: String
) {

    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_fitness_recovery",
            Context.MODE_PRIVATE
        )

    private val storageKey = "recovery_$userId"

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be empty"
        }
    }

    @Synchronized
    fun saveDailyCheckIn(
        sleepHours: Double,
        energyLevel: Int,
        sorenessLevel: Int,
        date: LocalDate = LocalDate.now()
    ): SystemFitnessRecoveryRecord {

        require(sleepHours.isFinite() && sleepHours in 0.0..24.0) {
            "Sleep hours must be between 0 and 24"
        }

        require(energyLevel in 1..5) {
            "Energy level must be between 1 and 5"
        }

        require(sorenessLevel in 1..5) {
            "Soreness level must be between 1 and 5"
        }

        val record = SystemFitnessRecoveryRecord(
            date = date.toString(),
            sleepHours = sleepHours,
            energyLevel = energyLevel,
            sorenessLevel = sorenessLevel
        )

        val records = getAllRecords().toMutableList()

        records.removeAll { it.date == record.date }
        records.add(record)

        saveRecords(records)

        return record
    }

    @Synchronized
    fun getAllRecords(): List<SystemFitnessRecoveryRecord> {

        val savedText = preferences.getString(storageKey, null)
            ?: return emptyList()

        return try {
            val array = JSONArray(savedText)
            val records = mutableListOf<SystemFitnessRecoveryRecord>()

            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue

                try {
                    val record = SystemFitnessRecoveryRecord(
                        date = item.getString("date"),
                        sleepHours = item.getDouble("sleepHours"),
                        energyLevel = item.getInt("energyLevel"),
                        sorenessLevel = item.getInt("sorenessLevel")
                    )

                    LocalDate.parse(record.date)

                    if (
                        record.sleepHours.isFinite() &&
                        record.sleepHours in 0.0..24.0 &&
                        record.energyLevel in 1..5 &&
                        record.sorenessLevel in 1..5
                    ) {
                        records.add(record)
                    }
                } catch (exception: Exception) {
                    continue
                }
            }

            records.distinctBy { it.date }
                .sortedByDescending { it.date }

        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun getCheckIn(
        date: LocalDate = LocalDate.now()
    ): SystemFitnessRecoveryRecord? {

        return getAllRecords().firstOrNull {
            it.date == date.toString()
        }
    }

    fun getWeeklySummary(
        referenceDate: LocalDate = LocalDate.now()
    ): SystemFitnessRecoverySummary {

        val weekStart = referenceDate.minusDays(
            (referenceDate.dayOfWeek.value - 1).toLong()
        )

        val weekEnd = weekStart.plusDays(6)

        val records = getAllRecords().filter { record ->
            val recordDate = LocalDate.parse(record.date)

            !recordDate.isBefore(weekStart) &&
                !recordDate.isAfter(weekEnd)
        }

        if (records.isEmpty()) {
            return SystemFitnessRecoverySummary(
                recordedDays = 0,
                averageSleepHours = 0.0,
                averageEnergyLevel = 0.0,
                averageSorenessLevel = 0.0
            )
        }

        return SystemFitnessRecoverySummary(
            recordedDays = records.size,
            averageSleepHours = records
                .map { it.sleepHours }
                .average(),
            averageEnergyLevel = records
                .map { it.energyLevel }
                .average(),
            averageSorenessLevel = records
                .map { it.sorenessLevel }
                .average()
        )
    }

    @Synchronized
    fun deleteCheckIn(date: LocalDate): Boolean {

        val records = getAllRecords().toMutableList()

        val removed = records.removeAll {
            it.date == date.toString()
        }

        if (removed) {
            saveRecords(records)
        }

        return removed
    }

    @Synchronized
    fun clearAllRecords() {
        preferences.edit()
            .remove(storageKey)
            .apply()
    }

    private fun saveRecords(
        records: List<SystemFitnessRecoveryRecord>
    ) {
        val array = JSONArray()

        records.forEach { record ->
            val item = JSONObject()

            item.put("date", record.date)
            item.put("sleepHours", record.sleepHours)
            item.put("energyLevel", record.energyLevel)
            item.put("sorenessLevel", record.sorenessLevel)

            array.put(item)
        }

        preferences.edit()
            .putString(storageKey, array.toString())
            .apply()
    }
}
