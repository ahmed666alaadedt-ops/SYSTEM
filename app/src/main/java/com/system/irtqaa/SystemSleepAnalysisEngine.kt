package com.system.irtqaa

data class SystemSleepAnalysis(
    val analyzedDays: Int,
    val averageSleepMinutes: Long,
    val totalSleepMinutes: Long,
    val averageQuality: Double,
    val sleepDebtMinutes: Long,
    val evaluation: String,
    val recommendation: String
) {
    val averageSleepHours: Double
        get() = averageSleepMinutes / 60.0

    val sleepDebtHours: Double
        get() = sleepDebtMinutes / 60.0
}

object SystemSleepAnalysisEngine {

    private const val DEFAULT_TARGET_MINUTES = 480L

    fun analyze(
        records: List<SystemSleepRecord>,
        targetMinutes: Long = DEFAULT_TARGET_MINUTES
    ): SystemSleepAnalysis {

        val validRecords = records
            .filter { it.isValid }
            .sortedBy { it.date }
            .takeLast(7)

        if (validRecords.isEmpty()) {
            return SystemSleepAnalysis(
                analyzedDays = 0,
                averageSleepMinutes = 0,
                totalSleepMinutes = 0,
                averageQuality = 0.0,
                sleepDebtMinutes = 0,
                evaluation = "NO_DATA",
                recommendation = "سجل ساعات نومك حتى نبدأ التحليل."
            )
        }

        val summary = SystemSleepTracker.calculateSummary(
            validRecords
        )

        val sleepDebt = validRecords.sumOf { record ->
            (targetMinutes - record.durationMinutes)
                .coerceAtLeast(0)
        }

        val evaluation = SystemSleepTracker.evaluateSleepQuality(
            summary.averageMinutes,
            summary.averageQuality
        )

        val recommendation = when {
            summary.averageMinutes < 300 ->
                "حاول زيادة ساعات نومك تدريجياً."

            summary.averageMinutes < 420 ->
                "حاول تثبيت موعد نومك وزيادة مدة الراحة."

            summary.averageQuality < 3.0 ->
                "اهتم بجودة النوم وابتعد عن المنبهات قبل النوم."

            else ->
                "ممتاز! استمر على نمط نوم منتظم."
        }

        return SystemSleepAnalysis(
            analyzedDays = validRecords.size,
            averageSleepMinutes = summary.averageMinutes,
            totalSleepMinutes = summary.totalMinutes,
            averageQuality = summary.averageQuality,
            sleepDebtMinutes = sleepDebt,
            evaluation = evaluation,
            recommendation = recommendation
        )
    }
}
