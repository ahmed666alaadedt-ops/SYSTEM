package com.system.irtqaa

data class SystemSleepRecoveryResult(
    val recoveryScore: Int,
    val recoveryStatus: String,
    val missingSleepMinutes: Long,
    val message: String
)

object SystemSleepRecovery {

    fun calculate(
        records: List<SystemSleepRecord>,
        targetMinutes: Long = 480L
    ): SystemSleepRecoveryResult {

        val validRecords = records
            .filter { it.isValid }
            .sortedBy { it.date }
            .takeLast(7)

        if (validRecords.isEmpty()) {
            return SystemSleepRecoveryResult(
                recoveryScore = 0,
                recoveryStatus = "NO_DATA",
                missingSleepMinutes = 0,
                message = "سجل نومك حتى نتمكن من تقييم التعافي."
            )
        }

        val safeTarget = targetMinutes.coerceAtLeast(1L)

        val averageMinutes = validRecords
            .map { it.durationMinutes }
            .average()

        val missingMinutes = (
            safeTarget - averageMinutes.toLong()
        ).coerceAtLeast(0L)

        val recoveryScore = (
            (averageMinutes / safeTarget) * 100
        ).toInt().coerceIn(0, 100)

        val status = when {
            recoveryScore >= 95 -> "EXCELLENT"
            recoveryScore >= 80 -> "GOOD"
            recoveryScore >= 60 -> "MODERATE"
            else -> "LOW"
        }

        val message = when (status) {
            "EXCELLENT" -> "تعافيك جيد حسب مدة النوم المسجلة."
            "GOOD" -> "تعافيك جيد، حافظ على انتظام نومك."
            "MODERATE" -> "حاول تحسين مدة الراحة تدريجياً."
            else -> "تحتاج إلى الاهتمام بمدة النوم والراحة."
        }

        return SystemSleepRecoveryResult(
            recoveryScore = recoveryScore,
            recoveryStatus = status,
            missingSleepMinutes = missingMinutes,
            message = message
        )
    }
}
