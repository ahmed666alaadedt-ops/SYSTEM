package com.system.irtqaa

import android.content.Context
import java.time.LocalDate

class SystemSleepStreakService(context: Context) {

    private val sleepManager = SystemSleepManager(context)

    fun getStreak(
        userId: String,
        today: LocalDate = LocalDate.now()
    ): SystemSleepStreakCalculation {

        val records = sleepManager.getRecords(userId)

        return SystemSleepStreakCalculator.calculate(
            records = records,
            today = today
        )
    }
}
