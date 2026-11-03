package com.system.irtqaa

data class SystemSleepScore(
    val totalScore: Int,
    val durationScore: Int,
    val qualityScore: Int,
    val consistencyScore: Int,
    val rank: String
)

object SystemSleepScoreCalculator {

    fun calculate(
        records: List<SystemSleepRecord>,
        targetMinutes: Long = 480L
    ): SystemSleepScore {

        val validRecords = records
            .filter { it.isValid }
            .sortedBy { it.date }
            .takeLast(7)

        if (validRecords.isEmpty()) {
            return SystemSleepScore(
                0, 0, 0, 0, "NO_DATA"
            )
        }

        val averageDuration =
            validRecords.map { it.durationMinutes }.average()

        val averageQuality =
            validRecords.map { it.quality }.average()

        val durationScore = (
            (averageDuration / targetMinutes.coerceAtLeast(1L)) * 40
        ).toInt().coerceIn(0, 40)

        val qualityScore = (
            (averageQuality / 5.0) * 35
        ).toInt().coerceIn(0, 35)

        val consistencyScore = (
            (validRecords.size / 7.0) * 25
        ).toInt().coerceIn(0, 25)

        val totalScore =
            durationScore + qualityScore + consistencyScore

        val rank = when {
            totalScore >= 90 -> "S"
            totalScore >= 80 -> "A"
            totalScore >= 70 -> "B"
            totalScore >= 60 -> "C"
            totalScore >= 40 -> "D"
            else -> "E"
        }

        return SystemSleepScore(
            totalScore = totalScore,
            durationScore = durationScore,
            qualityScore = qualityScore,
            consistencyScore = consistencyScore,
            rank = rank
        )
    }
}
