package com.system.irtqaa

data class SystemSleepWeeklyReport(
    val recordedDays: Int,
    val averageSleepMinutes: Long,
    val totalSleepMinutes: Long,
    val averageQuality: Double,
    val consistencyPercentage: Int,
    val evaluation: String
) {
    val averageSleepHours: Double
        get() = averageSleepMinutes / 60.0

    val totalSleepHours: Double
        get() = totalSleepMinutes / 60.0
}

object SystemSleepWeeklyReportGenerator {

    fun generate(
        records: List<SystemSleepRecord>
    ): SystemSleepWeeklyReport {

        val validRecords = records
            .filter { it.isValid }
            .sortedBy { it.date }
            .takeLast(7)

        if (validRecords.isEmpty()) {
            return SystemSleepWeeklyReport(
                recordedDays = 0,
                averageSleepMinutes = 0,
                totalSleepMinutes = 0,
                averageQuality = 0.0,
                consistencyPercentage = 0,
                evaluation = "NO_DATA"
            )
        }

        val totalMinutes = validRecords.sumOf {
            it.durationMinutes
        }

        val averageMinutes =
            totalMinutes / validRecords.size

        val averageQuality =
            validRecords.map { it.quality }.average()

        val consistency =
            (validRecords.size * 100) / 7

        val evaluation = when {
            consistency >= 85 && averageMinutes >= 420 ->
                "EXCELLENT"

            consistency >= 70 && averageMinutes >= 360 ->
                "GOOD"

            consistency >= 50 ->
                "MODERATE"

            else ->
                "NEEDS_IMPROVEMENT"
        }

        return SystemSleepWeeklyReport(
            recordedDays = validRecords.size,
            averageSleepMinutes = averageMinutes,
            totalSleepMinutes = totalMinutes,
            averageQuality = averageQuality,
            consistencyPercentage = consistency,
            evaluation = evaluation
        )
    }
}
