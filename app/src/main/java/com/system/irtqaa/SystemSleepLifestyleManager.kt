package com.system.irtqaa

import android.content.Context

class SystemSleepLifestyleManager(context: Context) {

    private val lifestyleStorage =
        SystemSleepLifestyleStorage(context)

    private val sleepManager =
        SystemSleepManager(context)

    fun saveInputs(
        userId: String,
        environment: SystemSleepEnvironmentInput,
        habits: SystemSleepHabitsInput
    ): Boolean {

        if (userId.isBlank()) return false

        return lifestyleStorage.save(
            userId = userId,
            environment = environment,
            habits = habits
        )
    }

    fun getReport(
        userId: String
    ): SystemSleepLifestyleReport? {

        if (userId.isBlank()) return null

        val savedInputs = lifestyleStorage.load(userId)
            ?: return null

        val records = sleepManager.getRecords(userId)

        return SystemSleepLifestyleReportBuilder.build(
            records = records,
            environmentInput = savedInputs.first,
            habitsInput = savedInputs.second
        )
    }

    fun deleteInputs(userId: String): Boolean {

        if (userId.isBlank()) return false

        return lifestyleStorage.delete(userId)
    }
}
