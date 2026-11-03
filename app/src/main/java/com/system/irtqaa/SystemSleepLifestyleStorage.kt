package com.system.irtqaa

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

class SystemSleepLifestyleStorage(context: Context) {

    private val preferences = context.getSharedPreferences(
        "system_sleep_lifestyle",
        Context.MODE_PRIVATE
    )

    fun save(
        userId: String,
        environment: SystemSleepEnvironmentInput,
        habits: SystemSleepHabitsInput
    ): Boolean {

        if (userId.isBlank()) return false

        val data = JSONObject().apply {
            put("environment", JSONObject().apply {
                put("roomDark", environment.roomDark)
                put("roomQuiet", environment.roomQuiet)
                put("roomComfortable", environment.roomComfortable)
                put("screensBeforeSleep", environment.screensBeforeSleep)
                put("caffeineBeforeSleep", environment.caffeineBeforeSleep)
            })

            put("habits", JSONObject().apply {
                put("exercisedToday", habits.exercisedToday)
                put("hadLateMeal", habits.hadLateMeal)
                put("usedRelaxation", habits.usedRelaxation)
                put("followedSleepSchedule", habits.followedSleepSchedule)
                put("tookDaytimeNap", habits.tookDaytimeNap)
            })
        }

        return preferences.edit()
            .putString(userId, data.toString())
            .commit()
    }

    fun load(
        userId: String
    ): Pair<SystemSleepEnvironmentInput, SystemSleepHabitsInput>? {

        if (userId.isBlank()) return null

        val saved = preferences.getString(userId, null)
            ?: return null

        return try {
            val data = JSONObject(saved)
            val environment = data.getJSONObject("environment")
            val habits = data.getJSONObject("habits")

            val environmentInput = SystemSleepEnvironmentInput(
                roomDark = environment.getBoolean("roomDark"),
                roomQuiet = environment.getBoolean("roomQuiet"),
                roomComfortable = environment.getBoolean("roomComfortable"),
                screensBeforeSleep = environment.getBoolean("screensBeforeSleep"),
                caffeineBeforeSleep = environment.getBoolean("caffeineBeforeSleep")
            )

            val habitsInput = SystemSleepHabitsInput(
                exercisedToday = habits.getBoolean("exercisedToday"),
                hadLateMeal = habits.getBoolean("hadLateMeal"),
                usedRelaxation = habits.getBoolean("usedRelaxation"),
                followedSleepSchedule = habits.getBoolean("followedSleepSchedule"),
                tookDaytimeNap = habits.getBoolean("tookDaytimeNap")
            )

            Pair(environmentInput, habitsInput)
        } catch (_: Exception) {
            null
        }
    }

    fun delete(userId: String): Boolean {
        if (userId.isBlank()) return false

        return preferences.edit()
            .remove(userId)
            .commit()
    }
}
