package com.system.irtqaa

data class SystemSleepEnvironmentInput(
    val roomDark: Boolean,
    val roomQuiet: Boolean,
    val roomComfortable: Boolean,
    val screensBeforeSleep: Boolean,
    val caffeineBeforeSleep: Boolean
)

data class SystemSleepEnvironmentResult(
    val score: Int,
    val level: String,
    val recommendations: List<String>
)

object SystemSleepEnvironment {

    fun evaluate(
        input: SystemSleepEnvironmentInput
    ): SystemSleepEnvironmentResult {

        var score = 0
        val recommendations = mutableListOf<String>()

        if (input.roomDark) {
            score += 25
        } else {
            recommendations.add("حاول جعل غرفة النوم مظلمة")
        }

        if (input.roomQuiet) {
            score += 25
        } else {
            recommendations.add("قلل الضوضاء أثناء النوم")
        }

        if (input.roomComfortable) {
            score += 25
        } else {
            recommendations.add("حسّن راحة ودرجة حرارة الغرفة")
        }

        if (!input.screensBeforeSleep) {
            score += 15
        } else {
            recommendations.add("قلل استخدام الشاشات قبل النوم")
        }

        if (!input.caffeineBeforeSleep) {
            score += 10
        } else {
            recommendations.add("تجنب الكافيين قرب موعد النوم")
        }

        val level = when {
            score >= 90 -> "EXCELLENT"
            score >= 70 -> "GOOD"
            score >= 50 -> "MODERATE"
            else -> "POOR"
        }

        return SystemSleepEnvironmentResult(
            score,
            level,
            recommendations
        )
    }
}
