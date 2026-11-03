package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate

enum class SystemNutritionHabit {
    DRINK_WATER,
    EAT_FRUITS_AND_VEGETABLES,
    INCLUDE_PROTEIN,
    EAT_BALANCED_MEALS,
    LIMIT_SUGARY_DRINKS
}

data class SystemNutritionDailyRecord(
    val userId: String,
    val date: String,
    val completedHabits: Set<SystemNutritionHabit>
) {
    val completedCount: Int
        get() = completedHabits.size

    val totalHabits: Int
        get() = SystemNutritionHabit.values().size

    val completionPercentage: Int
        get() = if (totalHabits == 0) {
            0
        } else {
            (completedCount * 100) / totalHabits
        }
}

class SystemNutritionHabitTracker(
    context: Context,
    private val userId: String
) {
    private val preferences = context.applicationContext
        .getSharedPreferences(
            "system_nutrition_habits",
            Context.MODE_PRIVATE
        )

    init {
        require(userId.isNotBlank()) {
            "User ID cannot be empty"
        }
    }

    fun getDailyRecord(
        date: LocalDate = LocalDate.now()
    ): SystemNutritionDailyRecord {

        val dateKey = date.toString()
        val jsonText = preferences.getString(
            storageKey(dateKey),
            null
        )

        if (jsonText.isNullOrBlank()) {
            return emptyRecord(dateKey)
        }

        return try {
            val json = JSONObject(jsonText)
            val habitsArray = json.optJSONArray("completedHabits")
                ?: JSONArray()

            val completed = mutableSetOf<SystemNutritionHabit>()

            for (index in 0 until habitsArray.length()) {
                val habitName = habitsArray.optString(index)

                val habit = SystemNutritionHabit.values()
                    .firstOrNull { it.name == habitName }

                if (habit != null) {
                    completed.add(habit)
                }
            }

            SystemNutritionDailyRecord(
                userId = userId,
                date = dateKey,
                completedHabits = completed
            )
        } catch (exception: Exception) {
            emptyRecord(dateKey)
        }
    }

    fun setHabitCompleted(
        habit: SystemNutritionHabit,
        completed: Boolean,
        date: LocalDate = LocalDate.now()
    ): SystemNutritionDailyRecord {

        val currentRecord = getDailyRecord(date)
        val updatedHabits = currentRecord.completedHabits.toMutableSet()

        if (completed) {
            updatedHabits.add(habit)
        } else {
            updatedHabits.remove(habit)
        }

        val updatedRecord = SystemNutritionDailyRecord(
            userId = userId,
            date = date.toString(),
            completedHabits = updatedHabits
        )

        saveRecord(updatedRecord)

        return updatedRecord
    }

    fun getCompletionPercentage(
        date: LocalDate = LocalDate.now()
    ): Int {
        return getDailyRecord(date).completionPercentage
    }

    fun clearDailyRecord(
        date: LocalDate = LocalDate.now()
    ) {
        preferences.edit()
            .remove(storageKey(date.toString()))
            .apply()
    }

    private fun saveRecord(
        record: SystemNutritionDailyRecord
    ) {
        val json = JSONObject()
        val habitsArray = JSONArray()

        record.completedHabits.forEach { habit ->
            habitsArray.put(habit.name)
        }

        json.put("userId", record.userId)
        json.put("date", record.date)
        json.put("completedHabits", habitsArray)

        preferences.edit()
            .putString(storageKey(record.date), json.toString())
            .apply()
    }

    private fun emptyRecord(
        date: String
    ): SystemNutritionDailyRecord {
        return SystemNutritionDailyRecord(
            userId = userId,
            date = date,
            completedHabits = emptySet()
        )
    }

    private fun storageKey(date: String): String {
        return "nutrition_${userId}_$date"
    }
}
