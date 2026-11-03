package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.util.UUID

data class SystemHydrationEntry(
    val id: String,
    val date: String,
    val amountMl: Int
)

data class SystemHydrationDailySummary(
    val date: String,
    val totalWaterMl: Int,
    val dailyGoalMl: Int,
    val remainingWaterMl: Int,
    val completionPercentage: Int,
    val goalCompleted: Boolean,
    val entriesCount: Int
)

class SystemHydrationTracker(
    context: Context,
    private val userId: String
) {

    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_hydration_tracker",
            Context.MODE_PRIVATE
        )

    private val entriesKey = "hydration_entries_$userId"
    private val goalKey = "hydration_goal_$userId"

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be empty"
        }
    }

    fun setDailyGoal(goalMl: Int) {
        require(goalMl in 250..10000) {
            "Daily goal must be between 250 and 10000 ml"
        }

        preferences.edit()
            .putInt(goalKey, goalMl)
            .apply()
    }

    fun getDailyGoal(): Int {
        return preferences.getInt(goalKey, 2000)
    }

    @Synchronized
    fun addWater(
        amountMl: Int,
        date: LocalDate = LocalDate.now()
    ): SystemHydrationEntry {

        require(amountMl in 1..2000) {
            "Water amount must be between 1 and 2000 ml"
        }

        val entry = SystemHydrationEntry(
            id = UUID.randomUUID().toString(),
            date = date.toString(),
            amountMl = amountMl
        )

        val entries = getAllEntries().toMutableList()
        entries.add(entry)

        saveEntries(entries)

        return entry
    }

    @Synchronized
    fun getAllEntries(): List<SystemHydrationEntry> {

        val saved = preferences.getString(entriesKey, null)
            ?: return emptyList()

        return try {
            val array = JSONArray(saved)
            val entries = mutableListOf<SystemHydrationEntry>()

            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue

                try {
                    val entry = SystemHydrationEntry(
                        id = item.getString("id"),
                        date = item.getString("date"),
                        amountMl = item.getInt("amountMl")
                    )

                    LocalDate.parse(entry.date)

                    if (entry.amountMl in 1..2000) {
                        entries.add(entry)
                    }
                } catch (exception: Exception) {
                    continue
                }
            }

            entries.sortedBy { it.date }

        } catch (exception: Exception) {
            emptyList()
        }
    }

    fun getEntriesForDate(
        date: LocalDate = LocalDate.now()
    ): List<SystemHydrationEntry> {

        return getAllEntries().filter {
            it.date == date.toString()
        }
    }

    fun getTotalWater(
        date: LocalDate = LocalDate.now()
    ): Int {

        return getEntriesForDate(date).sumOf {
            it.amountMl
        }
    }

    fun getDailySummary(
        date: LocalDate = LocalDate.now()
    ): SystemHydrationDailySummary {

        val entries = getEntriesForDate(date)
        val total = entries.sumOf { it.amountMl }
        val goal = getDailyGoal()

        val percentage = if (goal > 0) {
            ((total.toDouble() / goal) * 100)
                .toInt()
                .coerceAtMost(100)
        } else {
            0
        }

        return SystemHydrationDailySummary(
            date = date.toString(),
            totalWaterMl = total,
            dailyGoalMl = goal,
            remainingWaterMl = (goal - total).coerceAtLeast(0),
            completionPercentage = percentage,
            goalCompleted = total >= goal,
            entriesCount = entries.size
        )
    }

    @Synchronized
    fun deleteEntry(id: String): Boolean {

        val entries = getAllEntries().toMutableList()

        val removed = entries.removeAll {
            it.id == id
        }

        if (removed) {
            saveEntries(entries)
        }

        return removed
    }

    @Synchronized
    fun clearEntriesForDate(
        date: LocalDate = LocalDate.now()
    ) {

        val entries = getAllEntries()
            .filterNot { it.date == date.toString() }

        saveEntries(entries)
    }

    @Synchronized
    fun clearAllEntries() {
        preferences.edit()
            .remove(entriesKey)
            .apply()
    }

    fun clearDailyGoal() {
        preferences.edit()
            .remove(goalKey)
            .apply()
    }

    private fun saveEntries(
        entries: List<SystemHydrationEntry>
    ) {

        val array = JSONArray()

        entries.forEach { entry ->
            val item = JSONObject()

            item.put("id", entry.id)
            item.put("date", entry.date)
            item.put("amountMl", entry.amountMl)

            array.put(item)
        }

        preferences.edit()
            .putString(entriesKey, array.toString())
            .apply()
    }
}
