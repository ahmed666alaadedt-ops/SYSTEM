
package com.system.irtqaa

enum class SystemGuidancePriority(val order: Int) {
    HIGH(1),
    MEDIUM(2),
    LOW(3)
}

data class SystemPrioritizedRecommendation(
    val text: String,
    val priority: SystemGuidancePriority
)

object SystemSleepGuidancePriorityEngine {

    fun prioritize(
        recommendations: List<String>
    ): List<SystemPrioritizedRecommendation> {

        return recommendations
            .filter { it.isNotBlank() }
            .distinct()
            .map { recommendation ->
                SystemPrioritizedRecommendation(
                    text = recommendation,
                    priority = classify(recommendation)
                )
            }
            .sortedBy { it.priority.order }
    }

    private fun classify(
        recommendation: String
    ): SystemGuidancePriority {

        val text = recommendation.lowercase()

        val highPriorityWords = listOf(
            "insufficient sleep",
            "sleep deprivation",
            "قلة النوم",
            "نقص النوم",
            "حرمان من النوم"
        )

        val mediumPriorityWords = listOf(
            "environment",
            "consistency",
            "regular",
            "البيئة",
            "الانتظام",
            "الاستمرارية"
        )

        return when {
            highPriorityWords.any { text.contains(it) } ->
                SystemGuidancePriority.HIGH

            mediumPriorityWords.any { text.contains(it) } ->
                SystemGuidancePriority.MEDIUM

            else ->
                SystemGuidancePriority.LOW
        }
    }
}
