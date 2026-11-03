package com.system.irtqaa

import java.time.LocalTime

data class SystemSleepReminder(
    val bedtime: LocalTime,
    val wakeUpTime: LocalTime,
    val enabled: Boolean = true,
    val reminderMinutesBefore: Int = 30
) {
    fun bedtimeReminderTime(): LocalTime {
        return bedtime.minusMinutes(
            reminderMinutesBefore.coerceIn(0, 180).toLong()
        )
    }

    fun isValid(): Boolean {
        return reminderMinutesBefore in 0..180
    }
}
