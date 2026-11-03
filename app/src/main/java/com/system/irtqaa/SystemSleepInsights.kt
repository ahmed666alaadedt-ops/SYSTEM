package com.system.irtqaa

data class SystemSleepInsight(
    val title: String,
    val message: String,
    val priority: Int
)

object SystemSleepInsights {

    fun generate(
        analysis: SystemSleepAnalysis
    ): List<SystemSleepInsight> {

        val insights = mutableListOf<SystemSleepInsight>()

        if (analysis.analyzedDays == 0) {
            return listOf(
                SystemSleepInsight(
                    title = "بيانات النوم",
                    message = "سجل نومك حتى يتمكن SYSTEM من تحليل راحتك.",
                    priority = 1
                )
            )
        }

        if (analysis.averageSleepMinutes < 300) {
            insights.add(
                SystemSleepInsight(
                    title = "نقص النوم",
                    message = "معدل نومك منخفض جداً. حاول زيادة وقت الراحة تدريجياً.",
                    priority = 1
                )
            )
        }

        if (analysis.sleepDebtMinutes >= 120) {
            insights.add(
                SystemSleepInsight(
                    title = "تراكم نقص النوم",
                    message = "هناك نقص متراكم في ساعات نومك خلال الأيام المسجلة.",
                    priority = 2
                )
            )
        }

        if (analysis.averageQuality < 3.0) {
            insights.add(
                SystemSleepInsight(
                    title = "جودة النوم",
                    message = "حاول تحسين بيئة النوم وتقليل الإضاءة والمنبهات قبل النوم.",
                    priority = 2
                )
            )
        }

        if (analysis.averageSleepMinutes >= 420 &&
            analysis.averageQuality >= 3.0
        ) {
            insights.add(
                SystemSleepInsight(
                    title = "نمط نوم جيد",
                    message = "أداؤك في النوم جيد. حافظ على مواعيد نوم منتظمة.",
                    priority = 3
                )
            )
        }

        return insights.sortedBy { it.priority }
    }
}
