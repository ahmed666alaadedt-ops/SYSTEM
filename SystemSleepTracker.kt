package com.system.app.data.sleep

import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime

data class SystemSleepRecord(
    val date: LocalDate,
    val bedtime: LocalDateTime,
    val wakeUpTime: LocalDateTime,
    val quality: Int,
    val notes: String = ""
) {
    val durationMinutes: Long
        get() = Duration.between(bedtime, wakeUpTime).toMinutes()

    val durationHours: Double
        get() = durationMinutes / 60.0

    val isValid: Boolean
        get() = durationMinutes > 0 &&
            durationMinutes <= 24 * 60 &&
            quality in 1..5
}

data class SystemSleepSummary(
    val totalMinutes: Long,
    val averageMinutes: Long,
    val averageQuality: Double,
    val recordsCount: Int
) {
    val averageHours: Double
        get() = averageMinutes / 60.0
}

object SystemSleepTracker {

    fun createRecord(
        bedtime: LocalDateTime,
        wakeUpTime: LocalDateTime,
        quality: Int,
        notes: String = ""
    ): SystemSleepRecord? {

        val record = SystemSleepRecord(
            date = wakeUpTime.toLocalDate(),
            bedtime = bedtime,
            wakeUpTime = wakeUpTime,
            quality = quality,
            notes = notes
        )

        return if (record.isValid) record else null
    }

    fun calculateSummary(
        records: List<SystemSleepRecord>
    ): SystemSleepSummary {

        val validRecords = records.filter { it.isValid }

        if (validRecords.isEmpty()) {
            return SystemSleepSummary(0, 0, 0.0, 0)
        }

        val total = validRecords.sumOf { it.durationMinutes }

        return SystemSleepSummary(
            totalMinutes = total,
            averageMinutes = total / validRecords.size,
            averageQuality = validRecords.map { it.quality }.average(),
            recordsCount = validRecords.size
        )
    }

    fun evaluateSleepQuality(
        averageMinutes: Long,
        averageQuality: Double
    ): String {

        return when {
            averageMinutes >= 420 && averageQuality >= 4.0 -> "EXCELLENT"
            averageMinutes >= 360 && averageQuality >= 3.0 -> "GOOD"
            averageMinutes >= 300 -> "MODERATE"
            else -> "NEEDS_IMPROVEMENT"
        }
    }
}
