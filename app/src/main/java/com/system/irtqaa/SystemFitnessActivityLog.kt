package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.DayOfWeek
import java.time.LocalDate
import java.util.UUID

enum class SystemFitnessActivityType {
    WALKING,
    RUNNING,
    STRENGTH,
    FLEXIBILITY,
    OTHER
}

data class SystemFitnessActivityRecord(
    val activityId: String,
    val userId: String,
    val type: SystemFitnessActivityType,
    val durationMinutes: Int,
    val date: String,
    val note: String = ""
)

data class SystemFitnessWeeklySummary(
    val totalActivities: Int,
    val totalMinutes: Int,
    val walkingMinutes: Int,
    val runningMinutes: Int,
    val strengthMinutes: Int,
    val flexibilityMinutes: Int
)

class SystemFitnessActivityLog(
    context: Context,
    private val userId: String
) {
    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_fitness_activity_log",
            Context.MODE_PRIVATE
        )

    private val storageKey = "activities_$userId"

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be empty"
        }
    }

    @Synchronized
    fun addActivity(
        type: SystemFitnessActivityType,
        durationMinutes: Int,
        date: LocalDate = LocalDate.now(),
        note: String = ""
    ): SystemFitnessActivityRecord {

        require(durationMinutes in 1..1440) {
            "Duration must be between 1 and 1440 minutes"
        }

        val record = SystemFitnessActivityRecord(
            activityId = UUID.randomUUID().toString(),
            userId = userId,
            type = type,
            durationMinutes = durationMinutes,
            date = date.toString(),
            note = note.trim().take(200)
        )

        val records = getAllActivities().toMutableList()
        records.add(record)

        saveActivities(records)

        return record
    }

    @Synchronized
    fun getAllActivities(): List<SystemFitnessActivityRecord> {
        val savedText = preferences.getString(storageKey, null)
            ?: return emptyList()

        return try {
            val array = JSONArray(savedText)
            val records = mutableListOf<SystemFitnessActivityRecord>()

            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue

                try {
                    val record = SystemFitnessActivityRecord(
                        activityId = item.getString("activityId"),
                        userId = userId,
                        type = SystemFitnessActivityType.valueOf(
                            item.getString("type")
                        ),
                        durationMinutes = item.getInt("durationMinutes"),
                        date = item.getString("date"),
                        note = item.optString("note", "")
                    )

                    if (
                        record.durationMinutes in 1..1440 &&
                        record.date.isNotBlank()
                    ) {
                        LocalDate.parse(record.date)
                        records.add(record)
                    }
                } catch (exception: Exception) {
                    continue
                }
            }

            records.sortedByDescending { it.date }
        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun getActivitiesForDate(
        date: LocalDate = LocalDate.now()
    ): List<SystemFitnessActivityRecord> {
        return getAllActivities().filter {
            it.date == date.toString()
        }
    }

    @Synchronized
    fun deleteActivity(activityId: String): Boolean {
        val records = getAllActivities().toMutableList()
        val removed = records.removeAll {
            it.activityId == activityId
        }

        if (removed) {
            saveActivities(records)
        }

        return removed
    }

    fun getWeeklySummary(
        date: LocalDate = LocalDate.now()
    ): SystemFitnessWeeklySummary {

        val weekStart = date.with(
            DayOfWeek.MONDAY
        )

        val weekEnd = weekStart.plusDays(6)

        val weeklyRecords = getAllActivities().filter { record ->
            val activityDate = LocalDate.parse(record.date)

            !activityDate.isBefore(weekStart) &&
                !activityDate.isAfter(weekEnd)
        }

        return SystemFitnessWeeklySummary(
            totalActivities = weeklyRecords.size,
            totalMinutes = weeklyRecords.sumOf {
                it.durationMinutes
            },
            walkingMinutes = weeklyRecords
                .filter { it.type == SystemFitnessActivityType.WALKING }
                .sumOf { it.durationMinutes },
            runningMinutes = weeklyRecords
                .filter { it.type == SystemFitnessActivityType.RUNNING }
                .sumOf { it.durationMinutes },
            strengthMinutes = weeklyRecords
                .filter { it.type == SystemFitnessActivityType.STRENGTH }
                .sumOf { it.durationMinutes },
            flexibilityMinutes = weeklyRecords
                .filter { it.type == SystemFitnessActivityType.FLEXIBILITY }
                .sumOf { it.durationMinutes }
        )
    }

    @Synchronized
    fun clearAllActivities() {
        preferences.edit()
            .remove(storageKey)
            .apply()
    }

    private fun saveActivities(
        records: List<SystemFitnessActivityRecord>
    ) {
        val array = JSONArray()

        records.forEach { record ->
            val item = JSONObject()

            item.put("activityId", record.activityId)
            item.put("type", record.type.name)
            item.put("durationMinutes", record.durationMinutes)
            item.put("date", record.date)
            item.put("note", record.note)

            array.put(item)
        }

        preferences.edit()
            .putString(storageKey, array.toString())
            .apply()
    }
}
