package com.system.irtqaa

import java.time.LocalDate

object SystemSleepHistory {

    fun getHistory(
        records: List<SystemSleepRecord>,
        limit: Int = 30
    ): List<SystemSleepRecord> {

        return records
            .filter { it.isValid }
            .sortedByDescending { it.date }
            .distinctBy { it.date }
            .take(limit.coerceAtLeast(1))
    }

    fun findByDate(
        records: List<SystemSleepRecord>,
        date: LocalDate
    ): SystemSleepRecord? {

        return records
            .filter { it.isValid }
            .firstOrNull { it.date == date }
    }

    fun getTotalRecordedDays(
        records: List<SystemSleepRecord>
    ): Int {

        return records
            .filter { it.isValid }
            .distinctBy { it.date }
            .size
    }

    fun getLatestRecord(
        records: List<SystemSleepRecord>
    ): SystemSleepRecord? {

        return records
            .filter { it.isValid }
            .maxByOrNull { it.date }
    }
}
