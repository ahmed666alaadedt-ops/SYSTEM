package com.system.irtqaa

import java.time.Duration

data class SystemSleepConsistencyResult(
    val bedtimeVariationMinutes: Long,
    val wakeUpVariationMinutes: Long,
    val consistencyScore: Int,
    val consistencyLevel: String
)

object SystemSleepConsistency {

    fun calculate(
        records: List<SystemSleepRecord>
    ): SystemSleepConsistencyResult {

        val validRecords = records
            .filter { it.isValid }
            .sortedBy { it.date }
            .takeLast(7)

        if (validRecords.size < 2) {
            return SystemSleepConsistencyResult(
                0, 0, 0, "INSUFFICIENT_DATA"
            )
        }

        val bedtimeMinutes = validRecords.map {
            it.bedtime.hour * 60 + it.bedtime.minute
        }

        val wakeMinutes = validRecords.map {
            it.wakeUpTime.hour * 60 + it.wakeUpTime.minute
        }

        fun variation(values: List<Int>): Long {
            val average = values.average()
            return values.map {
                kotlin.math.abs(it - average)
            }.average().toLong()
        }

        val bedtimeVariation = variation(bedtimeMinutes)
        val wakeVariation = variation(wakeMinutes)

        val totalVariation =
            (bedtimeVariation + wakeVariation) / 2

        val score = (100 - totalVariation / 2)
            .toInt()
            .coerceIn(0, 100)

        val level = when {
            score >= 90 -> "EXCELLENT"
            score >= 75 -> "GOOD"
            score >= 50 -> "MODERATE"
            else -> "IRREGULAR"
        }

        return SystemSleepConsistencyResult(
            bedtimeVariation,
            wakeVariation,
            score,
            level
        )
    }
}
